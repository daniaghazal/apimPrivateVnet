param vnetName string
param vnetAddressSpace string
param appgwSubnet string
param apimSubnet string
param jumpboxSubnet string
param webServerSubnet string
param gwSubnet string
param vaultName string
param apiHostname string
param secretName string

param onpremVnetAddressSpace string
param onpremGatewayAddressSpace string
param onpremWebAddressSpace string

param publisherName string
param publisherEmail string
param adminUsernameSql string {
    secure: true
}
param adminPasswordSql string {
    secure: true
}

param hostname string

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
        webServerSubnet: webServerSubnet
        gwSubnet: gwSubnet
    }
}

module vpn './modules/gateway/vpn.bicep' = {
    name: 'vpn'
    params: {
        location: resourceGroup().location
        name: concat('vpn-cloud-',uniqueString(resourceGroup().id))
        subnetId: network.outputs.subnetGw
        publicIpName: 'pip-gw-cloud'
    }
}

module web './modules/webapp/webapp.bicep' = {
    name: 'web'
    dependsOn: [
        network
    ]    
}

module sql './modules/sql/sql.bicep' = {
    name: 'sql'
    params: {
        adminUsername: adminUsernameSql
        adminPassword: adminPasswordSql
        subnetId: network.outputs.webServerSubnetId
        vnetName: network.outputs.vnetname
    }
}

module identity './modules/identity/identity.bicep' = {
    name: 'identity'
}

module vault './modules/vault/vault.bicep' = {
    name: 'vault'
    dependsOn: [
        identity
    ]
    params: {
        vaultName: vaultName
        apimIdentity: identity.outputs.apimManagedIdenity
    }
}

// module apim './modules/apim/apim.bicep' = {
//     name: 'apim'
//     dependsOn: [
//         network
//         vault
//     ]
//     params: {
//         publisherName: publisherName
//         publisherEmail: publisherEmail
//         subnetResourceId: network.outputs.subnetApim
//         apiHostname: apiHostname
//         keyVaultName: vaultName
//         secretName: secretName
//         managedIdentityId: identity.outputs.apimManagedIdenity
//     }
// }



// module dns './modules/dns/dns.bicep' = {
//     name: 'dns'
//     dependsOn: [
//         apim
//         network
//     ]
//     params: {
//         dnsZoneName: hostname
//         apimIpAddress: apim.outputs.apimPrivateIp
//         vnetId: network.outputs.vnetId
//         vnetName: vnetName
//     }
// }

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
output apimSubnetCIDR string =  apimSubnet
