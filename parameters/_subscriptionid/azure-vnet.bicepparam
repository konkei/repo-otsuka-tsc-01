using '../../infra/azure-vnet.bicep'

param vnetName = 'vnet-16427-tayo'
param vnetAddressPrefix = '10.10.0.0/16'
param subnetName = 'snet-16427-hama'
param subnetAddressPrefix = '10.10.1.0/24'