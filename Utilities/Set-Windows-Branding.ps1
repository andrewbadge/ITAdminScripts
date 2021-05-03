<#
.SYNOPSIS
   Set the Windows Wallpaper and lockscreen
.DESCRIPTION
    
.INPUTS
    [String] $LockScreenSource
    [String] $BackgroundSource
.NOTES
    File Name      : Set-Windows-Branding.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1
.EXAMPLE 
    Set-Windows-Branding 
#>

function Set-Windows-Branding {
    param (
        [String] $LockScreenSource,
        [String] $BackgroundSource
    )    

    try {
        $RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
        $DesktopPath = "DesktopImagePath"
        $DesktopStatus = "DesktopImageStatus"
        $DesktopUrl = "DesktopImageUrl"
        $LockScreenPath = "LockScreenImagePath"
        $LockScreenStatus = "LockScreenImageStatus"
        $LockScreenUrl = "LockScreenImageUrl"

        $StatusValue = "1"
        $DesktopImageValue = "C:\Windows\System32\oobe\Desktop.jpg"
        $LockScreenImageValue = "C:\Windows\System32\oobe\LockScreen.jpg"
        
        if(!(Test-Path $RegKeyPath)) {
            Write-Host "Creating registry path $($RegKeyPath)."
            New-Item -Path $RegKeyPath -Force | Out-Null
        }
        if ($LockScreenSource) {
            Write-Host "Copy Lock Screen image from $($LockScreenSource) to $($LockScreenImageValue)."
            #(New-Object System.Net.WebClient).DownloadFile($LockScreenSource, "$LockScreenImageValue")
            copy-item $LockScreenSource "$LockScreenImageValue"
            Write-Host "Creating registry entries for Lock Screen"
            New-ItemProperty -Path $RegKeyPath -Name $LockScreenStatus -Value $StatusValue -PropertyType DWORD -Force | Out-Null
            New-ItemProperty -Path $RegKeyPath -Name $LockScreenPath -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null
            New-ItemProperty -Path $RegKeyPath -Name $LockScreenUrl -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null
        }
        if ($BackgroundSource) {
            Write-Host "Copy Desktop Background image from $($BackgroundSource) to $($DesktopImageValue)."
            #(New-Object System.Net.WebClient).DownloadFile($BackgroundSource, "$DesktopImageValue")
            copy-item $BackgroundSource "$DesktopImageValue"
            Write-Host "Creating registry entries for Desktop Background"
            New-ItemProperty -Path $RegKeyPath -Name $DesktopStatus -Value $StatusValue -PropertyType DWORD -Force | Out-Null
            New-ItemProperty -Path $RegKeyPath -Name $DesktopPath -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null
            New-ItemProperty -Path $RegKeyPath -Name $DesktopUrl -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null
        }  

    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

$LockScreenSource = "c:\tmp\lockscreen.jpg" 
$BackgroundSource = "c:\tmp\wallpaper.jpg"
Set-Windows-Branding $LockScreenSource $BackgroundSource