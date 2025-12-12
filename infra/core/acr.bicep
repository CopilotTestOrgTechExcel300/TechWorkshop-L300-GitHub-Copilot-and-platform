targetScope = 'resourceGroup'

@description('The name of the Azure Container Registry')
param name string

@description('The location for the ACR')
param location string

@description('Tags to apply to the ACR')
param tags object = {}

@description('The SKU of the ACR')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false // Use RBAC instead of admin credentials
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
    anonymousPullEnabled: false
    dataEndpointEnabled: false
    networkRuleBypassOptions: 'AzureServices'
  }
}

output id string = acr.id
output name string = acr.name
output loginServer string = acr.properties.loginServer
