#Run from the etherem-consortium folder

$rgName = "test1233"
$location = "westeurope"
$subName = "FounderAscendPlus"

$devVmAdminUsername = "azureuser"
$devVmSecurePassword = Read-Host "Enter admin password" #-AsSecureString

#$devVmPassword = ConvertFrom-SecureString -SecureString $devVmSecurePassword
#Write-Host $devVmPassword

$devVmDnsLabelPrefix = "test1233"

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

#
# Add a DevBox VM
# After the VM is deployed and running.
# Remote desktop to the VM and open PowerShell.
# Navigate to C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.8\Downloads\0
# Set the execution policy to allow running local unsigned script (Set-ExecutionPolicy -Scope CurrentUser RemoteSigned)
# Run the InstallTruffle2.ps1 script
#


$params = @($rgName, $devVmAdminUsername, $devVmSecurePassword, $devVmDnsLabelPrefix)

Write-Host "Deploying Dev VM."
$job = Start-Job -ScriptBlock `
{
    param($rgName1, $devVmAdminUsername1, $devVmSecurePassword1, $devVmDnsLabelPrefix1)

    #    $devVmPassword1 = ConvertFrom-SecureString -SecureString $devVmSecurePassword1

    $parameters = @{ "adminUsername" = $devVmAdminUsername1; "adminPassword" = $devVmSecurePassword1; "dnsLabelPrefix" = $devVmAdminUsername1}

    New-AzureRmResourceGroupDeployment -TemplateUri "https://raw.githubusercontent.com/dxuk/EthereumBlockchainDemo/master/DevVM/azuredeploy.json" `
    -ResourceGroupName $rgName1 `
    -TemplateParameterObject $parameters
} -ArgumentList $params

Wait-Job -Job $job

# Getting the information back from the jobs

Get-Job | Receive-Job