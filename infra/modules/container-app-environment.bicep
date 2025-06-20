param location string
param abbrs object
param resourceToken string
param logAnalyticsWorkspaceResourceId string
param storages array
param publicNetworkAccess string
param infrastructureSubnetId string
param appInsightsConnectionString string
param workloadProfileName string = 'Consumption'
param privateEndpointSubnetResourceId string

var containerAppsName = '${abbrs.appManagedEnvironments}${resourceToken}'

// Container apps environment
module containerAppsEnvironment 'br/public:avm/res/app/managed-environment:0.10.0' = {
  name: 'container-apps-environment'
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    name: containerAppsName
    location: location
    zoneRedundant: false
    storages: storages
    publicNetworkAccess: publicNetworkAccess
    infrastructureSubnetId: infrastructureSubnetId
    internal: publicNetworkAccess == 'Enabled' ? false : true
    workloadProfiles: [
      {
        name: workloadProfileName
        workloadProfileType: workloadProfileName
      }
    ]
    appInsightsConnectionString: appInsightsConnectionString
    openTelemetryConfiguration: {
      tracesConfiguration: {
        destinations: ['appInsights']
      }
      logsConfiguration: {
        destinations: ['appInsights']
      }
    }
  }
}

resource containerAppsEnvironmentPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${abbrs.networkPrivateLinkServices}cae-${resourceToken}'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${abbrs.networkPrivateLinkServices}cae-${resourceToken}'
        properties: {
          privateLinkServiceId: containerAppsEnvironment.outputs.resourceId
          groupIds: ['managedEnvironments']
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnetResourceId
    }
    customDnsConfigs: [
      {
        fqdn: '*.${containerAppsEnvironment.outputs.defaultDomain}'
        ipAddresses: [
          containerAppsEnvironment.outputs.staticIp
        ]
      }
    ]
  }
}

output AZURE_RESOURCE_CONTAINER_APPS_ENVIRONMENT_ID string = containerAppsEnvironment.outputs.resourceId
output AZURE_RESOURCE_CONTAINER_APPS_WORKLOAD_PROFILE_NAME string = workloadProfileName
output AZURE_RESOURCE_CONTAINER_APPS_ENVIRONMENT_NAME string = containerAppsEnvironment.outputs.name
