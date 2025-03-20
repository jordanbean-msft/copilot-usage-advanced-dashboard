@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Tags that will be applied to all resources')
param tags object = {}

param cpuAdUpdaterExists bool
@secure()
param cpuAdUpdaterDefinition object

param elasticSearchExists bool
@secure()
param elasticSearchDefinition object

param grafanaExists bool
@secure()
param grafanaDefinition object

@description('Id of the user or app to assign application roles')
param principalId string

@secure()
param grafanaUsername string

@secure()
param grafanaPassword string

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location)
var elasticSearchFileShareName = 'elastic-search'
var grafanaFileShareName = 'grafana'
var cpuadUpdaterFileShareName = 'cpuad-updater'

var grafanaUsernameSecretName = 'GRAFANA_USERNAME'
var grafanaUsernameSecretValue = grafanaUsername != '' ? grafanaUsername : uniqueString('grafanaUsername', subscription().id, resourceGroup().id, location, resourceToken)
var grafanaPasswordSecretName = 'GRAFANA_PASSWORD'
var grafanaPasswordSecretValue = grafanaPassword != '' ? grafanaPassword : uniqueString('grafanaPassword', subscription().id, resourceGroup().id, location, resourceToken)

module monitoring './modules/monitoring.bicep' = {
  name: 'monitoringDeployment'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    resourceToken: resourceToken
  }
}

module identity './modules/user-assigned-managed-identity.bicep' = {
  name: 'identityDeployment'
  params: {
    location: location
    abbrs: abbrs
    resourceToken: resourceToken
  }
}

module containerRegistry './modules/container-registry.bicep' = {
  name: 'containerRegistryDeployment'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    resourceToken: resourceToken
    principalId: identity.outputs.AZURE_RESOURCE_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID
  }
}

module keyVault './modules/key-vault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    abbrs: abbrs
    resourceToken: resourceToken
    tags: tags
    userAssignedManagedIdentityPrincipalId: identity.outputs.AZURE_RESOURCE_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID
    principalId: principalId
    secrets: [
      {
        name: grafanaUsernameSecretName
        value: grafanaUsernameSecretValue
      }
      {
        name: grafanaPasswordSecretName
        value: grafanaPasswordSecretValue
      }
    ]
  }
}

module storageAccount './modules/storage-account.bicep' = {
  name: 'storageAccountDeployment'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    resourceToken: resourceToken
    elasticSearchFileShareName: elasticSearchFileShareName
    grafanaFileShareName: grafanaFileShareName
    cpuadUpdaterFileShareName: cpuadUpdaterFileShareName
    userAssignedIdentityPrincipalId: identity.outputs.AZURE_RESOURCE_USER_ASSIGNED_IDENTITY_PRINCIPAL_ID
    keyVaultResourceId: keyVault.outputs.AZURE_RESOURCE_KEY_VAULT_ID
  }
}

module containerAppsEnvironment './modules/container-app-environment.bicep' = {
  name: 'containerAppsEnvironmentDeployment'
  params: {
    location: location
    abbrs: abbrs
    workloadProfileType: 'D8'
    resourceToken: resourceToken
    logAnalyticsWorkspaceResourceId: monitoring.outputs.AZURE_RESOURCE_MONITORING_LOG_ANALYTICS_ID
    storages: [
      {
        kind: 'SMB'
        accessMode: 'ReadWrite'
        shareName: storageAccount.outputs.AZURE_STORAGE_ELASTIC_SEARCH_FILE_SHARE_NAME
        storageAccountName: storageAccount.outputs.AZURE_STORAGE_ACCOUNT_NAME
      }
      {
        kind: 'SMB'
        accessMode: 'ReadWrite'
        shareName: storageAccount.outputs.AZURE_STORAGE_GRAFANA_FILE_SHARE_NAME
        storageAccountName: storageAccount.outputs.AZURE_STORAGE_ACCOUNT_NAME
      }
      {
        kind: 'SMB'
        accessMode: 'ReadWrite'
        shareName: storageAccount.outputs.AZURE_STORAGE_CPUAD_UPDATER_FILE_SHARE_NAME
        storageAccountName: storageAccount.outputs.AZURE_STORAGE_ACCOUNT_NAME
      }
    ]
    publicNetworkAccess: 'Enabled'
  }
}

module cpuadUpdaterFetchLatestImage './modules/fetch-container-image.bicep' = {
  name: 'cpuadUpdaterFetchImageDeployment'
  params: {
    exists: cpuAdUpdaterExists
    name: 'cpuadUpdater'
  }
}

module cpuadUpdater './modules/container-job.bicep' = {
  name: 'cpuadUpdaterDeployment'
  params: {
    name: 'cpuad-updater'
    location: location
    workloadProfileName: containerAppsEnvironment.outputs.AZURE_RESOURCE_CONTAINER_APPS_WORKLOAD_PROFILE_NAME
    containerRegistryLoginServer: containerRegistry.outputs.AZURE_CONTAINER_REGISTRY_LOGIN_SERVER
    containerAppsEnvironmentResourceId: containerAppsEnvironment.outputs.AZURE_RESOURCE_CONTAINER_APPS_ENVIRONMENT_ID
    applicationInsightsConnectionString: monitoring.outputs.AZURE_RESOURCE_MONITORING_APP_INSIGHTS_CONNECTION_STRING
    definition: cpuAdUpdaterDefinition
    fetchLatestImage: cpuadUpdaterFetchLatestImage
    userAssignedManagedIdentityResourceId: identity.outputs.AZURE_RESOURCE_USER_ASSIGNED_IDENTITY_ID
    userAssignedManagedIdentityClientId: identity.outputs.AZURE_RESOURCE_USER_ASSIGNED_IDENTITY_CLIENT_ID
    tags: tags
    cpu: '1.0'
    memory: '2.0Gi'
    volumeMounts: [
      {
        mountPath: '/app/logs'
        volumeName: storageAccount.outputs.AZURE_STORAGE_CPUAD_UPDATER_FILE_SHARE_NAME
      }
    ]
    volumes: [
      {
        name: storageAccount.outputs.AZURE_STORAGE_CPUAD_UPDATER_FILE_SHARE_NAME
        storageName: storageAccount.outputs.AZURE_STORAGE_CPUAD_UPDATER_FILE_SHARE_NAME
        storageType: 'AzureFile'
        mountOptions: 'dir_mode=0777,file_mode=0777,uid=1000,gid=1000,mfsymlinks,nobrl,cache=none'
      }
    ]
  }
}

module elasticSearchFetchLatestImage './modules/fetch-container-image.bicep' = {
  name: 'elasticSearchFetchImageDeployment'
  params: {
    exists: elasticSearchExists
    name: 'elastic-search'
  }
}

module elasticSearch './modules/container-app.bicep' = {
  name: 'elasticSearchDeployment'
  params: {
    name: 'elastic-search'
    location: location
    workloadProfileName: containerAppsEnvironment.outputs.AZURE_RESOURCE_CONTAINER_APPS_WORKLOAD_PROFILE_NAME
    containerRegistryLoginServer: containerRegistry.outputs.AZURE_CONTAINER_REGISTRY_LOGIN_SERVER
    containerAppsEnvironmentResourceId: containerAppsEnvironment.outputs.AZURE_RESOURCE_CONTAINER_APPS_ENVIRONMENT_ID
    applicationInsightsConnectionString: monitoring.outputs.AZURE_RESOURCE_MONITORING_APP_INSIGHTS_CONNECTION_STRING
    definition: elasticSearchDefinition
    fetchLatestImage: cpuadUpdaterFetchLatestImage
    ingressTargetPort: 9200
    userAssignedManagedIdentityResourceId: identity.outputs.AZURE_RESOURCE_USER_ASSIGNED_IDENTITY_ID
    userAssignedManagedIdentityClientId: identity.outputs.AZURE_RESOURCE_USER_ASSIGNED_IDENTITY_CLIENT_ID
    tags: tags
    cpu: '4.0'
    memory: '8.0Gi'
    volumeMounts: [
      {
        mountPath: '/usr/share/elasticsearch/data'
        volumeName: storageAccount.outputs.AZURE_STORAGE_ELASTIC_SEARCH_FILE_SHARE_NAME
      }
    ]
    volumes: [
      {
        name: storageAccount.outputs.AZURE_STORAGE_ELASTIC_SEARCH_FILE_SHARE_NAME
        storageName: storageAccount.outputs.AZURE_STORAGE_ELASTIC_SEARCH_FILE_SHARE_NAME
        storageType: 'AzureFile'
        mountOptions: 'dir_mode=0777,file_mode=0777,uid=1000,gid=1000,mfsymlinks,nobrl,cache=none'
      }
    ]
    ingressExternal: false
  }
}

module grafanaFetchLatestImage './modules/fetch-container-image.bicep' = {
  name: 'grafanaFetchImageDeployment'
  params: {
    exists: grafanaExists
    name: 'grafana'
  }
}

module grafana './modules/container-app.bicep' = {
  name: 'grafanaDeployment'
  params: {
    name: 'grafana'
    location: location
    workloadProfileName: containerAppsEnvironment.outputs.AZURE_RESOURCE_CONTAINER_APPS_WORKLOAD_PROFILE_NAME
    containerRegistryLoginServer: containerRegistry.outputs.AZURE_CONTAINER_REGISTRY_LOGIN_SERVER
    containerAppsEnvironmentResourceId: containerAppsEnvironment.outputs.AZURE_RESOURCE_CONTAINER_APPS_ENVIRONMENT_ID
    applicationInsightsConnectionString: monitoring.outputs.AZURE_RESOURCE_MONITORING_APP_INSIGHTS_CONNECTION_STRING
    definition: grafanaDefinition
    fetchLatestImage: cpuadUpdaterFetchLatestImage
    ingressTargetPort: 3000
    userAssignedManagedIdentityResourceId: identity.outputs.AZURE_RESOURCE_USER_ASSIGNED_IDENTITY_ID
    userAssignedManagedIdentityClientId: identity.outputs.AZURE_RESOURCE_USER_ASSIGNED_IDENTITY_CLIENT_ID
    tags: tags
    ingressExternal: true
    cpu: '1.0'
    memory: '2.0Gi'
    volumeMounts: [
      {
        mountPath: '/var/lib/grafana'
        volumeName: storageAccount.outputs.AZURE_STORAGE_GRAFANA_FILE_SHARE_NAME
      }
    ]
    volumes: [
      {
        name: storageAccount.outputs.AZURE_STORAGE_GRAFANA_FILE_SHARE_NAME
        storageName: storageAccount.outputs.AZURE_STORAGE_GRAFANA_FILE_SHARE_NAME
        storageType: 'AzureFile'
        mountOptions: 'dir_mode=0777,file_mode=0777,uid=1000,gid=1000,mfsymlinks,nobrl,cache=none'
      }
    ]
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.AZURE_CONTAINER_REGISTRY_LOGIN_SERVER
output AZURE_RESOURCE_CPUAD_UPDATER_ID string = cpuadUpdater.outputs.AZURE_RESOURCE_CONTAINER_APP_ID
output AZURE_RESOURCE_ELASTIC_SEARCH_ID string = elasticSearch.outputs.AZURE_RESOURCE_CONTAINER_APP_ID
output AZURE_RESOURCE_GRAFANA_ID string = grafana.outputs.AZURE_RESOURCE_CONTAINER_APP_ID
output AZURE_CONTAINER_APPS_ENVIRONMENT_NAME string = containerAppsEnvironment.outputs.AZURE_RESOURCE_CONTAINER_APPS_ENVIRONMENT_NAME
output AZURE_CONTAINER_REGISTRY_LOGIN_SERVER string = containerRegistry.outputs.AZURE_CONTAINER_REGISTRY_LOGIN_SERVER
