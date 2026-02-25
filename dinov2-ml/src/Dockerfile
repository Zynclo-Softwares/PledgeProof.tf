# ── DINOv2-small ONNX Lambda (container image) ─────────────────────────────
# Model + onnxruntime + numpy + pillow exceeds the 50 MB compressed layer
# limit, so we use a Docker container Lambda (10 GB image limit) instead.
# The model is baked into the image — no S3 download on cold start.
# ────────────────────────────────────────────────────────────────────────────

FROM public.ecr.aws/lambda/python:3.12

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy pre-downloaded model (see Makefile "download-model" target)
COPY model/dinov2_vits14.onnx /opt/model/dinov2_vits14.onnx

# Copy handler
COPY handler.py ${LAMBDA_TASK_ROOT}/

# Set model path env
ENV MODEL_PATH=/opt/model/dinov2_vits14.onnx

CMD ["handler.handler"]
