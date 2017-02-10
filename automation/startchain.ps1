<#
.SYNOPSIS
  Connects to Azure and starts all VMs / VM Scale Sets in the specified resource group

.PARAMETER ResourceGroupName
   Required
   The resource group containing the VMs VM Scale Sets to stop.  

.NOTES
   Based on the original "Stop Azure V2 VMs" script by
   AUTHOR: System Center Automation Team 
   LASTEDIT: January 7, 2016
#>

param (
    #    [Parameter(Mandatory=$false)] 
    #    [String]  $AzureCredentialAssetName = 'AzureCredential',
        
    #    [Parameter(Mandatory=$false)]
    #    [String] $AzureSubscriptionIdAssetName = 'AzureSubscriptionId'

    [Parameter(Mandatory=$true)] 
    [String] $ResourceGroupName
)

# Returns strings with status messages
[OutputType([String])]

$connectionName = "AzureRunAsConnection"
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
"Logging into Azure..."
$null = Add-AzureRmAccount `
	-ServicePrincipal `
	-TenantId $servicePrincipalConnection.TenantId `
	-ApplicationId $servicePrincipalConnection.ApplicationId `
	-CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
	-ErrorAction Stop `
	-ErrorVariable err

if($err) {
    throw $err
}

function CheckStatus($status) {
    foreach ($VMStatus in $status) { 
        if($VMStatus.Code -like "PowerState/*") {
            return $VMStatus.DisplayStatus
        }
    }
}

$ResourceGroupNames =  @($ResourceGroupName)

foreach ($RG in $ResourceGroupNames) {

    # Find all the scale set VMs
    $ScaleSets = Get-AzureRmVmss -ResourceGroupName $RG

    foreach($SS in $ScaleSets) {
        Write-Output ("Starting scale set: " + $ss.Name)
        Start-AzureRmVmss -ResourceGroupName $RG -VMScaleSetName $ss.Name
    }

    $VMs = Get-AzureRmVM -ResourceGroupName $RG

    # Start each of the VMs
    foreach ($VM in $VMs) {
        $VMDetail = $VM | Get-AzureRmVM -Status

        foreach ($VMStatus in $VMDetail.Statuses) { 
            if($VMStatus.Code -like "PowerState/*") {
                $VMStatusDetail = $VMStatus.DisplayStatus
            }
        }

        Write-Output ("Current VM: " + $VM.Name);
        Write-Output ($VM.Name + " status is '" + $VMStatusDetail + "'");

        if ($VMStatusDetail -eq "VM Running") {
            Write-Output ("Not attempting to start " + $VM.Name + " as it's aleady running.")
        }
        else {
            $StartRtn = $VM | Start-AzureRmVM -Force -ErrorAction Continue

            if ($StartRtn.IsSuccessStatusCode -ne $True) {
                # The VM failed to start, so send notice
                Write-Output ($VM.Name + " failed to start")
                Write-Error ($VM.Name + " failed to start. Error was:") -ErrorAction Continue
                Write-Error ($StartRtn.ReasonPhrase) -ErrorAction Continue
            }
            else {
                # The VM started, so send notice
                Write-Output ($VM.Name + " has been started")
            }
        }   
    }
}