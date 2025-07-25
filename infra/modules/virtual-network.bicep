param location string
param abbrs object
param resourceToken string
param virtualNetwork object
param resourceGroupName string

module containerAppsNetworkSecurityGroupDeployment 'br/public:avm/res/network/network-security-group:0.5.1' = if (bool(virtualNetwork.shouldProvisionPrivateEndpoints)) {
  name: 'container-apps-network-security-group'
  params: {
    name: (empty(virtualNetwork.containerAppsSubnetNetworkSecurityGroupName))
      ? '${abbrs.networkNetworkSecurityGroups}${resourceToken}-container-apps'
      : virtualNetwork.containerAppsSubnetNetworkSecurityGroupName
    location: location
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'AzureLoadBalancerInbound'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 4094
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          destinationPortRange: '30000-32767'
        }
      }
      {
        name: 'AllowContainerAppsEnvoySidecarInbound'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 4095
          protocol: 'Tcp'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          destinationPortRange: '*'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          access: 'Deny'
          direction: 'Inbound'
          priority: 4096
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'AllowHttpsOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'AllowMicrosoftContainerRegistryOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 110
          protocol: 'Tcp'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: 'MicrosoftContainerRegistry'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowAzureFrontDoorFirstPartyOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 120
          protocol: 'Tcp'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureFrontDoor.FirstParty'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowInternalAKSSecureConnectionUdpOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 130
          protocol: 'Udp'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureCloud.${location}'
          destinationPortRange: '1194'
        }
      }
      {
        name: 'AllowInternalAKSSecureConnectionTcpOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 140
          protocol: 'Tcp'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureCloud.${location}'
          destinationPortRange: '9000'
        }
      }
      {
        name: 'AllowFQDNAzureCloudOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 150
          protocol: 'Tcp'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowNtpOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 160
          protocol: 'Udp'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '123'
        }
      }
      {
        name: 'AllowContainerAppsInternalOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 170
          protocol: '*'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          destinationPortRange: '*'
        }
      }
      {
        name: 'AllowContainerRegistryStorageOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 180
          protocol: 'Tcp'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage.${location}'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowAzureMonitorOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 190
          protocol: 'Tcp'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureMonitor'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowNFSOutbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 200
          protocol: '*'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: virtualNetwork.privateEndpointSubnetAddressPrefix
          destinationPortRanges: [
            '445'
            '2049'
          ]
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          access: 'Deny'
          direction: 'Outbound'
          priority: 4096
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

module privateEndpointsNetworkSecurityGroupDeployment 'br/public:avm/res/network/network-security-group:0.5.1' = if (bool(virtualNetwork.shouldProvisionPrivateEndpoints)) {
  name: 'private-endpoints-network-security-group'
  params: {
    name: (empty(virtualNetwork.privateEndpointSubnetNetworkSecurityGroupName))
      ? '${abbrs.networkNetworkSecurityGroups}${resourceToken}-private-endpoints'
      : virtualNetwork.privateEndpointSubnetNetworkSecurityGroupName
    location: location
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'AllowNFSInbound'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 110
          protocol: '*'
          sourceAddressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: virtualNetwork.privateEndpointSubnetAddressPrefix
          destinationPortRanges: [
            '445'
            '2049'
          ]
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          access: 'Deny'
          direction: 'Inbound'
          priority: 4096
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          access: 'Deny'
          direction: 'Outbound'
          priority: 4096
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// need to get any existing DNS server(s) from the virtual network to prevent overwriting them
resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = if (virtualNetwork.vnetName != 'default') {
  name: virtualNetwork.vnetName
  scope: resourceGroup(virtualNetwork.vnetResourceGroupName)
}

var subnets = [
  {
    name: virtualNetwork.containerAppsSubnetName
    addressPrefix: virtualNetwork.containerAppsSubnetAddressPrefix
    delegation: 'Microsoft.App/environments'
    serviceEndpoints: [
      'Microsoft.Storage'
    ]
    networkSecurityGroupResourceId: bool(virtualNetwork.shouldProvisionPrivateEndpoints)
      ? containerAppsNetworkSecurityGroupDeployment.?outputs.resourceId
      : ''
  }
  {
    name: virtualNetwork.privateEndpointSubnetName
    addressPrefix: virtualNetwork.privateEndpointSubnetAddressPrefix
    networkSecurityGroupResourceId: privateEndpointsNetworkSecurityGroupDeployment.?outputs.resourceId
  }
]

module virtualNetworkDeployment 'br/public:avm/res/network/virtual-network:0.6.1' = {
  name: 'virtual-network-deployment'
  scope: resourceGroup(resourceGroupName)
  params: {
    addressPrefixes: [virtualNetwork.vnetAddressPrefixes]
    name: virtualNetwork.vnetName == 'default'
      ? '${abbrs.networkVirtualNetworks}${resourceToken}'
      : virtualNetwork.vnetName
    location: location
    subnets: subnets
    dnsServers: existingVirtualNetwork.?properties.dhcpOptions.dnsServers
  }
}

output AZURE_VIRTUAL_NETWORK_ID string = virtualNetworkDeployment.outputs.resourceId
output AZURE_VIRTUAL_NETWORK_NAME string = virtualNetworkDeployment.outputs.name
output AZURE_VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_ID string = virtualNetworkDeployment.outputs.subnetResourceIds[0]
output AZURE_VIRTUAL_NETWORK_PRIVATE_ENDPOINT_SUBNET_ID string = virtualNetworkDeployment.outputs.subnetResourceIds[1]
