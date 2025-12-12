# Azure Infrastructure Deployment Guide

## Overview
This guide explains how to deploy the ZavaStorefront application infrastructure to Azure using Azure Developer CLI (azd) and Bicep templates.

## Prerequisites

1. **Install Azure Developer CLI (azd)**
   ```bash
   curl -fsSL https://aka.ms/install-azd.sh | bash
   ```

2. **Install Azure CLI** (if not already installed)
   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

3. **Login to Azure**
   ```bash
   az login
   azd auth login
   ```

## Infrastructure Components

The deployment provisions the following Azure resources in **westus3**:

- **Resource Group**: Single resource group for all dev environment resources
- **Azure Container Registry (ACR)**: For storing Docker images (RBAC-based auth, no passwords)
- **App Service Plan**: Linux-based plan for container hosting
- **App Service (Web App)**: Hosts the containerized application
- **Application Insights**: For application monitoring and telemetry
- **Log Analytics Workspace**: Backend for Application Insights
- **Azure OpenAI (Foundry)**: GPT-4 and Phi model deployments

## Deployment Steps

### 1. Initialize AZD Environment

```bash
# From the repository root
azd init
```

When prompted:
- Environment name: `dev`
- Subscription: Select your Azure subscription
- Location: `westus3`

### 2. Provision Infrastructure

Deploy the Bicep templates:

```bash
azd provision
```

This command will:
- Create the resource group in westus3
- Deploy all Azure resources defined in `infra/main.bicep`
- Configure RBAC for ACR access
- Set up monitoring with Application Insights
- Deploy Foundry resources (GPT-4 and Phi models)

### 3. Build and Deploy Application

Build the Docker image and push to ACR:

```bash
azd deploy
```

This command will:
- Build the Docker image using the Dockerfile
- Push the image to Azure Container Registry
- Update App Service to pull the latest image
- App Service uses its managed identity to authenticate with ACR (no credentials needed)

### 4. Verify Deployment

Check deployment status:

```bash
# Get the web app URL
azd env get-values | grep APP_SERVICE_URL

# View all environment variables
azd env get-values
```

Access the application at the provided URL.

## Manual Deployment (Alternative)

If you prefer to deploy step-by-step:

### 1. Deploy Infrastructure Only

```bash
az deployment sub create \
  --location westus3 \
  --template-file ./infra/main.bicep \
  --parameters environmentName=dev location=westus3
```

### 2. Build and Push Docker Image

```bash
# Get ACR name from deployment outputs
ACR_NAME=$(az deployment sub show -n main --query properties.outputs.AZURE_CONTAINER_REGISTRY_NAME.value -o tsv)

# Build and push image
az acr build --registry $ACR_NAME --image zava-storefront:latest --file ./Dockerfile ./src
```

### 3. Update App Service

The App Service automatically pulls the latest image when tagged as `:latest`.

## Configuration

### Environment Variables

The following environment variables are automatically configured in App Service:

- `APPLICATIONINSIGHTS_CONNECTION_STRING`: For monitoring
- `ASPNETCORE_ENVIRONMENT`: Set to Development
- `DOCKER_REGISTRY_SERVER_URL`: ACR login server URL
- `DOCKER_ENABLE_CI`: Enables continuous deployment

### Update Infrastructure

To update the infrastructure:

1. Modify Bicep files in `infra/` directory
2. Run `azd provision` to apply changes

### Redeploy Application

To deploy a new version:

```bash
azd deploy
```

Or manually:

```bash
az acr build --registry $ACR_NAME --image zava-storefront:latest --file ./Dockerfile ./src
```

## Monitoring and Troubleshooting

### View Application Logs

```bash
# Stream logs from App Service
az webapp log tail --name <webapp-name> --resource-group <rg-name>
```

### Access Application Insights

1. Go to Azure Portal
2. Navigate to Application Insights resource
3. View Live Metrics, Logs, and Performance data

### Check ACR Images

```bash
az acr repository list --name $ACR_NAME
az acr repository show-tags --name $ACR_NAME --repository zava-storefront
```

## RBAC Configuration

The infrastructure uses Azure RBAC for ACR authentication:

- **App Service Managed Identity**: System-assigned managed identity enabled
- **AcrPull Role**: Assigned to App Service identity on ACR
- **No Passwords**: Admin credentials disabled on ACR

This is configured in `infra/core/acr-rbac.bicep`.

## Clean Up Resources

To delete all resources:

```bash
azd down
```

Or manually:

```bash
az group delete --name <resource-group-name> --yes --no-wait
```

## Resource Naming Convention

Resources follow Azure naming best practices:

- Resource Group: `rg-dev-<unique-token>`
- ACR: `acr<unique-token>`
- App Service Plan: `plan-<unique-token>`
- Web App: `app-<unique-token>`
- Application Insights: `appi-<unique-token>`
- Log Analytics: `log-<unique-token>`
- Cognitive Services: `cog-<unique-token>`

The `<unique-token>` is generated from subscription ID, environment name, and location to ensure uniqueness.

## Next Steps

1. **Set up CI/CD**: Configure GitHub Actions for automated deployments
2. **Configure Custom Domain**: Add custom domain to App Service
3. **Enable Auto-scaling**: Configure auto-scaling rules for production
4. **Security**: Enable Azure Firewall, Private Endpoints for production
5. **Backup**: Configure backup and disaster recovery

## Support

For issues or questions:
- Review deployment logs: `azd provision --debug`
- Check Azure Portal for resource status
- Review Application Insights for runtime errors
