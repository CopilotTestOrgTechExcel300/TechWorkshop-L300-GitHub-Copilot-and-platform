targetScope = 'resourceGroup'

@description('The name of the Azure AI Foundry account')
param accountName string

@description('The location for the Foundry resources')
param location string

@description('Tags to apply to the resources')
param tags object = {}

@description('SKU for the Cognitive Services account')
param sku string = 'S0'

// Azure OpenAI / Cognitive Services Account for Foundry
resource foundryAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: accountName
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// GPT-4o Deployment (current stable version)
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: foundryAccount
  name: 'gpt-4o'
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
    raiPolicyName: 'Microsoft.Default'
  }
}

// GPT-4o-mini Deployment (using as placeholder for Phi model)
// Note: Replace with actual Phi model when available in westus3
resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: foundryAccount
  name: 'gpt-4o-mini'
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [
    gpt4Deployment
  ]
}

output id string = foundryAccount.id
output name string = foundryAccount.name
output endpoint string = foundryAccount.properties.endpoint
output gpt4DeploymentName string = gpt4Deployment.name
output phiDeploymentName string = phiDeployment.name
