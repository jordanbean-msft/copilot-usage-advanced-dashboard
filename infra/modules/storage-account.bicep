param location string
param tags object
param abbrs object
param resourceToken string
param userAssignedIdentityPrincipalId string
param elasticSearchFileShareName string
param grafanaFileShareName string
param keyVaultResourceId string

var accessKey1Name = 'storageAccountKey1'

module storageAccount 'br/public:avm/res/storage/storage-account:0.18.2' = {
  name: 'storageAccount'
  params: {
    name: '${abbrs.storageAccounts}${resourceToken}'
    kind: 'BlobStorage'
    location: location
    skuName: 'Standard_LRS'
    tags: tags
    secretsExportConfiguration: {
      keyVaultResourceId: keyVaultResourceId
      accessKey1Name: accessKey1Name
    }
    roleAssignments:[
      {
        principalId: userAssignedIdentityPrincipalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage File Data SMB Share Contributor'
      }
    ]
    fileServices: {
      shares: [
        {
          name: elasticSearchFileShareName
          quota: 1024
        }
        {
          name: grafanaFileShareName
          quota: 1024
        }
      ]
    }
    largeFileSharesState: 'Enabled'
  }
}

output AZURE_STORAGE_ACCOUNT_ID string = storageAccount.outputs.resourceId
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.outputs.name
output AZURE_STORAGE_ELASTIC_SEARCH_FILE_SHARE_NAME string = elasticSearchFileShareName
output AZURE_STORAGE_GRAFANA_FILE_SHARE_NAME string = grafanaFileShareName
output AZURE_STORAGE_ACCOUNT_KEY_SECRET_NAME string = accessKey1Name
