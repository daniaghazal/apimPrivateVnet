param vnetName string
param vnetAddressSpace string
param appgwSubnet string
param apimSubnet string
param jumpboxSubnet string
param publisherName string
param publisherEmail string
param hostname string
param vaultName string

param adminUsername string {
  secure: true
}
param adminPassword string {
  secure: true
}

module network './modules/vnet/networking.bicep' = {
    name: 'network'
    params: {
        vnetName: vnetName
        vnetAddressSpace: vnetAddressSpace
        appgwSubnet: appgwSubnet
        apimSubnet: apimSubnet
        jumpboxSubnet: jumpboxSubnet
    }
}

module apim './modules/apim/apim.bicep' = {
    name: 'apim'
    dependsOn: [
        network
    ]
    params: {
        publisherName: publisherName
        publisherEmail: publisherEmail
        subnetResourceId: network.outputs.subnetApim
    }
}

module vault './modules/vault/keyvault.bicep' = {
    name: 'vault'
    dependsOn: [
        apim
    ]
    params: {
        principalIdApim: apim.outputs.apimIdentity
        vaultName: vaultName
    }
}

module dns './modules/dns/dns.bicep' = {
    name: 'dns'
    dependsOn: [
        apim
        network
    ]
    params: {
        dnsZoneName: hostname
        apimIpAddress: apim.outputs.apimPrivateIp
        vnetId: network.outputs.vnetId
        vnetName: vnetName
    }
}

module jumpbox './modules/compute/jumpbox.bicep' = {
    name: 'jumpbox'
    dependsOn: [
        network
    ]
    params: {
        adminUsername: adminUsername
        adminPassword: adminPassword
        subnetId: network.outputs.subnetJumpbox
    }
}

output gwSubnetId string = network.outputs.subnetAppGw
output identityId string = vault.outputs.userIdentityId