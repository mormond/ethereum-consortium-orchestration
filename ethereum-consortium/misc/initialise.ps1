login-azurermaccount 

$RgConsortiumName = "Latest2"
New-AzureRmResourceGroup -Location "westeurope" -Name $RgConsortiumName
New-AzureRmResourceGroupDeployment -TemplateFile .\template.consortium.json -TemplateParameterFile .\misc\template.consortium.params.json -ResourceGroupName $RgConsortiumName

#$RgMemberName = ""
#New-AzureRmResourceGroup -Location "westeurope" -Name $RgMemberName
#New-AzureRmResourceGroupDeployment -TemplateFile .\template.consortiumMember.json -TemplateParameterFile .\misc\template.consortium.params.participant1.json -ResourceGroupName $RgMemberName

