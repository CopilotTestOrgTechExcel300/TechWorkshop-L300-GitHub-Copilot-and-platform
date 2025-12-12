# GitHub Actions Deployment Setup

## Prerequisites

- Azure infrastructure already provisioned (run `azd provision` first)
- GitHub repository with admin access

## Configure GitHub Secrets and Variables

### 1. Create Azure Service Principal

Run this command in your terminal:

```bash
az ad sp create-for-rbac \
  --name "github-actions-zava-storefront" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP_NAME> \
  --json-auth
```

Copy the entire JSON output.

### 2. Add GitHub Secret

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Create the following secret:

| Name | Value |
|------|-------|
| `AZURE_CREDENTIALS` | Paste the entire JSON from step 1 |

### 3. Add GitHub Variables

Click the **Variables** tab and add these variables:

| Name | Value | How to Get |
|------|-------|------------|
| `AZURE_CONTAINER_REGISTRY_NAME` | `acrtermoz66pcrqm` | Run: `azd env get-values \| grep AZURE_CONTAINER_REGISTRY_NAME` |
| `APP_SERVICE_NAME` | `app-termoz66pcrqm` | Run: `azd env get-values \| grep APP_SERVICE_NAME` |
| `AZURE_RESOURCE_GROUP_NAME` | `rg-trainingenv-termoz66pcrqm` | Run: `azd env get-values \| grep AZURE_RESOURCE_GROUP_NAME` |

### 4. Grant Service Principal ACR Push Permission

```bash
# Get the service principal ID
SP_ID=$(az ad sp list --display-name "github-actions-zava-storefront" --query "[0].id" -o tsv)

# Grant AcrPush role
az role assignment create \
  --assignee $SP_ID \
  --role AcrPush \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP_NAME>/providers/Microsoft.ContainerRegistry/registries/<ACR_NAME>
```

## Test the Workflow

Push a commit to the `main` branch or manually trigger the workflow from **Actions** → **Build and Deploy to Azure** → **Run workflow**.

## Workflow Overview

The workflow automatically:
1. Checks out the code
2. Logs into Azure using the service principal
3. Builds the Docker image and pushes to ACR with both commit SHA and `latest` tags
4. Updates App Service to use the new image
5. Restarts App Service

Build time: ~1-2 minutes
