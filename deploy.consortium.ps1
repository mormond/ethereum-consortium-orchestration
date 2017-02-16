#Run from the etherem-consortium folder

$rgConsortiumName = "BC_Founder"
$rgName = "BC_Test_Consortium_Delete"
$location = "westeurope"

$devVmAdminUsername = "azureuser"
$devVmDnsLabelPrefix = "bcfounder"
$devVmPassword = Read-Host "Enter dev vm admin password" -AsSecureString
$hostingPlanName = "AppServicesHostingPlan"
$skuName = "S1"
$sqlAdminLogin = "dbadmin"
$sqlAdminPassword = Read-Host "Enter sql admin password" -AsSecureString
$databaseName = "accounts"

function CheckAndAuthenticateIfRequired {
    Try {
        $a = Get-AzureRmContext
    }
    Catch {
        login-azurermaccount 
    }
}

Write-Host "Logging into Azure"
CheckAndAuthenticateIfRequired

Write-Host "Setting subscription to: $subName"
Select-AzureRmSubscription -SubscriptionName $subName

Write-Host "Creating new resource group: $rgName"
New-AzureRmResourceGroup -Location $location -Name $rgName

Write-host "Deploying consortium template. Wish me luck."
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

Write-Host "Deploying Dev VM."
New-AzureRmResourceGroupDeployment -TemplateUri "https://raw.githubusercontent.com/dxuk/EthereumBlockchainDemo/master/DevVM/azuredeploy.json" `
 -ResourceGroupName $rgName `
 -adminUsername $devVmAdminUsername `
 -adminPassword $devVmPassword `
 -dnsLabelPrefix $devVmDnsLabelPrefix

 #
 # Add the App Service components (web site + SQL Server)
 #
 #

Write-Host "Deploying web site / API components."
New-AzureRmResourceGroupDeployment -TemplateFile ".\node-interface-components\template.web.components.json" `
  -ResourceGroupName $rgName `
  -hostingPlanName $hostingPlanName `
  -skuName $skuName `
  -administratorLogin $sqlAdminLogin `
  -administratorLoginPassword $sqlAdminPassword `
  -databaseName $databaseName 

#
# Add the VNET Integration
#
#

Write-Host "Adding VNET integration."
$invocationPath = Split-Path $MyInvocation.MyCommand.Path

& ($invocationPath + "\node-interface-components\app.service.vnet.integration.ps1") 
