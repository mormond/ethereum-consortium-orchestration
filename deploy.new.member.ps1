#
# Script to deploy an additional member to an existing consortium
# The address of the network bootnode must be provided
#

Param(
    [Parameter(Mandatory=$True)]
    [string]$rgMemberName, #Participant resource group name
    [string]$memberName, #Name that will show up in dashboard
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

New-AzureRmResourceGroup -Location "westeurope" -Name $rgMemberName
New-AzureRmResourceGroupDeployment -TemplateFile .\template.consortiumMember.json `
 -TemplateParameterFile .\misc\template.consortium.params.participant1.json `
 -ResourceGroupName $rgMemberName `
 -consortiumMemberName $memberName `
 -dashboardIp $dashboardIp `
 -registrarIp $dashboardIp

#
# Add the App Service components (web site + SQL Server)
#
#

Write-Host "Deploying web site / API components."
$webOutputs = New-AzureRmResourceGroupDeployment -TemplateFile ".\node-interface-components\template.web.components.json" `
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

& ($invocationPath + "\node-interface-components\app.service.vnet.integration.ps1") `
    -rgName $rgName `
    -appName $webOutputs.Outputs.webApiName.Value
