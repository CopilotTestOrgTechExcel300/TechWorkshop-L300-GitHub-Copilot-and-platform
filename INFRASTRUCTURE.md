# Azure Infrastructure Plan for ZavaStorefront

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Subscription                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Resource Group: rg-dev-{unique-token} (westus3)          │  │
│  │                                                             │  │
│  │  ┌─────────────────────┐    ┌──────────────────────────┐  │  │
│  │  │ Azure Container     │    │ App Service Plan         │  │  │
│  │  │ Registry (ACR)      │◄───│ - Linux, Basic B1       │  │  │
│  │  │ - No admin user     │    │ - Container support     │  │  │
│  │  │ - RBAC auth only    │    └──────────┬───────────────┘  │  │
│  │  └─────────────────────┘               │                  │  │
│  │           ▲                             ▼                  │  │
│  │           │                  ┌──────────────────────────┐  │  │
│  │           │                  │ Web App (Linux)          │  │  │
│  │           │                  │ - Managed Identity       │  │  │
│  │           └──────────────────│ - AcrPull RBAC role     │  │  │
│  │          (Pull images)       │ - Docker container      │  │  │
│  │                              └──────────┬───────────────┘  │  │
│  │                                         │                  │  │
│  │                                         │ (Telemetry)      │  │
│  │                                         ▼                  │  │
│  │                              ┌──────────────────────────┐  │  │
│  │  ┌─────────────────────┐    │ Application Insights     │  │  │
│  │  │ Log Analytics       │◄───│ - Web monitoring        │  │  │
│  │  │ Workspace           │    │ - Performance metrics   │  │  │
│  │  └─────────────────────┘    └──────────────────────────┘  │  │
│  │                                                             │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │ Azure OpenAI (Foundry)                                │  │  │
│  │  │ - GPT-4 deployment                                    │  │  │
│  │  │ - Phi model deployment                                │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Resources to be Provisioned

### 1. Resource Group
- **Name**: `rg-dev-{unique-token}`
- **Location**: westus3
- **Purpose**: Container for all dev environment resources
- **Tags**: 
  - environment: dev
  - application: zava-storefront
  - managed-by: azd

### 2. Azure Container Registry (ACR)
- **Name**: `acr{unique-token}`
- **SKU**: Basic
- **Location**: westus3
- **Features**:
  - Admin user: Disabled
  - Authentication: RBAC only
  - Public network access: Enabled
  - Anonymous pull: Disabled
- **Purpose**: Store Docker container images for the application

### 3. App Service Plan
- **Name**: `plan-{unique-token}`
- **SKU**: B1 (Basic)
- **OS**: Linux
- **Location**: westus3
- **Purpose**: Hosting platform for the containerized web application

### 4. App Service (Web App)
- **Name**: `app-{unique-token}`
- **Runtime**: Linux Container
- **Location**: westus3
- **Features**:
  - System-assigned managed identity
  - HTTPS only
  - Container image from ACR
  - Managed identity authentication to ACR
  - Application Insights integration
- **Configuration**:
  - linuxFxVersion: DOCKER|{acr}.azurecr.io/zava-storefront:latest
  - acrUseManagedIdentityCreds: true

### 5. Log Analytics Workspace
- **Name**: `log-{unique-token}`
- **SKU**: PerGB2018
- **Location**: westus3
- **Retention**: 30 days
- **Daily quota**: 1 GB
- **Purpose**: Backend for Application Insights logs

### 6. Application Insights
- **Name**: `appi-{unique-token}`
- **Type**: Web
- **Location**: westus3
- **Mode**: LogAnalytics (workspace-based)
- **Purpose**: Monitor application performance, availability, and usage

### 7. Azure OpenAI (Foundry)
- **Name**: `cog-{unique-token}`
- **Kind**: OpenAI
- **SKU**: S0
- **Location**: westus3
- **Deployments**:
  - **GPT-4**: Model version 0613, capacity 10
  - **Phi-3**: Placeholder (gpt-35-turbo until Phi available)
- **Purpose**: AI model access for application features

### 8. RBAC Role Assignment
- **Role**: AcrPull
- **Scope**: ACR resource
- **Principal**: App Service managed identity
- **Purpose**: Allow App Service to pull images from ACR without credentials

## Infrastructure as Code Structure

```
infra/
├── main.bicep                 # Main orchestration template
├── main.parameters.json       # Default parameters
├── abbreviations.json         # Azure naming abbreviations
└── core/
    ├── acr.bicep             # Azure Container Registry
    ├── acr-rbac.bicep        # ACR RBAC configuration
    ├── appservice.bicep      # App Service Plan + Web App
    ├── monitoring.bicep      # Log Analytics + App Insights
    └── foundry.bicep         # Azure OpenAI resources
```

## Deployment Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| environmentName | dev | Environment identifier |
| location | westus3 | Azure region |
| principalId | (runtime) | User/SP running deployment |

## Security Configuration

1. **No Passwords**: ACR admin user disabled
2. **Managed Identity**: App Service uses system-assigned identity
3. **RBAC**: Least-privilege access using AcrPull role
4. **HTTPS**: App Service enforces HTTPS
5. **TLS**: Minimum TLS 1.2 enforced
6. **FTPS**: Disabled on App Service

## Monitoring & Observability

- **Application Insights**: Real-time monitoring, distributed tracing
- **Log Analytics**: Centralized log storage and querying
- **Metrics**: CPU, memory, request/response metrics
- **Alerts**: (To be configured post-deployment)

## Cost Estimation (Monthly)

| Resource | SKU | Estimated Cost |
|----------|-----|----------------|
| App Service Plan | B1 | ~$13 |
| ACR | Basic | ~$5 |
| Application Insights | Pay-as-you-go | ~$5-10 |
| Log Analytics | 1GB/day | ~$2-5 |
| Azure OpenAI | S0 (pay per token) | Variable |
| **Total** | | **~$25-35/month** (excluding OpenAI usage) |

## Deployment Process

1. **Initialize**: `azd init` - Set up environment
2. **Provision**: `azd provision` - Deploy Bicep templates
3. **Build**: Docker image built from source
4. **Push**: Image pushed to ACR
5. **Deploy**: App Service pulls and runs container
6. **Verify**: Health checks and monitoring

## Post-Deployment Outputs

The deployment provides these outputs:

- `AZURE_LOCATION`: westus3
- `AZURE_RESOURCE_GROUP_NAME`: Resource group name
- `AZURE_CONTAINER_REGISTRY_ENDPOINT`: ACR login server
- `AZURE_CONTAINER_REGISTRY_NAME`: ACR name
- `APP_SERVICE_NAME`: Web app name
- `APP_SERVICE_URL`: Application URL
- `APPLICATION_INSIGHTS_CONNECTION_STRING`: Monitoring connection
- `FOUNDRY_ENDPOINT`: Azure OpenAI endpoint

## Success Criteria

✅ All resources deployed to westus3  
✅ Single resource group contains all resources  
✅ App Service pulls images using managed identity  
✅ No ACR admin credentials used  
✅ Application Insights connected and receiving data  
✅ Foundry GPT-4 and Phi models deployed  
✅ Application accessible via HTTPS  
✅ Infrastructure defined entirely in Bicep  
✅ Deployed using AZD CLI  

## Next Steps After Deployment

1. Verify all resources in Azure Portal
2. Test application URL
3. Check Application Insights for telemetry
4. Configure CI/CD pipeline (GitHub Actions)
5. Set up alerts and monitoring rules
6. Test Foundry model endpoints
