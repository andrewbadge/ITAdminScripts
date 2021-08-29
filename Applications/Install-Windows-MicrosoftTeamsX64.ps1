<#
.SYNOPSIS
   Downloads a MS Teams and installs (if not already installed)
.DESCRIPTION
    NB: Teams installer should be run as the logged in user, not SYSTEM
.INPUTS
    None
.OUTPUTS
    Debug Console information only
.NOTES
    File Name      : Install-Windows-MicrosoftTeamsx64.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1    
#>

function Download-File {
    param (
        [Parameter(Mandatory = $true)]
        [string] $FileURL,
        [Parameter(Mandatory = $true)]
        [string] $LocalFileName
    )    

    try {
        
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($FileURL,"$LocalFileName")
        
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

function Is-Account-System {
    try {
        
        return ([Environment]::UserName -eq "SYSTEM")
        
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

function Is-Application-Installed {
    param (
        [string] $AppName
    )    

    try {

        $installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -like $AppName }) -ne $null
        If(-Not $installed) {
            $installed = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -like $AppName }) -ne $null
        }

        If(-Not $installed) {
            Write-Host "'$AppName' NOT is installed."
            return $false
        } else {
            Write-Host "'$AppName' is installed."
            return $true
        }

    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

# Cache Folder on the local PC
$BaseFolder = "$env:ALLUSERSPROFILE\ORGNAME"

try {
    $IsAccountSystem = Is-Account-System 
    if (!$IsAccountSystem) {
        $IsInstalled = Is-Application-Installed "Teams*"
        if (!$IsInstalled) {

            New-Item -ItemType Directory -Force -Path $BaseFolder

            if ((Get-WmiObject win32_operatingsystem | select-object osarchitecture).osarchitecture -eq "64-bit")
            {
                Write-Host "Downloading 64-bit OS version of Teams"

                $URL = "https://go.microsoft.com/fwlink/?linkid=859722"
                $File = "$BaseFolder\Teams_windows_x64.exe"
                Download-File $URL $File

                Write-Host "Installing MSTeams"
                & "$File" -s
            }
            else
            {
                Write-Host "This script does not run on a 32-bit OS. Nothing installed."
            }
            Write-Host "Complete."
        }
    }
    else {
        Write-Host "This script must run as the Logged in User not SYSTEM. Nothing installed."
    }
} catch {
    Write-Host "Fatal Exception:[$_.Exception.Message]"
}
