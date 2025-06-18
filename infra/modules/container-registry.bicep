param location string
param tags object
param abbrs object
param resourceToken string
param principalId string
param doRoleAssignments bool
param publicNetworkAccess string
param logAnalyticsWorkspaceResourceId string
param privateEndpointSubnetResourceId string = ''

// Container registry
module containerRegistry 'br/public:avm/res/container-registry/registry:0.1.1' = {
  name: 'registry'
  params: {
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
    publicNetworkAccess: publicNetworkAccess
    exportPolicyStatus: toLower(publicNetworkAccess)
    acrSku: 'Premium'
    acrAdminUserEnabled: false
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
      }
    ]
    roleAssignments: doRoleAssignments
      ? [
          {
            principalId: principalId
            principalType: 'ServicePrincipal'
            roleDefinitionIdOrName: 'AcrPull'
          }
        ]
      : null
    privateEndpoints: !empty(privateEndpointSubnetResourceId)
      ? [
          {
            subnetResourceId: privateEndpointSubnetResourceId
          }
        ]
      : null
  }
}

output AZURE_CONTAINER_REGISTRY_LOGIN_SERVER string = containerRegistry.outputs.loginServer
output AZURE_RESOURCE_REGISTRY_ID string = containerRegistry.outputs.resourceId
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
