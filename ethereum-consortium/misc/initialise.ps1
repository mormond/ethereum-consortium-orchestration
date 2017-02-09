login-azurermaccount 

$RgConsortiumName = "BC_Founder"

New-AzureRmResourceGroup -Location "westeurope" -Name $RgConsortiumName
New-AzureRmResourceGroupDeployment -TemplateFile .\template.consortium.json `
 -TemplateParameterFile .\misc\template.consortium.params.json `
 -ResourceGroupName $RgConsortiumName

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
