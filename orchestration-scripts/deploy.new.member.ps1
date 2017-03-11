#
# Script to deploy an additional member to an existing consortium
# The address of the network bootnode must be provided
#

Param(
    [Parameter(Mandatory=$True)]
    [string]$rgName, #Participant resource group name
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

$contentRoot = "https://raw.githubusercontent.com/mormond"
$ethereumArmTemplates = "ethereum-arm-templates"
$ethereumMemberServices = "ethereum-consortium-member-services"
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
New-AzureRmResourceGroup -Location $location -Name $rgName

Write-host "Deploying member template. Wish me luck."

$bcOutputs = New-AzureRmResourceGroupDeployment `
  -TemplateFile "$contentRoot/$ethereumArmTemplates/master/ethereum-consortium/template.consortiumMember.json" `
  -TemplateParameterFile ("$invocationPath\..\ethereum-consortium-params\template.consortium.params.participant1.json") `
  -ResourceGroupName $rgName `
  -dashboardIp $dashboardIp `
  -registrarIp $dashboardIp

#
# Add the App Service components (web site + SQL Server)
#
#

Write-Host "Deploying web site / API components."

$webOutputs = New-AzureRmResourceGroupDeployment `
  -TemplateUri "$contentRoot/$ethereumMemberServices/master/template.web.components.json" `
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
$tempExists = $True
$tempPath = "$invocationPath\temp"
If(!(Test-Path $tempPath)) { 
    $tempExists = $false
    New-Item -Path $tempPath -ItemType "Directory"
}

$vnetIntegrationScript = "$tempPath\app.service.vnet.integration.ps1"

Invoke-WebRequest -UseBasicParsing `
    -Uri "$contentRoot/$ethereumMemberServices/master/app.service.vnet.integration.ps1" `
    -OutFile $vnetIntegrationScript `
    -Verbose

Write-Host "Adding VNET integration."

& ($vnetIntegrationScript) `
    -rgName $rgName `
    -targetVnetName $bcOutputs.Outputs.member.Value.network.name.Value `
    -appName $webOutputs.Outputs.webApiName.Value

Write-Host "VNET integration complete."

Write-Host "Tidying up."
Remove-Item $vnetIntegrationScript
if (!$tempExists) {
    Remove-Item $tempPath
}
Write-Host "Done."