# GitHub Actions & Secrets

Required secrets:
- `AWS_ACCOUNT_ID`
- `AWS_REGION`
- `AWS_ROLE_TO_ASSUME` (OIDC role for GitHub → AWS)
- `ECR_REPO_BACKEND` (e.g., vgl-backend)
- `ECR_REPO_FRONTEND` (e.g., vgl-frontend)
- `DB_PASSWORD`, `APP_KEY` (or your framework's secrets)

Enable **Environments**:
- `staging`, `production` with required reviewers for deploy.
