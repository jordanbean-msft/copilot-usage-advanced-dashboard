param location string
param abbrs object
param resourceToken string
param logAnalyticsWorkspaceResourceId string

// Container apps environment
module containerAppsEnvironment 'br/public:avm/res/app/managed-environment:0.4.5' = {
  name: 'container-apps-environment'
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    name: '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    zoneRedundant: false
  }
}

output AZURE_RESOURCE_CONTAINER_APPS_ENVIRONMENT_ID string = containerAppsEnvironment.outputs.resourceId
