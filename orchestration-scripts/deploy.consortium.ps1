#
# Script to deploy:
# A new consortium (initial member plus dashboard / bootnode) - $chosenDeploymentType = "founder"
# A minimal consortium (mainly for testing as a full deployment is lengthy) - $chosenDeploymentType = "minimal"
# Add a new member to an existing consortium - $chosenDeploymentType = "newmember"
#

Param(
    # For All Deployments
    [Parameter(Mandatory = $True)]
    [string]$rgName,
    [string]$location = "WestEurope",
    [string]$subName,
    [string]$sqlAdminLogin = "dbadmin",
    [string]$databaseName = "accounts",
    [Parameter(Mandatory = $True)]   
    [ValidateSet("Founder", "NewMember", "Minimal", IgnoreCase = $True)]
    [string]$chosenDeploymentType,

    # Only for founder deployment
    [string]$devVmDnsLabelPrefix,
    [securestring]$devVmPassword,
    [string]$devVmAdminUsername = "azureuser",
    [string]$devVmVnetName = "dx-founder-vnet",
    [string]$devVmNicName = "DevVMNic",
    [string]$devVmSubnetName = "subnet-txnodes",
    [string]$devVmIpAddressName = "DevVMPublicIP",
    [string]$devVmVmName = "DevVM",
    
    # Only for newmember deployment
    [string]$dashboardIp, # IP of the consortium dashboard node (which is also the registrar node)

    # Only for founder / new member deployment
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

Set-Variable minimalDeployment "minimal" -Option Constant
Set-Variable founderDeployment "founder" -Option Constant
Set-Variable newMemberDeployment "newmember" -Option Constant
Set-Variable contentRoot "https://raw.githubusercontent.com/mormond" -Option Constant
Set-Variable ethereumArmTemplates "ethereum-arm-templates" -Option Constant
Set-Variable ethereumDevVm "ethereum-dev-vm" -Option Constant
Set-Variable ethereumMemberServices "ethereum-consortium-member-services" -Option Constant

$invocationPath = Split-Path $MyInvocation.MyCommand.Path

#
# What type of deployment are we doing - check we have the required parameters
#

$chosenDeploymentType = $chosenDeploymentType.ToLowerInvariant()

switch ($chosenDeploymentType) {
    $founderDeployment {
        if (!($devVmDnsLabelPrefix -and $devVmPassword -and $sqlAdminPassword)) {
            Write-Host
            Write-Host "Missing parameters..."
            $devVmDnsLabelPrefix = Read-Host "devVmDnsLabelPrefix"
            $devVmPassword = Read-Host "devVmPassword" -AsSecureString
            $sqlAdminPassword = Read-Host "sqlAdminPassword" -AsSecureString
        }
    }
    $newMemberDeployment {   
        if (!($dashboardIp -and $sqlAdminPassword)) {
            Write-Host               
            Write-Host "Missing parameters..."
            $dashboardIp = Read-Host "dashboardIp"
            $sqlAdminPassword = Read-Host "sqlAdminPassword" -AsSecureString
        }
    }
}

Write-Host "Logging into Azure"
CheckAndAuthenticateIfRequired

if ($subName) {
    Write-Host "Setting subscription to: $subName"
    Select-AzureRmSubscription -SubscriptionName $subName
}

Write-Host "Creating new resource group: $rgName"
New-AzureRmResourceGroup -Location $location -Name $rgName

Write-host "Deploying template. Wish me luck."

if ($chosenDeploymentType -eq $minimalDeployment -Or 
    $chosenDeploymentType -eq $founderDeployment) {

    $ethOutputs = New-AzureRmResourceGroupDeployment `
        -TemplateUri "$contentRoot/$ethereumArmTemplates/master/ethereum-consortium/template.consortium.json" `
        -TemplateParameterFile ("$invocationPath\..\ethereum-consortium-params\template.consortium.params.json") `
        -ResourceGroupName $rgName

    $memberName = $ethOutputs.Parameters.members.Value[0].name.value
    $consortiumName = $ethOutputs.Parameters.consortiumName.value

    $vnetName = "$consortiumName-$memberName-vnet"
    $nsgName = "$consortiumName-$memberName-nsg-txnodes"

}
else {
    $ethOutputs = New-AzureRmResourceGroupDeployment `
        -TemplateFile "$contentRoot/$ethereumArmTemplates/master/ethereum-consortium/template.consortiumMember.json" `
        -TemplateParameterFile ("$invocationPath\..\ethereum-consortium-params\template.consortium.params.participant1.json") `
        -ResourceGroupName $rgName `
        -dashboardIp $dashboardIp `
        -registrarIp $dashboardIp

    $consortiumMemberName = $ethOutputs.Parameters.consortiumMemberName.value
    $vnetName = "$consortiumMemberName-vnet"
}

#
# If this was a minimal deployment, we're done.
#
if ($chosenDeploymentType -eq $minimalDeployment) {
    Write-Host "Done."
    exit
}

#
# IF this is a founder deployment
# Add a DevBox VM
#
if ($chosenDeploymentType -eq $founderDeployment) {

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

    Write-Host "Deploying Dev VM."

    New-AzureRmResourceGroupDeployment `
        -TemplateUri "$contentRoot/$ethereumDevVm/add-to-existing-vnet/azuredeploy.json" `
        -ResourceGroupName $rgName `
        -adminUsername $devVmAdminUsername `
        -adminPassword $devVmPassword `
        -dnsLabelPrefix $devVmDnsLabelPrefix `
        -virtualNetworkName $devVmVnetName `
        -nicName $devVmNicName `
        -subnetName $devVmSubnetName `
        -publicIPAddressName $devVmIpAddressName `
        -vmName $devVmVmName

}

#
# Add the App Service components (web site + SQL Server)
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

# Start by pulling down the PowerShell script to add the VNet Integration
$tempExists = $True
$tempPath = "$invocationPath\temp-$vnetName"
If (!(Test-Path $tempPath)) { 
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
        -targetVnetName $vnetName `
        -appName $webOutputs.Outputs.webApiName.Value

Write-Host "VNET integration complete."

Write-Host "Tidying up."
Remove-Item $vnetIntegrationScript
if (!$tempExists) {
    Remove-Item $tempPath
}

Write-Host "Done."
