"""
DINOv2-small Lambda handler — image embedding & comparison.

Routes (via event["action"]):
  warmup  → keeps container warm, no inference
  embed   → returns 384-dim L2-normalised embedding for one image
  compare → embeds a test image and cosine-compares against stored ref embeddings
"""

import base64
import io
import json
import os

import numpy as np
import onnxruntime as ort
from PIL import Image

# ── Model loading (runs once on cold start, persists for warm invocations) ──

MODEL_PATH = os.environ.get("MODEL_PATH", "/opt/model/dinov2_vits14.onnx")
session = ort.InferenceSession(MODEL_PATH, providers=["CPUExecutionProvider"])
INPUT_NAME = session.get_inputs()[0].name

# ── ImageNet normalisation constants ────────────────────────────────────────

IMAGENET_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32).reshape(1, 1, 3)
IMAGENET_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32).reshape(1, 1, 3)


# ── Preprocessing ───────────────────────────────────────────────────────────

def preprocess(image_bytes: bytes) -> np.ndarray:
    """Resize + centre-crop to 224×224, normalise, return (1,3,224,224) float32."""
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")

    # Resize shortest side to 256 (matching torchvision.transforms.Resize(256))
    w, h = img.size
    if w < h:
        new_w, new_h = 256, int(h * 256 / w)
    else:
        new_h, new_w = 256, int(w * 256 / h)
    img = img.resize((new_w, new_h), Image.Resampling.BILINEAR)

    # Centre-crop to 224×224
    left = (new_w - 224) // 2
    top = (new_h - 224) // 2
    img = img.crop((left, top, left + 224, top + 224))

    arr = np.array(img, dtype=np.float32) / 255.0
    arr = (arr - IMAGENET_MEAN) / IMAGENET_STD
    arr = arr.transpose(2, 0, 1)  # HWC → CHW
    return arr[np.newaxis]  # (1, 3, 224, 224)


# ── Inference helpers ───────────────────────────────────────────────────────

def embed(image_bytes: bytes) -> list[float]:
    """Return L2-normalised 384-dim embedding."""
    tensor = preprocess(image_bytes)
    output = session.run(None, {INPUT_NAME: tensor})
    vec = output[0][0].astype(np.float64)  # type: ignore[index]
    vec /= np.linalg.norm(vec)
    return vec.tolist()


def cosine_sim(a: list[float], b: list[float]) -> float:
    a_np = np.array(a, dtype=np.float64)
    b_np = np.array(b, dtype=np.float64)
    return float(np.dot(a_np, b_np) / (np.linalg.norm(a_np) * np.linalg.norm(b_np)))


# ── Lambda entry point ─────────────────────────────────────────────────────

def handler(event, _context):
    action = event.get("action")

    # ── Warmup ping ──
    if action == "warmup":
        return {"status": "warm"}

    # ── Embed a single image ──
    if action == "embed":
        image_bytes = base64.b64decode(event["image"])
        embedding = embed(image_bytes)
        return {"embedding": embedding}

    # ── Compare test image against reference embeddings ──
    if action == "compare":
        image_bytes = base64.b64decode(event["image"])
        ref_embeddings: list[list[float]] = event["refEmbeddings"]
        threshold: float = event.get("threshold", 0.65)

        test_emb = embed(image_bytes)

        scores = [cosine_sim(test_emb, ref) for ref in ref_embeddings]
        avg_score = sum(scores) / len(scores) if scores else 0.0
        max_score = max(scores) if scores else 0.0

        return {
            "embedding": test_emb,
            "scores": scores,
            "avgScore": round(avg_score, 4),
            "maxScore": round(max_score, 4),
            "pass": max_score >= threshold,
        }

    return {"error": f"Unknown action: {action}"}, 400
