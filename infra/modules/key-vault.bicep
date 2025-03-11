param location string
param abbrs object
param resourceToken string
param tags object
param userAssignedManagedIdentityPrincipalId string

module vault 'br/public:avm/res/key-vault/vault:0.12.1' = {
  name: 'vault'
  params: {
    name: '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    roleAssignments: [
      {
        principalId: userAssignedManagedIdentityPrincipalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Key Vault Secrets Officer'
      }
    ]
    enablePurgeProtection: false
    tags: tags
  }
}

output AZURE_RESOURCE_KEY_VAULT_ID string = vault.outputs.resourceId
