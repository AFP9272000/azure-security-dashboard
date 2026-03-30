# Azure Security Dashboard

Enterprise-grade security monitoring dashboard for Azure environments. Aggregates data from Microsoft Defender for Cloud, Azure Activity Log, and Log Analytics into a unified dark-themed SOC-style interface.

## Architecture

- **Backend**: Python/Flask with Azure SDK
- **Data Sources**: Microsoft Defender for Cloud, Log Analytics (KQL), Azure Activity Log
- **Deployment**: Containerized on Azure Kubernetes Service (AKS)
- **IaC**: Terraform + Bicep (dual implementation)
- **CI/CD**: GitHub Actions + Azure DevOps (dual pipeline)
- **Auth**: OIDC Workload Identity Federation (no stored secrets)

## Security Features Displayed

- **Secure Score**: Real-time compliance percentage from Defender for Cloud
- **Security Alerts**: Active alerts with severity, status, and MITRE ATT&CK tactics
- **Activity Log**: Azure subscription activity via KQL queries against Log Analytics
- **Recommendations**: Defender for Cloud security recommendations with severity
- **Resource Inventory**: Monitored resource count by type

## Local Development

```bash
# Clone and setup
git clone https://github.com/yourusername/azure-security-dashboard.git
cd azure-security-dashboard

# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your Azure Subscription ID and Log Analytics Workspace ID

# Login to Azure (required for DefaultAzureCredential)
az login

# Run locally
python -m app.main
```

Open `http://localhost:8080` in your browser.

## Container Build

```bash
docker build -t azure-security-dashboard .
docker run -p 8080:8080 \
  -e AZURE_SUBSCRIPTION_ID=your-sub-id \
  -e LOG_ANALYTICS_WORKSPACE_ID=your-workspace-id \
  azure-security-dashboard
```

## Project Status

- [x] Phase 1: Console setup + Dashboard application
- [ ] Phase 2: Terraform IaC
- [ ] Phase 3: GitHub Actions CI/CD with OIDC
- [ ] Phase 4: Bicep port
- [ ] Phase 5: Azure DevOps Pipeline
