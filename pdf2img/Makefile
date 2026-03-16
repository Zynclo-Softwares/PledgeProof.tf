# ── PDF-to-Image Lambda — Build & Push ──────────────────────────────────────
#
# Targets:
#   build   — Build Docker container image
#   login   — Authenticate Docker to ECR
#   push    — Tag + push image to ECR
#   deploy  — build → login → push (all-in-one)
#   clean   — Remove Docker image
#
# Prerequisites:
#   - Docker
#   - AWS CLI (authenticated)
# ────────────────────────────────────────────────────────────────────────────

AWS_ACCOUNT  ?= 659271373941
AWS_REGION   ?= ca-central-1
ECR_REPO     ?= pledgeproof-pdf2img
IMAGE_TAG    ?= latest

ECR_URI      = $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO)

.PHONY: build login push deploy clean

# ── Build Docker image ──
build:
	@echo "🐳 Building Docker image $(ECR_REPO):$(IMAGE_TAG) (linux/amd64)..."
	@docker buildx build --platform linux/amd64 --provenance=false --output type=docker -t $(ECR_REPO):$(IMAGE_TAG) src/
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
deploy: build push
	@echo "🚀 Done — image available at $(ECR_URI):$(IMAGE_TAG)"

# ── Cleanup ──
clean:
	@docker rmi $(ECR_REPO):$(IMAGE_TAG) $(ECR_URI):$(IMAGE_TAG) 2>/dev/null || true
	@echo "✓  Cleaned"
