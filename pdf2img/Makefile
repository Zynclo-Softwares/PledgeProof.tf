# ── PDF-to-Image Lambda — Build & Push ──────────────────────────────────────
#
# Targets:
#   build          — Build Docker container image
#   login          — Authenticate Docker to ECR
#   push           — Tag + push image to ECR
#   update-lambda  — Point Lambda to the latest ECR image
#   deploy         — build → push → update-lambda (all-in-one)
#   clean          — Remove Docker image
#
# Prerequisites:
#   - Docker
#   - AWS CLI (authenticated)
# ────────────────────────────────────────────────────────────────────────────

AWS_ACCOUNT  ?= 659271373941
AWS_REGION   ?= ca-central-1
ECR_REPO     ?= pledgeproof-pdf2img
IMAGE_TAG    ?= latest
LAMBDA_NAME  ?= pledgeproof-pdf2img-prod

ECR_URI      = $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO)

.PHONY: build login push deploy update-lambda clean

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
deploy: build push update-lambda
	@echo "🚀 Done — Lambda $(LAMBDA_NAME) updated with $(ECR_URI):$(IMAGE_TAG)"

# ── Update Lambda to use the latest image ──
update-lambda:
	@echo "🔄 Updating Lambda $(LAMBDA_NAME)..."
	@aws lambda update-function-code \
		--function-name $(LAMBDA_NAME) \
		--image-uri $(ECR_URI):$(IMAGE_TAG) \
		--region $(AWS_REGION) \
		--no-cli-pager > /dev/null
	@echo "✓  Lambda updated"

# ── Cleanup ──
clean:
	@docker rmi $(ECR_REPO):$(IMAGE_TAG) $(ECR_URI):$(IMAGE_TAG) 2>/dev/null || true
	@echo "✓  Cleaned"
