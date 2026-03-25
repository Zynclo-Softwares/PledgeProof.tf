# ── Resend Contact Sync Lambda (container image) ───────────────────────────
# Syncs Cognito user pool emails → Resend audience as unique contacts.
# ────────────────────────────────────────────────────────────────────────────

FROM public.ecr.aws/lambda/python:3.12

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY handler.py ${LAMBDA_TASK_ROOT}/

CMD ["handler.handler"]
