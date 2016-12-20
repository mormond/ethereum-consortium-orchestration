$Location = "WestEurope"

$BootNodeResourceGroupName = "BCDev_BootNode"
$BootNodeTemplateFile = ".\template.consortium.json"
$BootNodeTemplateParamsFile = ".\template.consortium.params.json"

$FounderResourceGroupName = "BCDev_Founder"
$MemberTemplateFile = ".\template.consortiumMember.json"
$MemberTemplateParamsFile = ".\template.consortiumMember.params.json"

$Member1ResourceGroupName = "BCDev_Member1"

#New-AzureRmResourceGroup -Name $BootNodeResourceGroupName -Location $Location
#New-AzureRmResourceGroupDeployment -ResourceGroupName $BootNodeResourceGroupName -TemplateFile $BootNodeTemplateFile -TemplateParameterFile $BootNodeTemplateParamsFile

New-AzureRmResourceGroup -Name $FounderResourceGroupName -Location $Location
New-AzureRmResourceGroupDeployment -ResourceGroupName $FounderResourceGroupName -TemplateFile $MemberTemplateFile -TemplateParameterFile $MemberTemplateParamsFile

New-AzureRmResourceGroup -Name $Member1ResourceGroupName -Location $Location
New-AzureRmResourceGroupDeployment -ResourceGroupName $Member1ResourceGroupName -TemplateFile $MemberTemplateFile -TemplateParameterFile $MemberTemplateParamsFile
