targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g., dev, staging, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Principal ID for the user or service principal deploying resources')
param principalId string = ''

// Tags for all resources
var tags = {
  'azd-env-name': environmentName
  environment: environmentName
  application: 'zava-storefront'
  'managed-by': 'azd'
}

// Consistent naming convention
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

// Azure Container Registry
module acr './core/acr.bicep' = {
  name: 'acr-deployment'
  scope: rg
  params: {
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
  }
}

// Application Insights & Log Analytics
module monitoring './core/monitoring.bicep' = {
  name: 'monitoring-deployment'
  scope: rg
  params: {
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    location: location
    tags: tags
  }
}

// App Service Plan & Web App
module appService './core/appservice.bicep' = {
  name: 'appservice-deployment'
  scope: rg
  params: {
    appServicePlanName: '${abbrs.webServerFarms}${resourceToken}'
    webAppName: '${abbrs.webSitesAppService}${resourceToken}'
    location: location
    tags: tags
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    acrLoginServer: acr.outputs.loginServer
    acrName: acr.outputs.name
  }
}

// Microsoft Foundry Resources (GPT-4 and Phi models) - Deployed in West US 3
module foundry './core/foundry.bicep' = {
  name: 'foundry-deployment'
  scope: rg
  params: {
    accountName: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: 'westus3'
    tags: tags
  }
}

// RBAC: Grant App Service managed identity AcrPull role on ACR
module acrRoleAssignment './core/acr-rbac.bicep' = {
  name: 'acr-rbac-deployment'
  scope: rg
  params: {
    acrName: acr.outputs.name
    principalId: appService.outputs.webAppIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs for AZD
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP_NAME string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.name
output APP_SERVICE_NAME string = appService.outputs.webAppName
output APP_SERVICE_URL string = appService.outputs.webAppUrl
output APPLICATION_INSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output FOUNDRY_ENDPOINT string = foundry.outputs.endpoint
