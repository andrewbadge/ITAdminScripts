<#
.SYNOPSIS
    Disable the SMB1 protocol on a Windows machine
.DESCRIPTION
    Used to disable SMBv1, this should be ran on demand or immediately in most case to assure SMBv1 is disabled
.NOTES
    File Name      : Disable-SMB1.ps1
    Author         : Andrew Badge
    Prerequisite   : Server 2008 R2, Windows 8 or later
.LINK   
#>

function Disable-SMB1 {
    try {
        Write-Host "Disabling SMB1"
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" SMB1 -Type DWORD -Value 0 -Force
        Write-Host "Complete"
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}
