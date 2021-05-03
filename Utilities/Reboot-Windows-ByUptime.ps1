<#
.SYNOPSIS
   Reboots the device if the uptime exceeds the number of days
.DESCRIPTION
    
.INPUTS
    [int] $UptimeInDays         The number of days the device has been running. If the device has been running
                                 for larger than or equal to this the device will reboot.
.NOTES
    File Name      : Reboot-Windows-ByUptime.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1
.EXAMPLE 
    Reboot-Windows-ByUptime 30
#>

function Reboot-Windows-ByUptime {
    param (
        [int] $UptimeInDays
    )    

    try {
        
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}