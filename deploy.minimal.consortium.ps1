#
# Script to deploy a new consortium (initial member plus dashboard / bootnode)
#

Param(
    [Parameter(Mandatory=$True)]
    [string]$rgName,
    [string]$location = "WestEurope",
    [Parameter(Mandatory=$True)]  
    [string]$subName
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

