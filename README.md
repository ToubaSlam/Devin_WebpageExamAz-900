# DevOps Portfolio Project

A production-grade DevOps portfolio built by a QA engineer transitioning to DevOps.  
Demonstrates end-to-end ownership: from a Python REST API to fully automated cloud infrastructure, CI/CD, and observability.

---

## Architecture

```
                        ┌─────────────────────────────────────────────┐
                        │               GitHub Repository               │
                        │                                               │
                        │  Push / PR  ──►  GitHub Actions Pipeline     │
                        │                      │                        │
                        │        ┌─────────────┼─────────────┐         │
                        │        ▼             ▼             ▼         │
                        │    Lint/Test    Docker Build   Terraform      │
                        │                     │          Plan/Apply     │
                        └─────────────────────┼───────────────────────-┘
                                              │ push image
                                              ▼
                               ┌──────────────────────────┐
                               │   Azure Container Registry│
                               │   (ACR — Docker images)   │
                               └──────────────┬───────────┘
                                              │ SSH + docker compose pull
                                              ▼
                    ┌─────────────────────────────────────────────────┐
                    │               Azure Linux VM                     │
                    │                                                  │
                    │  ┌──────────────┐  ┌────────────┐  ┌─────────┐ │
                    │  │  Flask API   │  │ Prometheus  │  │ Grafana │ │
                    │  │  :5000       │  │  :9090      │  │  :3000  │ │
                    │  └──────┬───────┘  └─────┬──────┘  └────┬────┘ │
                    │         │  /metrics       │  scrape      │ viz  │
                    │         └─────────────────┘              │      │
                    │              Docker "monitoring" network ─┘      │
                    │                                                  │
                    │  Provisioned by Terraform (VNet, NSG, Public IP) │
                    └─────────────────────────────────────────────────┘
```

**Draw this in draw.io using the description above** — place it at the top of your portfolio.

---

## Project Overview — What Each Tool Does

| Tool | Role in this project |
|---|---|
| **Python / Flask** | REST API serving `/health`, `/status`, `/info` endpoints |
| **pytest** | Unit tests verifying each endpoint returns the correct status code and JSON shape |
| **Docker** | Packages the app and all its dependencies into a portable, reproducible image |
| **Docker Compose** | Orchestrates Flask + Prometheus + Grafana as a single stack locally and on the VM |
| **Terraform** | Declares Azure infrastructure as code — resource group, VNet, NSG, ACR, Linux VM |
| **Azure** | Cloud provider hosting the VM, container registry, and remote Terraform state |
| **GitHub Actions** | Runs CI (lint/test) on every PR and CD (build/push/deploy) on every merge to main |
| **Prometheus** | Time-series database that scrapes `/metrics` from Flask every 15 seconds |
| **Grafana** | Dashboards over Prometheus data — request rate, latency, error rate |
| **Datadog** (optional) | APM + infrastructure monitoring via ddtrace agent sidecar |

---

## Repository Structure

```
.
├── app/
│   ├── __init__.py
│   ├── main.py              # Flask application (Prometheus instrumented)
│   └── main_dd.py           # Datadog APM variant
├── tests/
│   └── test_app.py          # pytest unit tests
├── Dockerfile               # Multi-stage build (builder + slim runtime)
├── docker-compose.yml       # Local dev stack
├── docker-compose.prod.yml  # Production stack (image from ACR, resource limits)
├── docker-compose.datadog.yml  # Optional: add Datadog agent
├── requirements.txt
├── requirements-dev.txt
├── pytest.ini
├── .flake8
├── .env.example
├── terraform/
│   ├── main.tf              # Root module — wires networking + ACR + VM
│   ├── variables.tf
│   ├── outputs.tf
│   ├── modules/
│   │   ├── networking/      # VNet, subnet, NSG, public IP
│   │   ├── acr/             # Azure Container Registry
│   │   └── vm/              # Linux VM + cloud-init Docker install
│   └── environments/
│       ├── dev/terraform.tfvars
│       └── prod/terraform.tfvars
├── .github/
│   └── workflows/
│       └── deploy.yml       # Full CI/CD pipeline
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yml   # Scrape config
│   │   └── alert_rules.yml  # HighErrorRate, HighLatency, ApiDown alerts
│   └── grafana/
│       ├── provisioning/    # Auto-provision datasource + dashboard location
│       └── dashboards/
│           └── flask_api.json  # Pre-built Grafana dashboard
└── runbooks/
    ├── deploy-new-version.md    # Step-by-step deploy guide
    └── incident-response.md     # On-call checklist
```

---

## Running Locally with Docker Compose

### Prerequisites

- Docker Desktop (Mac/Windows) or Docker Engine + Compose plugin (Linux)
- Git

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/ToubaSlam/Devin_WebpageExamAz-900.git
cd Devin_WebpageExamAz-900

# 2. Start the full stack (Flask + Prometheus + Grafana)
docker compose up --build

# 3. Test the API
curl http://localhost:5000/health
curl http://localhost:5000/status
curl http://localhost:5000/info

# 4. Open Prometheus  →  http://localhost:9090
# 5. Open Grafana     →  http://localhost:3000  (admin / admin)
#    Navigate to Dashboards → Portfolio → Flask API Dashboard

# 6. Run unit tests (outside Docker, in a virtualenv)
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
pytest
```

---

## Deploying to Azure with Terraform

### Prerequisites

- Azure CLI: `az login`
- Terraform >= 1.7: `terraform -version`
- An SSH key pair: `ssh-keygen -t ed25519 -C "portfolio-vm"`

### One-time: create the Terraform remote state bucket

```bash
az group create --name portfolio-tfstate-rg --location eastus
az storage account create \
  --name portfoliotfstate \
  --resource-group portfolio-tfstate-rg \
  --sku Standard_LRS \
  --encryption-services blob
az storage container create \
  --name tfstate \
  --account-name portfoliotfstate
```

### Deploy

```bash
cd terraform

# Initialise (downloads providers, configures remote state)
terraform init

# Preview changes — always read this before applying
terraform plan \
  -var-file="environments/dev/terraform.tfvars" \
  -var="ssh_public_key=$(cat ~/.ssh/id_ed25519.pub)"

# Provision infrastructure (takes ~3 minutes)
terraform apply \
  -var-file="environments/dev/terraform.tfvars" \
  -var="ssh_public_key=$(cat ~/.ssh/id_ed25519.pub)"

# Note the outputs
terraform output
```

After apply, the VM needs ~2 minutes for cloud-init to finish installing Docker.

---

## CI/CD Pipeline Stages

| Stage | Trigger | What happens |
|---|---|---|
| `lint-and-test` | Every PR + push to main | flake8 lint, pytest with coverage |
| `build-and-push` | Every PR (build only) / push to main (build + push to ACR) | Docker multi-stage build |
| `terraform` | Every PR (plan) / push to main (apply) | Infrastructure as code |
| `deploy` | Push to main only | SSH → `docker compose pull` → `docker compose up -d` → smoke test |

### Required GitHub Secrets

Set these under **Settings → Secrets and variables → Actions**:

```
ACR_LOGIN_SERVER, ACR_USERNAME, ACR_PASSWORD
AZURE_CREDENTIALS, ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID
SSH_PUBLIC_KEY, SSH_PRIVATE_KEY
VM_PUBLIC_IP, VM_ADMIN_USERNAME
GRAFANA_ADMIN_PASSWORD
```

Generate `AZURE_CREDENTIALS`:
```bash
az ad sp create-for-rbac --name "portfolio-cicd" \
  --role contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth
```

---

## Monitoring

| URL | Service | Credentials |
|---|---|---|
| `http://<VM_IP>:5000/metrics` | Prometheus scrape endpoint | None |
| `http://<VM_IP>:9090` | Prometheus UI | None |
| `http://<VM_IP>:3000` | Grafana | admin / set via `GRAFANA_ADMIN_PASSWORD` |

The pre-built **Flask API Dashboard** shows:
- Error rate (5xx %) — alert fires if > 5%
- Request rate (req/s)
- p95 response latency — alert fires if > 1 s
- Request count by HTTP status code over time
- Response time percentiles (p50, p95, p99)

---

## What I Learned

**Docker Compose networking** — Services on the same Compose network reach each other by service name (e.g. `prometheus` scrapes `http://api:5000/metrics`). Docker's embedded DNS resolves service names to container IPs automatically. Port mappings (`5000:5000`) only expose a service to the *host* — they're not required for container-to-container communication.

**Docker health checks** — The `HEALTHCHECK` instruction in the Dockerfile and the `healthcheck:` block in compose let Docker know when a container is *actually ready*, not just started. The `depends_on: condition: service_healthy` in compose waits for the upstream container's health check to pass before starting the downstream one.

**Terraform modules** — Breaking infrastructure into reusable modules (`networking`, `acr`, `vm`) mirrors how real engineering teams organise Terraform at scale. Each module has its own `variables.tf` and `outputs.tf` so the root module stays clean.

**Terraform remote state** — Storing state in Azure Blob Storage means the CI pipeline and every team member operate on the same known state, preventing drift and conflicts.

**Prometheus data model** — Metrics are stored as time series: `metric_name{label="value"} value timestamp`. `rate()` calculates per-second rate over a time window. `histogram_quantile()` computes percentiles from histogram buckets.

**CI/CD gates** — Running `terraform plan` on PRs (not apply) gives reviewers visibility into infrastructure changes without risk. `terraform apply` only runs after a human approves the merge.

**Production vs dev compose** — The prod file never builds images locally — it always pulls from the registry. Resource limits (`cpus`, `memory`) prevent noisy-neighbour issues. Named volumes (`portfolio_prometheus_data`) survive container replacements so metrics history is preserved across deploys.

---

## Author

**Touba Slam** — QA Automation Engineer transitioning to DevOps.  
GitHub: [github.com/ToubaSlam](https://github.com/ToubaSlam)
