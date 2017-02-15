#Run from the etherem-consortium folder

$rgConsortiumName = "BC_Founder"
$location = "westeurope"

$devVmAdminUsername = "azureuser"
$devVmPassword = Read-Host "Enter admin password"
$devVmDnsLabelPrefix = "bcfounder"

login-azurermaccount 

New-AzureRmResourceGroup -Location $location -Name $rgConsortiumName

New-AzureRmResourceGroupDeployment -TemplateFile ..\ethereum-consortium\template.consortium.json `
 -TemplateParameterFile .\ethereum-consortium\template.consortium.params.json `
 -ResourceGroupName $rgName

#
# Add a DevBox VM
# After the VM is deployed and running.
# Remote desktop to the VM and open PowerShell.
# Navigate to C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.8\Downloads\0
# Set the execution policy to allow running local unsigned script (Set-ExecutionPolicy -Scope CurrentUser RemoteSigned)
# Run the InstallTruffle2.ps1 script
#

New-AzureRmResourceGroupDeployment -TemplateUri "https://raw.githubusercontent.com/dxuk/EthereumBlockchainDemo/master/DevVM/azuredeploy.json" `
 -ResourceGroupName $rgName
 -adminUsername $devVmAdminUsername
 -adminPassword $devVmPassword
 -dnsLabelPrefix $devVmDnsLabelPrefix

