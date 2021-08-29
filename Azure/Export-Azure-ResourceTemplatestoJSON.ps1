<#
.SYNOPSIS
   Exports all Azure resources to JSON templates
.DESCRIPTION
    Install Module from PS
        Install-Module -Name Az -Repository PSGallery -Force
    If you have issues installing the module; ensure you are running as admin. you can also try 
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process  
    Or install from MSI from Github
    https://github.com/Azure/azure-powershell/releases
    NB: This script will export what ever subscriptions and resources your account has access to. 
    
.INPUTS
    
.NOTES
    File Name      : Export-AzureResources.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1
#>

# Authenticate to Azure. You will be promoted for creds and MFA
Connect-AzAccount

# Create the base/root folder to export to. Update the path if required.
$CurrentDate = Get-Date
$BaseFolder = "c:\tmp\AzureExport-" + $CurrentDate.ToString("yyyy-MM-dd")
New-Item -ItemType Directory -Force -Path $BaseFolder

#Get all the subscriptions
$Subscriptions = Get-AzSubscription
foreach ($sub in $Subscriptions) {
    $SubName = $sub.Name
    Write-Host "--Subscription:" $SubName 

    #Create a folder the subscriptions
    $SubFolder = "$BaseFolder\$SubName"
    New-Item -ItemType Directory -Force -Path $SubFolder

    #Change the context to that subscription and get all the resource groups
    Get-AzSubscription -SubscriptionName $SubName | Set-AzContext
    $ResourceGroups = Get-AzResourceGroup

    #Loop through each resource group
    #NB: you can't export the resource group in one action as there is a 200 item limit
    foreach ($rg in $ResourceGroups) {

        #Get the Resource group 
        $RGName = $rg.ResourceGroupName
        Write-Host "----ResourceGroup:" $RGName       
        
        #Create the folder for each RersourceGroup
        $RGFolder = "$SubFolder\$RGName"
        $RGFilename = "$RGFolder\$RGName.json"
        New-Item -ItemType Directory -Force -Path $RGFolder
        Write-Host "Exporting to:" $RGFolder 

        #Loop through each resource in each resource group
        $Resources = Get-AzResource -ResourceGroupName $RGName
        foreach ($resource in $Resources) {
            #NB: some resources contain \  or / in the so this is replaced with _
            $ResourceId = $resource.ResourceId
            $ResourceName = $resource.Name.Replace("\","_").Replace("/","_")
            $ErrorFile = "$RGFolder\$ResourceName.EXCEPTION"

            #Do the export for the resource
            Write-Host "------Exporting Resource:" $ResourceName 
            try {
                Export-AzResourceGroup -Path "$RGFolder" -ResourceGroupName "$RGName" -Resource "$ResourceId"  -WarningVariable CapturedWarning
                #If there is a warning, output this alongside the export JSON file
                if ($CapturedWarning) 
                {
                    $CapturedWarning | Out-File -FilePath "$RGFolder\$ResourceName.WARNING"
                }   

                #Rename the export to the Resource name as the Export function always names it the ResourceGroup Name
                $RGNewFilename = "$RGFolder\$ResourceName.json"
                if (Test-Path $RGFilename -PathType leaf) { Rename-Item -Path "$RGFilename" -NewName "$RGNewFilename" }
            } catch {
                Write-Host "Fatal Exception:[$_.Exception.Message]"
                $_.Exception.Message | Out-File -FilePath $ErrorFile
            } finally {
                #Remove any leftover export if there is an exception so it doesn't cause any error for the next resource
                if (Test-Path $RGFilename -PathType leaf) { Remove-Item -Path "$RGFilename" -Force }
            }
        }

        Write-Host "----Export Complete for ResourceGroup:" $RGName 
    }
    Write-Host "--Export Complete for Subscription:" $SubName 
}
Write-Host "--Finished"
