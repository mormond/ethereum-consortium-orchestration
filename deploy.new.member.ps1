#Run from the etherem-consortium folder

$rgName = "test1233"
$location = "westeurope"
$subName = "FounderAscendPlus"

$hostingPlanName = "AppServicesHostingPlan"
$skuName = "S1"
$administratorLogin = "dbadmin"
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

$RgMemberName = "BC_Member1" #Participant resource group name
$MemberName = "member1" #Name that will show up in dashboard
$DashboardIp = "" #IP of the consortium dashboard node (which is also the registrar node)

New-AzureRmResourceGroup -Location "westeurope" -Name $RgMemberName
New-AzureRmResourceGroupDeployment -TemplateFile .\template.consortiumMember.json `
 -TemplateParameterFile .\misc\template.consortium.params.participant1.json `
 -ResourceGroupName $RgMemberName `
 -consortiumMemberName $MemberName `
 -dashboardIp $DashboardIp `
 -registrarIp $DashboardIp

  #
 # Add the App Service components (web site + SQL Server)
 #
 #

Write-Host "Deploying web site / API components."
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

Write-Host "Adding VNET integration."
$invocationPath = Split-Path $MyInvocation.MyCommand.Path

& ($invocationPath + "\node-interface-components\app.service.vnet.integration.ps1") 
