<#
.SYNOPSIS
   Downloads a new normal.dotm template and copies it for the logged in user
   Backs up the old Normal.dotm (first Time only)
.DESCRIPTION
    NB:This script should be run as the logged in user, not SYSTEM
.INPUTS
    None
.OUTPUTS
    Debug Console information only
.NOTES
    File Name      : Download-Windows-WordNormalTemplate.ps1
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

try {
    $IsAccountSystem = Is-Account-System 
    if (!$IsAccountSystem) {
        #Set intial Folder and crerate if missing
        $BaseFolder = "$env:ALLUSERSPROFILE\OrgName\Templates"
        New-Item -ItemType Directory -Force -Path $BaseFolder

        # Download the new template
        # Change the source "version" filename if you want to redownload and overwrite the existing template 
        $URL = "https://github.com/PublicPathToTemplateFile/normal-V2021Sept7.dotm"
        $DownloadedFilename = "$BaseFolder\normal-V2021Sept7.dotm"
        if (!(Test-Path $DownloadedFilename -PathType Leaf)) {
            Write-Host "Downloading the new Template file"
            Download-File $URL $DownloadedFilename
        }
        
        $TemplatesFolder = "$env:APPDATA\Microsoft\Templates"
        $BackupFilename = "$BaseFolder\normal.dotm.backup"

        # Only Backup the old normal.dotm if a backup doesn't already exist
        if (!(Test-Path $BackupFilename -PathType Leaf)) {
            Write-Host "Backing up the old template"
            Copy-Item -Path "$TemplatesFolder\normal.dotm" -Destination $BackupFilename -Force
        }

        Write-Host "Moving new Template file to the Templates folder"
        Copy-Item -Path $DownloadedFilename -Destination "$TemplatesFolder\normal.dotm" -Force

        Write-Host "Complete."
    }
    else {
        Write-Host "This script must run as the Logged in User not SYSTEM. Nothing installed."
    }
} catch {
    Write-Host "Fatal Exception:[$_.Exception.Message]"
}