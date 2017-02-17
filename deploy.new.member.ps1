#
# Script to deploy an additional member to an existing consortium
# The address of the network bootnode must be provided
#

Param(
    [Parameter(Mandatory=$True)]
    [string]$rgMemberName, #Participant resource group name
    [Parameter(Mandatory=$True)]    
    [string]$dashboardIp, #IP of the consortium dashboard node (which is also the registrar node)
    [string]$location = "WestEurope",
    [string]$subName = "FounderAscendPlus",
    [string]$sqlAdminLogin = "dbadmin",
    [string]$databaseName = "accounts",
    [Parameter(Mandatory=$True)]
    [securestring]$sqlAdminPassword,
    [string]$hostingPlanName = "AppServicesHostingPlan",
    [string]$skuName = "S1"
)

$invocationPath = Split-Path $MyInvocation.MyCommand.Path

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
New-AzureRmResourceGroup -Location $location -Name $rgMemberName

Write-host "Deploying member template. Wish me luck."
Write-Host ($invocationPath + "\..\ethereum-consortium\template.consortium.params.participant1.json") 
New-AzureRmResourceGroupDeployment `
 -TemplateFile ($invocationPath + "\..\ethereum-consortium\template.consortiumMember.json") `
 -TemplateParameterFile ($invocationPath + "\ethereum-consortium\template.consortium.params.participant1.json") `
 -ResourceGroupName $rgMemberName `
 -dashboardIp $dashboardIp `
 -registrarIp $dashboardIp

#
# Add the App Service components (web site + SQL Server)
#
#

Write-Host "Deploying web site / API components."

$webOutputs = & ($invocationPath + "\node-interface-components\add.app.service.components.ps1") `
    -rgName $rgMemberName `
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
    -appName $webOutputs.Outputs.webApiName.Value
