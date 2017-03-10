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
    [Parameter(Mandatory=$True)]    
    [string]$subName,
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

#Write-Host "Setting subscription to: $subName"
#Select-AzureRmSubscription -SubscriptionName $subName

Write-Host "Creating new resource group: $rgName"
New-AzureRmResourceGroup -Location $location -Name $rgMemberName

Write-host "Deploying member template. Wish me luck."

$bcOutputs = New-AzureRmResourceGroupDeployment `
  -TemplateFile "https://raw.githubusercontent.com/mormond/ethereum-arm-templates/master/ethereum-consortium/template.consortiumMember.json" `
  -TemplateParameterFile ($invocationPath + "..\ethereum-consortium-params\template.consortium.params.participant1.json") `
  -ResourceGroupName $rgMemberName `
  -dashboardIp $dashboardIp `
  -registrarIp $dashboardIp

#
# Add the App Service components (web site + SQL Server)
#
#

Write-Host "Deploying web site / API components."

$webOutputs = New-AzureRmResourceGroupDeployment `
  -TemplateUri "https://raw.githubusercontent.com/mormond/member-appservices/master/template.web.components.json" `
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

Write-Host $bcOutputs.Outputs.member.Value.network.name.Value

#Pull down the PowerShell Script to add the VNet Integration
$temp = New-Item -Path "." -Name "temp" -ItemType "Directory"
$vnetIntegrationScript = "$temp\app.service.vnet.integration.ps1"

Invoke-WebRequest -UseBasicParsing `
    -Uri "https://raw.githubusercontent.com/mormond/ethereum-consortium-member-services/master/app.service.vnet.integration.ps1" `
    -OutFile $vnetIntegrationScript `
    -Verbose

Write-Host "Adding VNET integration."

& ($vnetIntegrationScript) `
    -rgName $rgMemberName `
    -targetVnetName $bcOutputs.Outputs.member.Value.network.name.Value `
    -appName $webOutputs.Outputs.webApiName.Value
