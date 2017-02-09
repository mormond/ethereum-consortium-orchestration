login-azurermaccount 

$RgConsortiumName = "Latest2"

New-AzureRmResourceGroup -Location "westeurope" -Name $RgConsortiumName
New-AzureRmResourceGroupDeployment -TemplateFile .\template.consortium.json `
 -TemplateParameterFile .\misc\template.consortium.params.json `
 -ResourceGroupName $RgConsortiumName

$RgMemberName = "Latest22" #Participant resource group -Name
$DashboardIp = "" #IP of the consortium dashboard node (which is also the registrar node)

New-AzureRmResourceGroup -Location "westeurope" -Name $RgMemberName
New-AzureRmResourceGroupDeployment -TemplateFile .\template.consortiumMember.json `
 -TemplateParameterFile .\misc\template.consortium.params.participant1.json `
 -ResourceGroupName $RgMemberName `
 -consortiumMemberName $RgMemberName `
 -dashboardIp $DashboardIp `
 -registrarIp $DashboardIp
