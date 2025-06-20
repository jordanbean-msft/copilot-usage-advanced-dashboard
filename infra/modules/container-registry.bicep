param location string
param tags object
param abbrs object
param resourceToken string
param networkRuleSetIpRules array
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
    publicNetworkAccess: 'Enabled' //this is always Enabled because if you want to control the network, a private endpoint will get created and IP rules will be set
    exportPolicyStatus: 'enabled' //this is always Enabled because if you want to control the network, a private endpoint will get created and IP rules will be set
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
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSetDefaultAction: publicNetworkAccess == 'Enabled' ? 'Allow' : 'Deny'
    networkRuleSetIpRules: publicNetworkAccess == 'Enabled' ? null : networkRuleSetIpRules
  }
}

output AZURE_CONTAINER_REGISTRY_LOGIN_SERVER string = containerRegistry.outputs.loginServer
output AZURE_RESOURCE_REGISTRY_ID string = containerRegistry.outputs.resourceId
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
