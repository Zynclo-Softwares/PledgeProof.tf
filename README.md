# PledgeProof — Infrastructure (Terraform)

AWS infrastructure managed via **HCP Terraform Stacks**. All resources deploy to `ca-central-1` (Canada Central) by default, with multi-region support via the `regions` variable.

## Deployment Model

Uses HCP Terraform Stacks — the root `components.tfcomponent.hcl` declares each module as a `component`, parameterized by region. The `deployments.tfdeploy.hcl` defines the `prod` deployment with all secrets injected via HCP Vault/Varset (never hardcoded).

Providers are configured in `providers.tfcomponent.hcl` — one AWS provider per region plus a dedicated `us-east-1` provider for ACM certificates required by Cognito and CloudFront.

---

## Module Overview

```
terraform/
├── components.tfcomponent.hcl    # Component declarations (wires modules to regions)
├── deployments.tfdeploy.hcl      # Prod deployment, secrets, input variables
├── providers.tfcomponent.hcl     # AWS providers (per-region + us-east-1)
├── variables.tfcomponent.hcl     # Shared variables (regions, secrets, tuning)
├── alb/                          # Application Load Balancer + HTTPS + DNS
├── cognito/                      # User authentication (email, Google, Apple)
├── compute/                      # ECS Fargate cluster + service + auto-scaling
├── dinov2-ml/                    # DINOv2 image embedding Lambda
├── dynamodb/                     # Single-table DynamoDB
├── pdf2img/                      # PDF-to-image conversion Lambda
├── resend-sync/                  # Scheduled email audience sync Lambda
└── s3/                           # S3 upload bucket
```

---

## Modules

### alb

Public entrypoint — ALB with HTTPS termination, HTTP→HTTPS redirect, and Route 53 DNS alias.

- **Resources:** `aws_lb`, `aws_lb_listener` (HTTP + HTTPS), `aws_lb_target_group`, `aws_security_group`, `aws_route53_record`, ACM certificate (DNS-validated)
- **Notable:** TLS 1.3 enforced via `ELBSecurityPolicy-TLS13-1-2-2021-06`
- **Outputs:** `cert_arn`, `alb_target_group_arn`, `alb_security_group_id`

### cognito

User Pool with email/password, Google OAuth, and Apple Sign-In.

- **Resources:** `aws_cognito_user_pool`, `aws_cognito_user_pool_client`, `aws_cognito_identity_provider` (Google + Apple), `aws_cognito_user_pool_domain` (custom domain), Route 53 record, ACM cert (us-east-1)
- **Outputs:** `cognito_domain`, `user_pool_id`, `app_client_id`, `user_pool_arn`

### compute

ECS Fargate service running the Elysia server as a single ARM64 container.

- **Resources:** `aws_ecs_cluster`, `aws_ecs_service`, `aws_ecs_task_definition`, `aws_ecr_repository`, `aws_cloudwatch_log_group`, auto-scaling resources, IAM roles/policies
- **IAM grants:** DynamoDB, S3, Lambda invoke, Cognito, Bedrock model access
- **Notable:** ARM64 (`FARGATE` launch type), auto-scaling enabled when `max_count > 1`
- **Outputs:** `ecr_repo_uri`

### dinov2-ml

Lambda for DINOv2 ViT-L image embeddings + cosine similarity (ONNX runtime, container image).

- **Resources:** `aws_lambda_function`, `aws_ecr_repository`, IAM role/policy, CloudWatch log group
- **Notable:** x86_64, ECR lifecycle keeps last 3 images
- **Outputs:** `function_arn`, `function_name`, `ecr_repository_url`

### pdf2img

Lambda for rendering PDF pages to JPEG images via PyMuPDF (container image).

- **Resources:** Same structure as dinov2-ml
- **Notable:** x86_64, used during proof lock creation and verification chat
- **Outputs:** `function_arn`, `function_name`, `ecr_repository_url`

### resend-sync

Scheduled Lambda that syncs Cognito user emails to a Resend audience for email marketing.

- **Resources:** `aws_lambda_function`, `aws_ecr_repository`, IAM role/policy, CloudWatch log group, `aws_scheduler_schedule_group`, 3 × `aws_scheduler_schedule`
- **Schedule:** Runs 3× daily (8:00 AM, 1:00 PM, 8:00 PM ET) via EventBridge Scheduler
- **Outputs:** `function_arn`, `function_name`, `ecr_repository_url`

### dynamodb

Single-table DynamoDB (`PledgeProof`) with GSI on `startTimeUtc` for schedule cron lookups.

- **Resources:** `aws_dynamodb_table` (main + optional dev table)
- **Notable:** PAY_PER_REQUEST billing, TTL enabled, point-in-time recovery, GSI `SK-PK-index`
- **Variables:** `enable_dev_table` toggle
- **Outputs:** `table_name`, `table_arn`, `dev_table_name`, `dev_table_arn`

### s3

Single S3 bucket for all uploads (images, documents, chat histories).

- **Resources:** `aws_s3_bucket`
- **Outputs:** `bucket_id`, `bucket_arn`

---

## Configuration

All variables are declared in `variables.tfcomponent.hcl`. Secrets are injected via the `prod` deployment block in `deployments.tfdeploy.hcl`.

Key variables:

| Variable | Description |
|---|---|
| `regions` | List of AWS regions (default: `["ca-central-1"]`) |
| `gcp_client_id` / `gcp_client_secret` | Google OAuth credentials |
| `apple_services_id` / `apple_team_id` / `apple_key_id` / `apple_private_key` | Apple Sign-In |
| `admin_password` | Admin route password for server |
| `resend_api_key` | Resend email API key |
| `task_cpu` / `task_memory` | ECS task sizing |
| `max_count` | ECS auto-scaling max (>1 enables scaling) |

---

## Applying Changes

Infrastructure is managed through HCP Terraform Stacks — changes are applied via the HCP UI or CLI, not `terraform apply` directly. Push changes to the repo and HCP picks them up automatically.

```bash
# Local validation only
terraform validate
terraform plan
```
