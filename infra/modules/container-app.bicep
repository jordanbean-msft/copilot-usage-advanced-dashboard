param location string
param tags object
param name string
param definition object
param fetchLatestImage object
param applicationInsightsConnectionString string
param userAssignedManagedIdentityClientId string
param userAssignedManagedIdentityResourceId string
param ingressTargetPort int
param containerRegistryLoginServer string
param containerAppsEnvironmentResourceId string
param ingressExternal bool = false
param cpu string
param memory string
param volumeMounts array = []
param volumes array = []

var appSettingsArray = filter(array(definition.settings), i => i.name != '')
var secrets = map(filter(appSettingsArray, i => i.?secret != null), i => {
  name: i.name
  value: i.value
  secretRef: i.?secretRef ?? take(replace(replace(toLower(i.name), '_', '-'), '.', '-'), 32)
})
var srcEnv = map(filter(appSettingsArray, i => i.?secret == null), i => {
  name: i.name
  value: i.value
})

module containerApp 'br/public:avm/res/app/container-app:0.8.0' = {
  name: name
  params: {
    name: name
    ingressTargetPort: ingressTargetPort
    scaleMinReplicas: 1
    scaleMaxReplicas: 10
    secrets: {
      secureList:  union([
      ],
      map(secrets, secret => {
        name: secret.secretRef
        value: secret.value
      }))
    }
    containers: [
      {
        image: fetchLatestImage.outputs.?containers[?0].?image ?? 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        name: 'main'
        resources: {
          cpu: json(cpu)
          memory: memory
        }
        volumeMounts: volumeMounts
        env: union([
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: applicationInsightsConnectionString
          }
          {
            name: 'AZURE_CLIENT_ID'
            value: userAssignedManagedIdentityClientId
          }
        ],
        srcEnv,
        map(secrets, secret => {
            name: secret.name
            secretRef: secret.secretRef
        }))
      }
    ]
    managedIdentities:{
      systemAssigned: false
      userAssignedResourceIds: [userAssignedManagedIdentityResourceId]
    }
    registries:[
      {
        server: containerRegistryLoginServer
        identity: userAssignedManagedIdentityResourceId
      }
    ]
    environmentResourceId: containerAppsEnvironmentResourceId
    location: location
    tags: union(tags, { 'azd-service-name': name })
    ingressExternal: ingressExternal
    volumes: volumes
  }
}

output AZURE_RESOURCE_CONTAINER_APP_ID string = containerApp.outputs.resourceId
