#Run from the etherem-consortium folder

$rgConsortiumName = "BC_Founder"
$rgName = "BC_Founder"
$location = "westeurope"

$devVmAdminUsername = "azureuser"
$devVmPassword = Read-Host "Enter admin password"
$devVmDnsLabelPrefix = "bcfounder"

$hostingPlanName = "AppServicesHostingPlan"
$skuName = "S1"
$administratorLogin = "dbadmin"
$databaseName = "accounts"

login-azurermaccount 

New-AzureRmResourceGroup -Location $location -Name $rgConsortiumName

New-AzureRmResourceGroupDeployment -TemplateFile "..\ethereum-consortium\template.consortium.json" `
 -TemplateParameterFile ".\ethereum-consortium\template.consortium.params.json" `
 -ResourceGroupName $rgName

#
# Add a DevBox VM
# After the VM is deployed and running.
# Remote desktop to the VM and open PowerShell.
# Navigate to C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.8\Downloads\0
# Set the execution policy to allow running local unsigned script (Set-ExecutionPolicy -Scope CurrentUser RemoteSigned)
# Run the InstallTruffle2.ps1 script
#

New-AzureRmResourceGroupDeployment -TemplateUri "https://raw.githubusercontent.com/dxuk/EthereumBlockchainDemo/master/DevVM/azuredeploy.json" `
 -ResourceGroupName $rgName `
 -adminUsername $devVmAdminUsername `
 -adminPassword $devVmPassword `
 -dnsLabelPrefix $devVmDnsLabelPrefix

 #
 # Add the App Service components (web site + SQL Server)
 #
 #

 New-AzureRmResourceGroupDeployment -TemplateFile ".\node-interface-components\template.web.components.json" `
 -ResourceGroupName $rgName `
 -hostingPlanName $hostingPlanName `
 -skuName $skuName `
 -administratorLogin $administratorLogin `
 -databaseName $databaseName 

#
# Add the VNET Integration
#
#

$invocationPath = Split-Path $MyInvocation.MyCommand.Path

& ($invocationPath + "\node-interface-components\app.service.vnet.integration.ps1") 
