# ── DINOv2-small ONNX Lambda — Build & Push ─────────────────────────────────
#
# Targets:
#   download-model  — Fetch DINOv2 ViT-S/14 ONNX from HuggingFace
#   build           — Build Docker container image
#   login           — Authenticate Docker to ECR
#   push            — Tag + push image to ECR
#   deploy          — download-model → build → login → push (all-in-one)
#   clean           — Remove downloaded model + Docker image
#
# Prerequisites:
#   - Docker
#   - AWS CLI (authenticated)
#   - wget or curl
# ────────────────────────────────────────────────────────────────────────────

AWS_ACCOUNT  ?= 659271373941
AWS_REGION   ?= ca-central-1
ECR_REPO     ?= pledgeproof-dinov2
IMAGE_TAG    ?= latest

ECR_URI      = $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO)
MODEL_DIR    = src/model
MODEL_FILE   = $(MODEL_DIR)/dinov2_vits14.onnx
MODEL_URL    = https://huggingface.co/sefaburak/dinov2-small-onnx/resolve/main/dinov2_vits14.onnx

.PHONY: download-model build login push deploy clean

# ── Download ONNX model from HuggingFace ──
download-model: $(MODEL_FILE)

$(MODEL_FILE):
	@mkdir -p $(MODEL_DIR)
	@echo "⬇  Downloading DINOv2-small ONNX model..."
	@wget -q --show-progress -O $(MODEL_FILE) "$(MODEL_URL)" || \
		curl -L -o $(MODEL_FILE) "$(MODEL_URL)"
	@echo "✓  Model saved to $(MODEL_FILE)"

# ── Build Docker image ──
build: $(MODEL_FILE)
	@echo "🐳 Building Docker image $(ECR_REPO):$(IMAGE_TAG) (linux/amd64)..."
	@docker buildx build --platform linux/amd64 -t $(ECR_REPO):$(IMAGE_TAG) src/
	@echo "✓  Image built"

# ── Login to ECR ──
login:
	@echo "🔑 Logging into ECR..."
	@aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com
	@echo "✓  Logged in"

# ── Push to ECR ──
push: login
	@echo "📤 Pushing to $(ECR_URI):$(IMAGE_TAG)..."
	@docker tag $(ECR_REPO):$(IMAGE_TAG) $(ECR_URI):$(IMAGE_TAG)
	@docker push $(ECR_URI):$(IMAGE_TAG)
	@echo "✓  Pushed"

# ── All-in-one ──
deploy: download-model build push
	@echo "🚀 Done — image available at $(ECR_URI):$(IMAGE_TAG)"

# ── Cleanup ──
clean:
	@rm -rf $(MODEL_DIR)
	@docker rmi $(ECR_REPO):$(IMAGE_TAG) $(ECR_URI):$(IMAGE_TAG) 2>/dev/null || true
	@echo "✓  Cleaned"
