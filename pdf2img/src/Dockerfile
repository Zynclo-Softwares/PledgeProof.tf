# ── PDF-to-Image Lambda (container image) ──────────────────────────────────
# PyMuPDF renders PDF pages to JPEG images for Haiku's vision capabilities.
# ────────────────────────────────────────────────────────────────────────────

FROM public.ecr.aws/lambda/python:3.12

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy handler
COPY handler.py ${LAMBDA_TASK_ROOT}/

CMD ["handler.handler"]
