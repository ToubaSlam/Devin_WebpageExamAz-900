# Runbook: How to Deploy a New Version

**Audience:** Any engineer with write access to the repository.  
**Goal:** Ship a code change from a local branch to production with zero manual steps after the PR is merged.

---

## Overview

```
Developer pushes branch
        │
        ▼
  GitHub Actions: lint → test → docker build (no push)
        │
        ▼
  Open Pull Request → terraform plan posted as PR comment
        │
        ▼
  PR reviewed & merged to main
        │
        ▼
  GitHub Actions: docker build → push to ACR → terraform apply → SSH deploy
        │
        ▼
  docker compose pull + up -d on Azure VM → smoke test: curl /health
```

---

## Step-by-step

### 1. Make your code change locally

```bash
git checkout -b feature/your-feature-name
# ... edit files ...
git add -p
git commit -m "feat: describe what changed and why"
git push -u origin feature/your-feature-name
```

### 2. Open a Pull Request

Go to `https://github.com/ToubaSlam/Devin_WebpageExamAz-900` → **New pull request** → base: `main`.

The pipeline automatically runs **lint → test → docker build** and posts a **Terraform plan** as a PR comment. Review the plan — it shows exactly which Azure resources will change.

### 3. Merge the PR

Click **Squash and merge**. This triggers the full deployment pipeline:

| Stage | What happens |
|---|---|
| `lint-and-test` | flake8 + pytest run |
| `build-and-push` | Docker image built, tagged with commit SHA, pushed to ACR |
| `terraform` | `terraform apply` provisions any new/changed Azure resources |
| `deploy` | SSH into VM → `docker compose pull` → `docker compose up -d` |
| Smoke test | `curl -sf http://localhost:5000/health` — fails pipeline if unhealthy |

### 4. Verify the deployment

```bash
curl http://<VM_PUBLIC_IP>:5000/health
# Expected: {"status": "healthy", "service": "devops-portfolio-api"}

curl http://<VM_PUBLIC_IP>:5000/info
# Expected: version field matches the commit SHA from your merge
```

Open Grafana at `http://<VM_PUBLIC_IP>:3000` → confirm error rate is 0%.

---

## Rollback

### Option A — Revert via git (recommended)

```bash
git revert <bad-commit-sha>
git push origin main    # triggers a new clean deployment
```

### Option B — Manual rollback on the VM

```bash
ssh azureuser@<VM_PUBLIC_IP>
cd /opt/portfolio
nano .env               # change IMAGE_TAG to last known-good SHA
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
curl -sf http://localhost:5000/health
```

---

## GitHub Secrets required

| Secret | Description |
|---|---|
| `ACR_LOGIN_SERVER` | e.g. `portfolioprodacr.azurecr.io` |
| `ACR_USERNAME` | ACR admin username |
| `ACR_PASSWORD` | ACR admin password |
| `AZURE_CREDENTIALS` | Service principal JSON from `az ad sp create-for-rbac` |
| `ARM_CLIENT_ID` | Service principal client ID |
| `ARM_CLIENT_SECRET` | Service principal secret |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID |
| `ARM_TENANT_ID` | Azure tenant ID |
| `SSH_PUBLIC_KEY` | Public key placed on VM by Terraform |
| `SSH_PRIVATE_KEY` | Private key used by the deploy job |
| `VM_PUBLIC_IP` | VM public IP (update after terraform apply) |
| `VM_ADMIN_USERNAME` | e.g. `azureuser` |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password |
