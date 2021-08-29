<#
.SYNOPSIS
   Checks if an Application is installed
.DESCRIPTION
    
.INPUTS
    [string] $AppName   Full Name of the App to check
.OUTPUTS
    '$AppName' NOT is installed.
    '$AppName' is installed.
.NOTES
    File Name      : Check-Windows-ApplicationIsInstalled.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1
.EXAMPLE 
    Is-Application-Installed "Microsoft Office"
#>

function Is-Application-Installed {
    param (
        [Parameter(Mandatory = $true)]
        [string] $AppName
    )    

    try {

        $installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $AppName }) -ne $null
        If(-Not $installed) {
            $installed = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $AppName }) -ne $null
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
