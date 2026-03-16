"""
PDF-to-Image Lambda handler — renders PDF pages as JPEG images.

Routes (via event["action"]):
  warmup   → keeps container warm, no processing
  convert  → renders each page of a PDF to a base64-encoded JPEG image

Input for "convert":
  pdf_base64: str  — base64-encoded PDF bytes
  scale: float     — render scale factor (default 2.0, max 3.0)
  max_pages: int   — max pages to render (default 20)

Output:
  pages: list[str] — array of base64-encoded JPEG images (one per page)
  page_count: int  — total number of pages in the PDF
"""

import base64
import io

import pymupdf
from PIL import Image


def render_pages(pdf_bytes: bytes, scale: float = 2.0, max_pages: int = 20) -> tuple[list[bytes], int]:
    """Render each PDF page to JPEG bytes. Returns (pages, total_page_count)."""
    doc = pymupdf.open(stream=pdf_bytes, filetype="pdf")
    total = len(doc)
    pages: list[bytes] = []

    limit = min(total, max_pages)
    matrix = pymupdf.Matrix(scale, scale)

    for i in range(limit):
        page = doc[i]
        pix = page.get_pixmap(matrix=matrix)

        img = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=85)
        pages.append(buf.getvalue())

    doc.close()
    return pages, total


def handler(event, _context):
    action = event.get("action")

    if action == "warmup":
        return {"status": "warm"}

    if action == "convert":
        pdf_bytes = base64.b64decode(event["pdf_base64"])
        scale = min(float(event.get("scale", 2.0)), 3.0)
        max_pages = min(int(event.get("max_pages", 20)), 50)

        page_images, total_pages = render_pages(pdf_bytes, scale=scale, max_pages=max_pages)

        return {
            "pages": [base64.b64encode(p).decode("ascii") for p in page_images],
            "page_count": len(page_images),
            "total_pages": total_pages,
        }

    return {"error": f"Unknown action: {action}"}
