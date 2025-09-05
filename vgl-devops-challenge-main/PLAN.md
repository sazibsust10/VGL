# VGL DevOps Plan

**Author:** Mahmudul Hassan  
**Date:** 2025-09-05

## Summary of Changes
- Added Dockerfiles for **backend (PHP-FPM + Nginx)** and **frontend (Node build + Nginx)**.
- Added `docker-compose.yml` for reproducible local development with hot-reload, a MySQL-compatible DB, and Redis.
- Introduced GitHub Actions:
  - `ci.yml` for build, lint, tests, and Docker image build to ECR (on PR/merge).
  - `cd.yml` for deploy to **AWS ECS Fargate** (manual approval via environments). 
- Added Terraform to provision AWS: VPC, subnets, ECS/Fargate services for frontend & backend, RDS MySQL, ElastiCache Redis, ECR, ALB, ACM, Route53, S3+CloudFront for static assets.
- Added Ansible playbooks for app configuration tasks, DB migrations, cache warmup, and smoke tests post-deploy.
- Added `.devcontainer` + `Makefile` + `pre-commit` for consistent local workflows. 
- Added documentation: `README-DEV.md` and comments within infra code.

## Assumptions
- Backend is PHP (Laravel/Symfony-like) and uses MySQL and optionally Redis.
- Frontend is Vue + TypeScript (Vite) and builds to static assets served via Nginx or CloudFront.
- No hardcoded secrets in repo; secrets provided via GitHub Actions & AWS SSM Parameter Store.
- Domain is managed in Route53 (or delegated), TLS via ACM in us-east-1 for CloudFront and region X for ALB.
- Container registry is **Amazon ECR**; runtime is **ECS Fargate** (serverless containers).

## What I Achieved
- **Deployment-ready**: Infra-as-code with Terraform + CI/CD pipelines producing versioned images and blue/green-capable ECS deploys.
- **Local dev reproducibility**: `docker-compose` spins up backend, frontend, DB, Redis; `.env.example` and Make targets to set up quickly.
- **Docs**: this PLAN.md explains changes, trade-offs, and next steps. Ops docs in `README-DEV.md`.
- **DevOps improvements**: security baselines, branch protections, pre-commit, image scanning, SBOM, least-privilege IAM, cost guardrails.

## What’s Missing / Trade‑offs
- Terraform only includes **reference modules** and opinionated defaults; needs app-specific tuning (CPU/RAM, desired count, health checks, env variables).
- Minimal Ansible focused on app-level tasks; infra is Terraform-first.
- Integration tests are stubbed; replace with real tests.
- Observability (OpenTelemetry) is optional/stubbed; complete dashboards/alerts later.

## Next Steps (If I had more time)
- Add **Helm** + EKS variant for Kubernetes.
- Add **feature environments** (preview stacks) using Terraform workspaces.
- Add **KMS-encrypted** SSM parameters and rotation via Secrets Manager.
- Add **load tests** (k6) and budget alerts to simulate/observe scale behavior.
- Implement **zero-downtime DB migrations** strategy (pt-online-schema-change / gh-ost for MySQL).

## Risks, Cost & Scaling Considerations
- **Costs**: Prefer Fargate with autoscaling; RDS in `db.t4g.micro/small` for dev/stage; use **Graviton** where possible (ECS, RDS) to reduce cost 20–30%. 
- **Scaling**: ALB + ECS target tracking policy on CPU/ReqCount; RDS with read-replica for heavy read; Redis for sessions/cache/queues.
- **Resilience**: Multi-AZ subnets; health checks; circuit breakers and retries at app layer.
- **Security**: Private subnets for services/DB; WAF on ALB/CloudFront; SSM for secrets; ECR image scanning; least-privilege IAM for tasks.
- **FinOps**: Tagging, Cost Explorer cost categories, Budgets + Alerts, rightsizing recommendations, turn off idle stage env nightly via scheduler.

## How to Use This Work
1. Copy the contents of this ZIP to the root of your repo.
2. Adjust variables in `infra/terraform/variables.tf` and `terraform.tfvars` (domain, AWS account/region, DB size, image names).
3. Create required GitHub **repository secrets** (see `.github/README.md`):
   - `AWS_ACCOUNT_ID`, `AWS_REGION`, `AWS_ROLE_TO_ASSUME`
   - `ECR_REPO_BACKEND`, `ECR_REPO_FRONTEND`
   - `DB_PASSWORD`, `APP_KEY` (Laravel) or equivalent
4. Run local dev: `make up` then open http://localhost:5173 (frontend) and http://localhost:8080 (backend).
5. Trigger CI by pushing to a branch; merge to `main` to deploy (or use environment approval).

## Folder Map
```
.github/workflows/ci.yml
.github/workflows/cd.yml
.github/README.md
docker/backend/Dockerfile
docker/backend/nginx.conf
docker/frontend/Dockerfile
docker/frontend/nginx.conf
docker/php/conf.d/app.ini
docker-compose.yml
infra/terraform/* (modules for vpc, ecs, rds, redis, ecr, alb, s3, cloudfront)
ops/ansible/* (deploy, migrate, smoke)
.devcontainer/devcontainer.json
Makefile
README-DEV.md
.pre-commit-config.yaml
.editorconfig
.env.example
```

## Validation
- `terraform validate` and `tflint` pass on base config.
- `docker compose build` succeeds on both services.
- GitHub Actions jobs lint and build images; deployment is gated by environment approvals and runs `ansible` smoke tests.
