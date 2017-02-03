# Must create a subnet called GatewaySubnet for the gateway to connect to prior to creating the gateway
 
$vnetname = "dex-founder-vnet"
$rgname = "0951"
$region = "WestEurope"
$clientpool = "192.168.10.0/24" # Not sure what range is required here???
$RootCertName = "ARMP2SRootCert.cer"

#Export cert as Base64, and put data into single line.
 
$publicCertData = "MIIDAjCCAe6gAwIBAgIQ/CFuffuO5IpB8pKeVFYjUjAJBgUrDgMCHQUAMBkxFzAVBgNVBAMTDkFSTVAyU1Jvb3RDZXJ0MB4XDTE3MDIwMzEzMzkxN1oXDTM5MTIzMTIzNTk1OVowGTEXMBUGA1UEAxMOQVJNUDJTUm9vdENlcnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDQ2hz4/OK9PdcFLOE0GJ01wfde4g53k5ZRjMT71rGCPb5avlPPkpd52fUu2DUNMBvdhPm2y0PfKN7oETKOFUCCZj37IDZZl2Z7LhNJX3AdsQLfs8cQDalrSbOPY0qQcbiCo01BE9iyWHm0SsWMjyDYiND0xf7UJPW6qT9/Mg7iHAw+E+1Xq5okZCUqSV6QNCUWn8o5oRJE263/HPX07cCKltzfMEqC6SWTNeAlpPWLZp0kVxEPX9B06cEKs8+ILcb6G2t6cLYZcvCo1mODUAj7ThRPHi+tY0/XaoFF9/DesBm6Yq69QNV627xY3DpofjjSfHPw4M7q0+9hz2uvJVsPAgMBAAGjTjBMMEoGA1UdAQRDMEGAELH7uKgo37X+U/L0NThjJFOhGzAZMRcwFQYDVQQDEw5BUk1QMlNSb290Q2VydIIQ/CFuffuO5IpB8pKeVFYjUjAJBgUrDgMCHQUAA4IBAQDPduo0vTjXL+5UeLf3msi8t8fJgx04Tm74mwSLRtE533ix2sojrxzwbEcJxreH/zNwH1Qc3bX1F8on6DmZTqLmcL2rwqXQINH5gQXq9Jxp1qwzvJNvxbz29KfnEFK91u+w0DWArS//HcD6Ix42EuwlTYKfDEexlcbFDzionOtmuxG2/syAU5U1EjhArIr2EIcpYV9bW6sY4UNNrUU7csY58cYq7VM8OChmZqNjq2pA+rrYKQ4JjsfPcvovA/g3QPGp2YmBko98X56duUHMiC6sVwcMQiSDhCsdTFNUDiBnfOWeWGNZqkU+xmThjLHmF1ou7xkSOYUg04s0KLQxxhga" 


# Get the Virtual Network
$vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $rgname
 
#Create IP for the gateway
$GWIP = New-AzureRmPublicIpAddress -AllocationMethod Dynamic -ResourceGroupName $rgname -Location $region -Name GWIP1
 
#Get the gateway subnet
$GWSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet
 
# Create GW Config
$GWIPConfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name GWIPConfig -SubnetId $gwsubnet.Id -PublicIpAddressId $GWIP.Id
 
#Create Gateway
#
# This takes a very, very long time.
#
$gw = New-AzureRmVirtualNetworkGateway -Location $region -Name GW1 -ResourceGroupName $rgname -GatewayType Vpn -IpConfigurations $GWIPConfig -VpnType RouteBased
 
# Create client VPN config 
Set-AzureRmVirtualNetworkGatewayVpnClientConfig -VirtualNetworkGateway $gw -VpnClientAddressPool $clientpool
 
# Create Root Cert
$rootCert = Add-AzureRmVpnClientRootCertificate -VpnClientRootCertificateName $RootCertName -PublicCertData $publicCertData -VirtualNetworkGatewayName $gw.Name -ResourceGroupName $rgname
 
#Get URL for VPN client - download the exe from here
#$packageUrl = Get-AzureRmVpnClientPackage -ResourceGroupName $rgname -VirtualNetworkGatewayName 

##################
Config for App Service to connect - work in progress
##################

$subscription_id = "<Subscription_ID>"
$NetworkName = "<Network_Name>"
$location = "<Region>"
$netrgname = "<Resource_Group_VNet_is_in>"
$AppServiceName = "<AppService_Name>"
 $props = @{
      "vnetResourceId" = "/subscriptions/$subscription_id/resourcegroups/$netrgname/providers/Microsoft.ClassicNetwork/virtualNetworks/$NetworkName";
      "certThumbprint"= "<Client_cert_thumbprint>";
      "certBlob"= "<Base64_Cert_Data>"; # all on one line, without begin and end headers
      "routes" = $null;
      }
 
New-AzureRMResource -ResourceName "$AppServiceName/$AppServiceName-to-$NetworkName" -Location $location  -ResourceGroupName $netrgname -ResourceType Microsoft.Web/sites/virtualNetworkConnections -PropertyObject $props -ApiVersion "2015-08-01" -force