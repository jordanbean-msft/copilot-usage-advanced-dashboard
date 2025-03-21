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
param workloadProfileName string

var appSettingsArray = filter(array(definition.settings), i => i.name != '')
var secrets = map(filter(appSettingsArray, i => i.?secret != null), i => {
  name: i.name
  value: i.value
  secretRef: i.?secretRef ?? take(replace(replace(toLower(i.name), '_', '-'), '.', '-'), 32)
  path: i.?path
})
var srcEnv = map(filter(appSettingsArray, i => i.?secret == null), i => {
  name: i.name
  value: i.value
})
var additionalVolumeMounts = union(length(secrets) > 0 ? [
  {
    volumeName: 'secrets'
    mountPath: '/run/secrets'
  }
] : [], volumeMounts)

var secretVolumePaths = map(filter(secrets, i => i.secretRef != null && i.path != null), i => {
  secretRef: i.secretRef
  path: i.path
})

var additionalVolumes = union(length(secrets) > 0 ? [
  {
    name: 'secrets'
    storageType: 'Secret'
    secrets: length(secretVolumePaths) > 0 ? secretVolumePaths : null
  }]: [], volumes)

module containerApp 'br/public:avm/res/app/container-app:0.8.0' = {
  name: name
  params: {
    name: name
    workloadProfileName: workloadProfileName
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
        volumeMounts: additionalVolumeMounts
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
    volumes: additionalVolumes
  }
}

output AZURE_RESOURCE_CONTAINER_APP_ID string = containerApp.outputs.resourceId
