Azure Security Dashboard

Enterprise-grade security monitoring dashboard that aggregates Microsoft Defender for Cloud alerts, Azure Activity Logs, and Log Analytics queries into a unified SOC-style interface, reducing mean time to detect (MTTD) security issues across Azure environments.

![Azure](https://img.shields.io/badge/Azure-AKS%20%7C%20Defender%20%7C%20Log%20Analytics-0078D4)
![Python](https://img.shields.io/badge/Python-3.12%20%7C%20Flask-blue)
![IaC](https://img.shields.io/badge/IaC-Terraform%20%2B%20Bicep-purple)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20%2B%20Azure%20DevOps-green)
![Security](https://img.shields.io/badge/Security-Checkov%20%7C%20tfsec%20%7C%20Trivy-red)
![Auth](https://img.shields.io/badge/Auth-OIDC%20%7C%20Zero%20Secrets-brightgreen)

## Overview

A custom-built security operations dashboard deployed on Azure Kubernetes Service (AKS) with dual IaC implementations (Terraform + Bicep) and dual CI/CD pipelines (GitHub Actions + Azure DevOps) — both authenticated via OIDC Workload Identity Federation with zero stored secrets.

**Key Metrics:**
- Centralizes **15+ security signals** from Defender for Cloud, Activity Log, and Log Analytics
- Monitors **46+ Azure resources** across **21 resource types** in real time
- Displays **Secure Score**, active alerts, security recommendations, and resource inventory
- Achieves **zero hardcoded secrets** via OIDC federation across all authentication flows
- Passes **triple-layer security scanning** (Checkov, tfsec, Trivy) on every deployment
- Dual IaC: identical infrastructure deployable via **Terraform or Bicep**
- Dual CI/CD: full pipelines on both **GitHub Actions and Azure DevOps**

## Architecture

<img width="1322" height="822" alt="architecture drawio" src="https://github.com/user-attachments/assets/d6ad867f-46d5-4425-8675-3d7a1e235743" />

## Security Data Sources

### Defender for Cloud
| Signal | Description | Dashboard View |
|--------|-------------|----------------|
| Secure Score | Compliance percentage across CIS benchmarks | Real-time gauge with points breakdown |
| Security Alerts | Active threats with severity classification | Filterable list (High/Medium/Low) |
| Recommendations | Actionable hardening guidance | Status table with severity and category |
| Container Scanning | ACR image vulnerability assessment | Integrated via Defender for Containers |

### Log Analytics (KQL)
| Query Target | Description | Dashboard View |
|-------------|-------------|----------------|
| `AzureActivity` | Subscription-level operations | Activity feed with caller, IP, and status |
| `SigninLogs` | Failed authentication attempts | Aggregated failure counts by user and IP |
| Container Insights | AKS pod and node telemetry | Cluster health monitoring |

### Resource Inventory
| Signal | Description |
|--------|-------------|
| Resource count | Total monitored resources by type |
| Resource groups | Organized by deployment boundary |

## Infrastructure as Code

This project demonstrates **dual IaC proficiency** with identical infrastructure deployable via either tool:

### Terraform
```
terraform/
├── main.tf                          # Root orchestration
├── variables.tf                     # Input parameters
├── outputs.tf                       # Deployment outputs
├── providers.tf                     # AzureRM + backend config
├── .checkov.yml                     # Security scan skip config
└── modules/
    ├── resource_group/              # Resource group + tags
    ├── acr/                         # Container registry (Basic SKU)
    ├── log_analytics/               # Log Analytics workspace
    ├── defender/                    # Defender plans + diagnostic settings
    ├── aks/                         # AKS cluster (OIDC, Workload Identity,
    │                                #   Azure CNI Overlay, Network Policy,
    │                                #   Azure AD RBAC, API IP restriction)
    └── workload_identity/           # Managed identity + federated credential
                                     #   + 4 RBAC role assignments
```

**Backend:** Remote state in Azure Storage Account with blob encryption

**Import:** All Phase 1 console-built resources imported via `terraform import`: zero downtime migration to IaC

### Bicep
```
bicep/
├── main.bicep                       # Subscription-scoped orchestration
├── main.bicepparam                  # Parameter file
└── modules/
    ├── acr.bicep                    # Container registry
    ├── log-analytics.bicep          # Log Analytics workspace
    ├── defender.bicep               # Defender + diagnostics
    ├── aks.bicep                    # AKS cluster (matching Terraform config)
    └── workload-identity.bicep      # Managed identity + federation + RBAC
```

**Deployment:** Single `az deployment sub create` deploys entire environment

## CI/CD Pipelines

### GitHub Actions (`.github/workflows/ci-cd.yml`)

| Stage | Actions | Gate |
|-------|---------|------|
| **Security Scanning** | Checkov (Terraform), tfsec (Terraform), Trivy (filesystem) | Blocks on CRITICAL |
| **Build & Push** | Docker build, push to ACR, Trivy image scan | Blocks on CRITICAL |
| **Terraform Deploy** | `init` → `plan` → `apply` with OIDC auth | No manual approval (dev) |
| **Deploy to AKS** | Whitelist runner IP → kubectl apply → verify → cleanup IP | Rollout health check |

**Authentication:** GitHub OIDC → Azure AD federated credentials (zero secrets)

### Azure DevOps (`azure-pipelines.yml`)

| Stage | Actions | Gate |
|-------|---------|------|
| **Security Scanning** | Checkov, tfsec, Trivy (PowerShell Core) | Blocks on CRITICAL |
| **Build & Push** | Docker build, push to ACR, Trivy image scan | Blocks on CRITICAL |
| **Terraform Deploy** | `init` → `plan` → `apply` with OIDC via service connection | No manual approval (dev) |
| **Deploy to AKS** | Whitelist runner IP → kubectl apply → verify → cleanup IP | Rollout health check |

**Authentication:** Azure DevOps Workload Identity federation via service connection (zero secrets)

**Self-hosted agent** on Windows with PowerShell Core scripting

## Security Scanning Results

### Checkov (Terraform)
- **34 passed** / 0 failed (18 findings triaged and documented in `.checkov.yml`)
- Covers: ACR admin disabled, AKS Network Policy, RBAC enabled, Azure Policy addon, logging configured, upgrade channel set, dashboard disabled

### tfsec
- **8 passed** / 0 failed
- Covers: API server IP restriction, RBAC permissions, authorized IP ranges

### Trivy (Container Image)
- **0 CRITICAL** / 0 HIGH in application dependencies
- Base image (Debian) LOW/MEDIUM findings documented as accepted risk (no upstream fixes available)

## Security Hardening

| Control | Implementation |
|---------|---------------|
| **Zero stored secrets** | OIDC Workload Identity Federation for all auth flows |
| **API server restriction** | AKS authorized IP ranges (allowlisted CIDRs only) |
| **Local accounts disabled** | Azure AD RBAC enforced, no kubeconfig admin access |
| **Network policy** | Azure Network Policy engine (pod-to-pod traffic control) |
| **Container scanning** | Defender for Containers + Trivy in CI/CD pipeline |
| **IaC scanning** | Checkov + tfsec on every push, blocks on failures |
| **Image cleaner** | AKS auto-removes stale images weekly |
| **Non-root container** | Dockerfile runs as `appuser`, not root |
| **Auto-upgrade** | AKS patch channel with weekly maintenance windows |
| **ACR admin disabled** | Pull access via AKS managed identity (AcrPull RBAC) |

## Quick Start

### Prerequisites
- Azure subscription with Contributor access
- Azure CLI, Terraform, Docker, kubectl, kubelogin
- Python 3.12+

### Deploy with Terraform

```bash
# Clone repository
git clone https://github.com/AFP9272000/azure-security-dashboard.git
cd azure-security-dashboard/terraform

# Create backend storage (one-time)
az storage account create --name secdashboardtfstate --resource-group security-dashboard \
  --location eastus --sku Standard_LRS --allow-blob-public-access false
az storage container create --name tfstate --account-name secdashboardtfstate --auth-mode login

# Initialize and deploy
terraform init
terraform plan -out=tfplan \
  -var="subscription_id=YOUR_SUB_ID" \
  -var="tenant_id=YOUR_TENANT_ID" \
  -var="authorized_ip_ranges=[\"YOUR_IP/32\"]"
terraform apply tfplan
```

### Deploy with Bicep

```bash
az deployment sub create --location eastus \
  --template-file bicep/main.bicep \
  --parameters bicep/main.bicepparam
```

### Run Locally

```bash
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
cp .env.example .env           # Fill in subscription + workspace IDs
az login
python -m app.main             # http://localhost:8080
```

### Container Build

```bash
docker build -t azure-security-dashboard .
docker run -p 8080:8080 \
  -e AZURE_SUBSCRIPTION_ID=your-sub-id \
  -e LOG_ANALYTICS_WORKSPACE_ID=your-workspace-id \
  azure-security-dashboard
```

## Project Structure

```
azure-security-dashboard/
├── .github/workflows/
│   └── ci-cd.yml                    # GitHub Actions pipeline (OIDC)
├── azure-pipelines.yml              # Azure DevOps pipeline (Workload Identity)
├── app/
│   ├── main.py                      # Flask application + API endpoints
│   ├── azure_client.py              # Azure SDK integration (Defender, Log Analytics, ARM)
│   ├── templates/
│   │   ├── base.html                # SOC dark theme layout
│   │   ├── dashboard.html           # Main overview (Secure Score, alerts, activity)
│   │   ├── alerts.html              # Detailed alert view with severity filtering
│   │   └── activity.html            # Activity log with caller/IP/status
│   └── static/css/style.css         # Enterprise dark theme CSS
├── k8s/
│   ├── deployment.yaml              # AKS deployment + LoadBalancer service
│   └── service-account.yaml         # Workload Identity service account
├── terraform/                       # Terraform IaC (modular)
│   ├── modules/
│   │   ├── resource_group/
│   │   ├── acr/
│   │   ├── log_analytics/
│   │   ├── defender/
│   │   ├── aks/
│   │   └── workload_identity/
│   └── .checkov.yml                 # Documented security scan exceptions
├── bicep/                           # Bicep IaC (Azure-native)
│   ├── main.bicep
│   └── modules/
│       ├── acr.bicep
│       ├── log-analytics.bicep
│       ├── defender.bicep
│       ├── aks.bicep
│       └── workload-identity.bicep
├── Dockerfile                       # Multi-stage, non-root, health check
├── requirements.txt
└── README.md
```

## Skills Demonstrated

| Category | Technologies |
|----------|-------------|
| **Azure Services** | AKS, ACR, Defender for Cloud, Log Analytics, Azure AD, Managed Identity, Key Vault (planned) |
| **Security** | Workload Identity (OIDC), Network Policy, API IP restriction, Defender CSPM, container scanning |
| **IaC** | Terraform (modular, remote state, import) + Bicep (subscription-scoped, parameterized) |
| **CI/CD** | GitHub Actions (OIDC) + Azure DevOps (Workload Identity, self-hosted agent) |
| **Containers** | Docker (non-root, health checks), Kubernetes (deployments, services, probes, RBAC) |
| **Security Scanning** | Checkov, tfsec, Trivy (IaC + container image + filesystem) |
| **Languages** | Python (Flask, Azure SDK), KQL, HCL, Bicep, YAML, Bash, PowerShell |
| **DevSecOps** | Shift-left scanning, pipeline security gates, documented triage, zero-secret architecture |

## Related Projects

- [CloudTrail Security Monitor](https://github.com/AFP9272000/cloudtrail-security-monitor) — AWS real-time security monitoring with Lambda, Security Hub, and EventBridge
- [Security Event Aggregator](https://github.com/AFP9272000/security-event-aggregator) — Containerized microservices on ECS Fargate with MITRE ATT&CK mappings
- [Secure Juice Shop](https://github.com/AFP9272000/secure-vulnerable-website-juiceshop) — Enterprise DevSecOps pipeline with Checkov, tfsec, Trivy, SARIF

## License

MIT License - see [LICENSE](LICENSE) for details.

---

**Addison Pirlo** — [LinkedIn](https://www.linkedin.com/in/addison-pirlo-98b1a8297/) | [Email](mailto:addisonpirlo2@gmail.com)
