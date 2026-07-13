# Backend migration: AWS Fargate → Railway

Moves the PledgeProof backend (Bun/Elysia server, repo `Zynclo-Softwares/PledgeProof.server`)
off the ECS Fargate + ALB stack and onto Railway, while **keeping the same public
domain** `api.pledgeproof.zynclo.com` so no mobile-app release is needed.

Everything else in AWS stays exactly as-is: DynamoDB, S3, Cognito, the DINOv2 /
PDF2IMG / resend-sync Lambdas, and Bedrock. The server keeps calling them — it
just authenticates with an **IAM user's access keys** now instead of an ECS
task role.

---

## 0. BLOCKER — Railway token

The `RAILWAY_TOKEN` currently in the shell is **not authorized** for the Railway
API (verified: `me`, workspace, and project-token queries all return
`Not Authorized` / `Project Token not found`). Terraform's Railway provider has
to **create a project**, which needs an **Account** or **Workspace** token —
*not* a project token.

Do this once:

1. Create a token at **railway.com → (avatar) → Account Settings → Tokens**
   (personal) **or** **Workspace Settings → Tokens** (team). If you pick a
   workspace token, note the **workspace id**.
2. Add it to the HCP `pp_secrets` variable set as **`railway_token`** (sensitive).
   The Stack reads it via `store.varset.pp_secrets.stable.railway_token`.
3. If the token can see more than one workspace, set `railway_workspace_id` in
   `deployments.tfdeploy.hcl` (currently `""`).

**Do NOT test the token with `railway whoami`.** A workspace-scoped token
(scope = a workspace, e.g. "Rahat Bin Taleb's Projects") has no user identity,
so `whoami` returns "Unauthorized" even when the token is perfectly valid — this
is by design and is *not* an error. Test with the `projects` query instead:

```bash
curl -s -X POST https://backboard.railway.com/graphql/v2 \
  -H "Authorization: Bearer $RAILWAY_TOKEN" -H "Content-Type: application/json" \
  -d '{"query":"query { projects { edges { node { name } } } }"}'
# returns your project names  -> valid (Terraform will work)
# "Not Authorized"            -> dead/wrong value, regenerate
```

The token must be a workspace or account token (from railway.com → Account
Settings → Tokens, choosing the workspace), NOT a project token. For interactive
`railway` CLI use (`link`, `logs`, `up`), run `railway login` (browser) instead —
that's separate from this API token.

---

## 1. Architecture: before → after

| Concern            | Before (AWS)                                              | After (Railway)                                             |
|--------------------|----------------------------------------------------------|------------------------------------------------------------|
| Compute            | ECS Fargate service (`compute` component)                | Railway service (`railway` component)                      |
| Ingress / TLS      | ALB + ACM cert + HTTP→HTTPS (`alb` component)             | Railway edge (auto Let's Encrypt TLS)                      |
| Image build/deploy | GH Actions → ECR → `ecs update-service` (`server` CI)     | Railway auto-build from GitHub on push to `main`           |
| AWS auth           | ECS **task role** (temp creds via metadata)              | **IAM user access keys** (`iam-railway-user` component)    |
| Domain             | Route 53 **A-alias** `api.…` → ALB                        | Route 53 **CNAME** `api.…` → `*.up.railway.app` (unchanged host) |
| Port               | container port 80                                         | server binds Railway's `$PORT` (falls back to 80)          |

Unchanged: DynamoDB, S3, Cognito, DINOv2/PDF2IMG/resend-sync Lambdas, Bedrock,
QStash, RevenueCat, GitHub App.

---

## 2. Changes already made on this branch

**`terraform/` (repo `PledgeProof.tf`)**
- `railway/` — new module: `railway_project`, `railway_service` (GitHub source +
  region + replicas), `railway_variable_collection` (atomic env upsert),
  `railway_service_domain` (smoke-test URL), `railway_custom_domain` (registers
  `api.…`, exports `dns_record_value`). Modeled on the JustApply reference.
- `iam-railway-user/` — new module: IAM user + access key with a policy that
  **mirrors the old ECS task role exactly** (DynamoDB, S3, Bedrock, Lambda
  invoke, Cognito `AdminDeleteUser`).
- `components.tfcomponent.hcl` — **removed** `alb` + `compute`; **added**
  `iam_railway_user` + `railway`.
- `providers.tfcomponent.hcl` — added the `railway` provider (singleton).
- `variables.tfcomponent.hcl` — removed `compute_*`; added `railway_*`.
- `deployments.tfdeploy.hcl` — removed `compute_*`; added `railway_*` inputs.
- `outputs.tfcomponent.hcl` — new: `railway_service_domain`,
  `railway_custom_domain_dns_value`, `railway_project_id`.

Both new modules pass `terraform validate` against the real provider schemas.

**`server/` (repo `PledgeProof.server`)**
- `railway.json` — build (Dockerfile = `dockerfile`) + deploy (healthcheck
  `/health`, restart ON_FAILURE ×3).
- `src/index.ts` — `.listen({ port: Number(process.env.PORT) || 80, … })`
  (was hardcoded `80`). **Required** — Railway routes to `$PORT`.
- `.github/workflows/deploy.yml` — replaced the ECR/ECS deploy with a compile-check
  CI; Railway now owns deploys.

> The old `server/scripts/{build,deploy,update_task,desired}.sh` are now dead;
> remove them in cleanup (Phase G).

---

## 3. Environment variables (Railway service)

Set by the `railway` component (mirrors the old `task_env` + AWS creds). Values
flow from the HCP `pp_secrets` varset and other components — **none inline**.

| Var | Source |
|---|---|
| `ENV` | `"prod"` |
| `AWS_REGION` | region (`ca-central-1`) |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | `iam_railway_user` outputs (**new** — replaces task role) |
| `DYNAMO_TABLE` | `dynamodb` component |
| `S3_BUCKET` | `s3` component |
| `DINOV2_FUNCTION_NAME` / `PDF2IMG_FUNCTION_NAME` | lambda components |
| `COGNITO_USER_POOL_ID` | `cognito` component |
| `SERVER_URL` | `https://api.pledgeproof.zynclo.com` (unchanged) |
| `QSTASH_TOKEN` / `QSTASH_CURRENT_SIGNING_KEY` / `QSTASH_NEXT_SIGNING_KEY` | varset |
| `ADMIN_PASS` | varset |
| `GITHUB_APP_ID` / `GITHUB_INSTALLATION_ID` / `GITHUB_PRIVATE_KEY_PATH` / `GITHUB_WEBHOOK_SECRET` | varset |
| `REVENUECAT_API_KEY` | varset |

Notes:
- `GITHUB_PRIVATE_KEY_PATH` holds the **PEM contents** (the server's
  `loadPrivateKey()` accepts an inline key starting with `-----BEGIN`). Railway
  env vars support the multiline value.
- `.env` locally also has `RESEND_API_KEY` / `REVENUECAT_ADMIN_KEY`, but the
  server's `env.ts` schema does **not** read them, so they are intentionally
  omitted (matches the old prod task env).

---

## 4. IAM permission parity

`iam-railway-user` grants exactly what `compute/task.tf` granted the task role:

- **DynamoDB**: Get/Put/Update/Delete/Query/Scan/BatchGet/BatchWrite on the table + `index/*`
- **S3**: Get/Put/Delete/ListBucket on the bucket + `/*`
- **Bedrock**: `InvokeModel` on `anthropic.*` foundation models + `us.anthropic.*` inference profiles
- **Lambda**: `InvokeFunction` on the DINOv2 + PDF2IMG functions
- **Cognito**: `AdminDeleteUser` on the user pool

No resource has a VPC-endpoint or source-IP condition (verified), so these calls
work from Railway over the public internet with SigV4.

---

## 5. Prerequisites (one-time, manual)

1. **Railway account/workspace token** in the varset (Section 0).
2. **Install the Railway GitHub App** on `Zynclo-Softwares/PledgeProof.server`
   (Railway dashboard → New/Service → GitHub → authorize the repo). The provider
   cannot connect a repo the app can't see.
3. **Re-lock providers** so the Stack lock includes the Railway provider:
   ```bash
   cd terraform
   terraform stacks providers-lock
   git add .terraform.lock.hcl && git commit -m "chore: lock railway provider"
   ```
4. Confirm HCP can plan the Stack (the `prod` deployment picks up the branch).

---

## 6. Execution runbook

> Strategy: **provision Railway and prove it healthy while the ALB/ECS stack is
> still serving traffic**, flip DNS with a single atomic Route 53 change (zero
> gap, instant rollback), then decommission AWS. No user-visible downtime.

### Phase A — ship the server changes
```bash
cd server
git checkout main && git merge dev   # or open dev → main PR
# ensure railway.json + the src/index.ts PORT change + CI are on main
git push origin main
```
Railway auto-deploys from `main`, so these must land **before** Phase B.

### Phase B — provision Railway (AWS stays up)
Merge the `terraform` changes and let HCP plan/apply the `prod` deployment
(or run the Stack apply). This creates: `iam_railway_user`, the Railway
project/service, env vars, the `*.up.railway.app` domain, and **registers** the
custom domain (DNS not flipped yet). The `alb` + `compute` components are removed
from config but **do not apply that removal yet** — see Phase F.

> If you want to stage it: apply with the `alb`/`compute` blocks still present
> (revert Section 2's component removal), add only `iam_railway_user` + `railway`,
> then remove `alb`/`compute` in Phase F. This keeps both stacks live
> simultaneously and is the safest ordering.

Grab the outputs:
```bash
# From HCP UI (Stack → Outputs) or:
terraform stacks output railway_service_domain          # e.g. pledgeproof-api-prod.up.railway.app
terraform stacks output railway_custom_domain_dns_value # the CNAME target for cutover
```

### Phase C — smoke test on the Railway URL
```bash
export RAILWAY_API_TOKEN="<account/workspace token>"
railway link            # pick the pledgeproof project/service
railway status
railway variables       # confirm every var from Section 3 is present
railway logs            # look for "server started" and no env-validation fatal

SVC="https://pledgeproof-api-prod.up.railway.app"
curl -fsS "$SVC/health"   # -> {"status":"ok",...}
curl -fsS "$SVC/"         # -> welcome message
```
Exercise a couple of real, read-only flows (an authenticated GET that hits
DynamoDB/S3) to confirm the **IAM keys work end-to-end**, not just `/health`.
If Bedrock/Lambda calls fail with `AccessDenied`, the IAM policy is the place to
look.

### Phase D — DNS cutover (atomic, ALB still alive)
`api.…` is currently a Route 53 **A-alias** to the ALB. A CNAME can't coexist
with it, so swap both in **one atomic change batch** (no NXDOMAIN gap; resolvers
holding the cached A keep hitting the still-alive ALB until TTL):

```bash
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name zynclo.com \
  --query 'HostedZones[0].Id' --output text | sed 's#/hostedzone/##')
NAME="api.pledgeproof.zynclo.com."
TARGET="$(terraform stacks output -raw railway_custom_domain_dns_value)"   # *.up.railway.app

# capture the exact existing A-alias so we can DELETE it precisely
OLD=$(aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" \
  --query "ResourceRecordSets[?Name=='$NAME' && Type=='A']" --output json)

cat > /tmp/cutover.json <<JSON
{ "Changes": [
  { "Action": "DELETE", "ResourceRecordSet": $(echo "$OLD" | jq '.[0]') },
  { "Action": "CREATE", "ResourceRecordSet": {
      "Name": "$NAME", "Type": "CNAME", "TTL": 300,
      "ResourceRecords": [{ "Value": "$TARGET" }] } }
] }
JSON

aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" \
  --change-batch file:///tmp/cutover.json
```

### Phase E — verify the real domain
```bash
dig +short api.pledgeproof.zynclo.com          # -> the railway CNAME/target
# Railway issues TLS within ~seconds–minutes of the CNAME resolving:
curl -fsS https://api.pledgeproof.zynclo.com/health
```
Watch Railway logs + the mobile app. Keep the ALB alive here — **rollback is one
reverse change batch** (CREATE the A-alias, DELETE the CNAME). Bake for as long
as you like (hours/overnight).

### Phase F — decommission AWS
Once stable, apply the removal of the `alb` + `compute` components (already done
in config). This destroys the ECS cluster/service/task, ECR repo, ALB, listeners,
target group, SGs, and ACM cert.

Two gotchas:
- The `alb` module also "owns" the old `api.…` **A-alias** in Terraform state,
  which you replaced out-of-band in Phase D. Before destroy, **remove that one
  resource from Stack state** (HCP UI → Stack → Resources → the alb component's
  `aws_route53_record.alb_alias` → *Remove from state*) so the destroy doesn't
  try to delete a record that's now a CNAME. The CNAME is untouched.
- ECR repo `pledgeproof-server` may hold images; if destroy errors on a non-empty
  repo, delete the images first (`aws ecr batch-delete-image …`) or add
  `force_delete = true` before removing the module.

### Phase G — repo & IaC cleanup
- `server/`: delete `scripts/build.sh`, `scripts/deploy.sh`, `scripts/update_task.sh`,
  `scripts/desired.sh` (ECS-only). Keep `ngrok-update.sh` if still used for `dev`.
- Delete the AWS OIDC role `GitHubActions-PledgeProof-Server` (no longer used).
- Delete the `terraform/alb/` and `terraform/compute/` module dirs.
- Optional IaC hygiene: `terraform import` the new `api.…` CNAME into a small
  `dns` module (or add it to the `railway` module) so DNS is code-managed again.

---

## 7. Connectivity tweaks in other components

Because the **domain is preserved**, most integrations need **no change** — just
verification:

- **Mobile app** (`lib/api.ts` → `PROD_URL = https://api.pledgeproof.zynclo.com`):
  **no change, no app release.** This is the whole reason we keep the domain.
- **QStash (Upstash)**: schedules/callbacks target `SERVER_URL` (unchanged).
  Signing keys are set. Nothing to do; confirm a scheduled job round-trips.
- **RevenueCat webhook**: dashboard URL is `…/webhooks/revenuecat` on the same
  domain — no change. Send a test event post-cutover.
- **GitHub App webhook**: URL is on the same domain (`…/webhooks/github`) — no
  change. Verify in the App settings that the webhook still delivers (200s).
- **Cognito**: unaffected; the server now deletes users via the IAM user's
  `AdminDeleteUser` instead of the task role.
- **DynamoDB / S3 / Bedrock / DINOv2 / PDF2IMG Lambdas**: unaffected; reached via
  the IAM user keys. No bucket/endpoint policy blocks Railway (verified).
- **resend-sync Lambda**: fully independent; unaffected.

The only genuinely new wiring is **IAM keys → Railway env** (handled by the
`iam_railway_user` → `railway` component chain).

---

## 8. Rollback

- **Before Phase F** (ALB still alive): reverse the Phase D change batch —
  `CREATE` the A-alias back, `DELETE` the CNAME. Traffic returns to ECS in one
  TTL. Nothing else to undo.
- **After Phase F**: ECS/ALB are gone; roll back by re-applying the `alb` +
  `compute` components and pushing an image to a re-created ECR, then flipping
  DNS back. Slower — so only run Phase F once you're confident.

---

## 9. Latency & cost notes

- **Region**: AWS is `ca-central-1` (Montréal). Railway `ord` (Chicago) is the
  closest region → lowest round-trip for the per-request DynamoDB/S3/Bedrock/
  Lambda calls. `sfo` adds ~50–70 ms/call. Some Railway plans pin region; if
  `ord` isn't honored, that's a plan limitation, not a config bug.
- Railway replaces ALB + Fargate hourly costs with Railway's usage billing; the
  DINOv2/PDF2IMG Lambdas and DynamoDB/S3 costs are unchanged.
