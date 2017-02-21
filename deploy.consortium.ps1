#
# Script to deploy a new consortium (initial member plus dashboard / bootnode)
#

Param(
    [Parameter(Mandatory=$True)]
    [string]$rgName,
    [string]$location = "WestEurope",
    [Parameter(Mandatory=$True)]   
    [string]$subName,
    [string]$devVmAdminUsername = "azureuser",
    [Parameter(Mandatory=$True)]
    [string]$devVmDnsLabelPrefix,
    [string]$sqlAdminLogin = "dbadmin",
    [string]$databaseName = "accounts",
    [Parameter(Mandatory=$True)]
    [securestring]$devVmPassword,
    [Parameter(Mandatory=$True)]
    [securestring]$sqlAdminPassword,
    [string]$hostingPlanName = "AppServicesHostingPlan",
    [string]$skuName = "S1"
)

$vnetName = "dx-founder-vnet"

function CheckAndAuthenticateIfRequired {
    Try {
        $a = Get-AzureRmContext
    }
    Catch {
        login-azurermaccount 
    }
}

$invocationPath = Split-Path $MyInvocation.MyCommand.Path

Write-Host "Logging into Azure"
CheckAndAuthenticateIfRequired

#Write-Host "Setting subscription to: $subName"
#Select-AzureRmSubscription -SubscriptionName $subName

Write-Host "Creating new resource group: $rgName"
New-AzureRmResourceGroup -Location $location -Name $rgName

Write-host "Deploying consortium template. Wish me luck."
$ethOutputs = New-AzureRmResourceGroupDeployment -TemplateFile ($invocationPath + "\..\ethereum-consortium\template.consortium.json") `
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

$deployment = Get-AzureRmResourceGroupDeployment -ResourceGroupName $rgName `
 -DeploymentName "template.consortium"

$consortiumName = $deployment.Parameters.consortiumName[0].Value
$memberName = $deployment.Parameters.members.Value[0].name.Value
$nsgName = "$consortiumName-$memberName-nsg-txnodes"
$vnetName = "$consortiumName-$memberName-vnet"

$nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName

$nsg | Add-AzureRmNetworkSecurityRuleConfig `
 -Name RDPRule `
 -Protocol TCP `
 -SourcePortRange * `
 -DestinationPortRange 3389 `
 -SourceAddressPrefix * `
 -DestinationAddressPrefix * `
 -Access Allow `
 -Direction Inbound `
 -Priority 1001

$nsg | Set-AzureRmNetworkSecurityGroup

#Write-Host "Deploying Dev VM."
#New-AzureRmResourceGroupDeployment -TemplateUri "https://raw.githubusercontent.com/dxuk/EthereumBlockchainDemo/master/DevVM/azuredeploy.json" `

New-AzureRmResourceGroupDeployment -TemplateFile ".\devvm\template.devvm.json" `
 -ResourceGroupName $rgName `
 -adminUsername $devVmAdminUsername `
 -adminPassword $devVmPassword `
 -dnsLabelPrefix $devVmDnsLabelPrefix `
 -virtualNetworkName $vnetName

#
# Add the App Service components (web site + SQL Server)
#
#

Write-Host "Deploying web site / API components."

$webOutputs = & ($invocationPath + "\node-interface-components\add.app.service.components.ps1") `
    -rgName $rgName `
    -sqlAdminLogin $sqlAdminLogin `
    -sqlAdminPassword $sqlAdminPassword `
    -databaseName $databaseName `
    -hostingPlanName $hostingPlanName `
    -skuName $skuName
   
#
# Add the VNET Integration
#
#

Write-Host "Adding VNET integration."

& ($invocationPath + "\node-interface-components\app.service.vnet.integration.ps1") `
    -rgName $rgName `
    -targetVnetName $vnetName `
    -appName $webOutputs.Outputs.webApiName.Value
