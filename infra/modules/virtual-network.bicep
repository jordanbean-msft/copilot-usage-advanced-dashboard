param location string
param abbrs object
param resourceToken string
param virtualNetwork object

module containerAppsNetworkSecurityGroupDeployment 'br/public:avm/res/network/network-security-group:0.5.1' = {
  name: 'container-apps-network-security-group'
  params: {
    name: (empty(virtualNetwork.containerAppsSubnetNetworkSecurityGroupName))
      ? '${abbrs.networkNetworkSecurityGroups}${resourceToken}-container-apps'
      : virtualNetwork.containerAppsSubnetNetworkSecurityGroupName
    location: location
    securityRules: [
      {
        name: 'AllowNFSOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 199
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage'
          destinationPortRanges: [
            '445'
            '2049'
          ]
        }
      }
    ]
  }
}

// need to get any existing DNS server(s) from the virtual network to prevent overwriting them
resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = if (!empty(virtualNetwork.vnetName)) {
  name: virtualNetwork.vnetName
}

module virtualNetworkDeployment 'br/public:avm/res/network/virtual-network:0.6.1' = {
  name: 'virtual-network-deployment'
  params: {
    addressPrefixes: [virtualNetwork.vnetAddressPrefixes]
    name: (empty(virtualNetwork.vnetName)) ? '${abbrs.networkVirtualNetworks}${resourceToken}' : virtualNetwork.vnetName
    location: location
    subnets: [
      {
        name: virtualNetwork.containerAppsSubnetName
        addressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
        delegation: 'Microsoft.App/environments'
        serviceEndpoints: [
          'Microsoft.Storage'
        ]
        networkSecurityGroupResourceId: containerAppsNetworkSecurityGroupDeployment.outputs.resourceId
      }
      {
        name: virtualNetwork.privateEndpointSubnetName
        addressPrefix: virtualNetwork.privateEndpointSubnetAddressPrefix
      }
    ]
    dnsServers: existingVirtualNetwork.properties.dhcpOptions.dnsServers
  }
}

output AZURE_VIRTUAL_NETWORK_ID string = virtualNetworkDeployment.outputs.resourceId
output AZURE_VIRTUAL_NETWORK_NAME string = virtualNetworkDeployment.outputs.name
output AZURE_VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_ID string = virtualNetworkDeployment.outputs.subnetResourceIds[0]
output AZURE_VIRTUAL_NETWORK_PRIVATE_ENDPOINT_SUBNET_ID string = virtualNetworkDeployment.outputs.subnetResourceIds[1]
