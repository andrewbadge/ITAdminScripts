<#
.SYNOPSIS
    Removes Windows 10 App installed by default that are unwanted.
.DESCRIPTION
    Removed unwanted apps, games and trialware from Windows 10.
.NOTES
    File Name      : Windows10-RemoveUnwantedApps.ps1
    Author         : Andrew Badge
    Prerequisite   : Windows 10
.LINK
    
#>
function RemoveUnwantedApps {
    try {
        Write-Host "Starting to remove unwanted apps"

        $bloatware = @(
            "*3DBuilder*"
            "*Bing*"
            "*CandyCrush*"
            "*DellInc.DellDigitalDelivery*"
            "*Facebook*"
            "*feedbackhub*"
            "*freshpaint*"
            "*king.com*"
            "*Linkedin*"
            "*Microsoft.Messaging*"
            "*Microsoft.MsixPackagingTool*"
            "*Microsoft.OneConnect*"
            "*Microsoft.People*"
            "*Microsoft.YourPhone*"
            "*Microsoft3DViewer*"
            "*MixedReality*"
            "*Netflix*"
            "*Office*"
            "*print3D*"
            "*Sketchable*"
            "*Solitaire*"
            "*soundrecorder*"
            "*Spotify*"
            "*Twitter*"
            "*wallet*"
            "*windowsalarms*"
            "*windowscommunicationsapps*"
            "*Windowsphone*"
            "*xbox*"
            "*xboxapp*"
            "*xboxgameoverlay*"
            "*Zune*"    
        )

        foreach ($bloat in $bloatware) {
            if (($app = Get-AppxPackage -AllUsers $bloat) -and ($app.Name -notlike "*XboxGameCallableUI*")) {
                Write-Host "$($app.Name) app found. Uninstalling..."
                try {
                    Write-Progress -CurrentOperation "$($app.Name) app found. Uninstalling..." -Activity "Uninstalling"
                    $app | Remove-AppxPackage -allusers -EA Stop
                } catch {
                    Write-Host "Uninstall of $($app.Name) failed. Error is:"
                    Write-Host $_.Exception.Message
                }                
            }
            if ($provapp = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like $bloat}) {
                Write-Host "$($provapp.DisplayName) provisioned app found. Uninstalling..."
                try {
                    Write-Progress -CurrentOperation "$($provapp.DisplayName) provisioned app found. Uninstalling..." -Activity "Uninstalling"
                    $provapp | Remove-AppxProvisionedPackage -Online -EA Stop
                } catch {
                    Write-Host "Uninstall of $($provapp.DisplayName) failed. Error is:"
                    Write-Host $_.Exception.Message
                }
            }
        }

        Write-Host "Complete"
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}
