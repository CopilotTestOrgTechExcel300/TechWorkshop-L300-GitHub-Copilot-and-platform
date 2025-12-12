targetScope = 'resourceGroup'

@description('The name of the Azure Container Registry')
param acrName string

@description('Principal ID to grant access (App Service managed identity)')
param principalId string

@description('Principal type (ServicePrincipal, User, or Group)')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
])
param principalType string = 'ServicePrincipal'

// Reference to existing ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

// AcrPull role definition (built-in role)
// 7f951dda-4ed3-4680-a7ca-43fe172d538d is the role definition ID for AcrPull
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Role assignment to grant App Service managed identity permission to pull images from ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, principalId, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}

output roleAssignmentId string = acrPullRoleAssignment.id
