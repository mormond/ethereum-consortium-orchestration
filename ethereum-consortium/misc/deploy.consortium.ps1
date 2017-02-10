#Run from the etherem-consortium folder

login-azurermaccount 

$rgConsortiumName = "BC_Founder"
$location = "westeurope"

New-AzureRmResourceGroup -Location $location -Name $rgConsortiumName

New-AzureRmResourceGroupDeployment -TemplateFile .\template.consortium.json `
 -TemplateParameterFile .\misc\template.consortium.params.json `
 -ResourceGroupName $rgConsortiumName

#
# Add a DevBox VM
# After the VM is deployed and running.
# Remote desktop to the VM and open PowerShell.
# Navigate to C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.8\Downloads\0
# Set the execution policy to allow running local unsigned script (Set-ExecutionPolicy -Scope CurrentUser RemoteSigned)
# Run the InstallTruffle2.ps1 script
#

$adminUsername = "azureuser"
$password = Read-Host "Enter admin password"
$dnsLabelPrefix = "bcfounder1"

New-AzureRmResourceGroupDeployment -TemplateUri "https://raw.githubusercontent.com/dxuk/EthereumBlockchainDemo/master/DevVM/azuredeploy.json" `
 -ResourceGroupName $RgConsortiumName
 -adminUsername $adminUsername
 -adminPassword $password
 -dnsLabelPrefix $dnsLabelPrefix

