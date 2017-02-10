########################
# Template Files
########################
function CreateConsortiumMember ($resourceGroupName, $location, $templateFile, $paramsFile, $consortiumName, $bootNodeIp = "0.0.0.0") {

    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

    if ($bootNodeIp -eq "0.0.0.0") {
        Write-Host "Creating boot node"
        Write-Host "New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFile -TemplateParameterFile $paramsFile -consortiumName $consortiumName"

        New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
        -TemplateFile $templateFile `
        -TemplateParameterFile $paramsFile `
        -consortiumName $consortiumName   
    }
    else {
        Write-Host "Creating member node $consortiumName..."

        New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
        -TemplateFile $templateFile `
        -TemplateParameterFile $paramsFile `
        -consortiumName $consortiumName `
        -dashboardIp $bootNodeIp `
        -registrarIp $bootNodeIp 
    }
}

########################
# Members 
########################
$location = "WestEurope"

$resourceGroupPrefix = "BCDev1_"
$bootNodeResourceGroupName = $resourceGroupPrefix + "BootNode"
$bootNodeConsortiumName = "bootnode"
$member1ResourceGroupName = $resourceGroupPrefix + "Founder"
$member1ConsortiumName = "founder"
$member2ResourceGroupName = $resourceGroupPrefix + "Member2"
$member2ConsortiumName = "member2"

########################
# Template Files
########################
$bootNodeTemplateFile = ".\template.consortium.json"
$memberTemplateFile = ".\template.consortiumMember.json"

########################
# Param Files
########################
$bootNodeTemplateParamsFile = ".\template.consortium.params.json"
$memberTemplateParamsFile = ".\template.consortiumMember.params.json"

########################
# Bootnode
########################
$bootNodeDeployment = CreateConsortiumMember $bootNodeResourceGroupName $location $bootNodeTemplateFile $bootNodeTemplateParamsFile $bootNodeConsortiumName
$dashboardIp = $bootNodeDeployment.Outputs.dashboardIp.value

########################
# Founder Node
########################
CreateConsortiumMember $member1ResourceGroupName $location $memberTemplateFile $memberTemplateParamsFile $member1ConsortiumName $dashboardIp   

########################
# Member2 Node
########################
CreateConsortiumMember $member2ResourceGroupName $location $memberTemplateFile $memberTemplateParamsFile $member2ConsortiumName $dashboardIp   

