<#
.SYNOPSIS
   Disables the Windows Quick assst functionality. 
.DESCRIPTION
    Checks to see if Quick assist is enabled using Get-WindowsCapability. If enabled it well then disable it. 
.NOTES
    File Name      : Disable-Quick-Assist.ps1
    Author         : James Maclean
    Prerequisite   : Powershell 5.1
.EXAMPLE 
    Remove-Quickassist
#>


function Remove-Quickassist {
          $Quickassist=(get-WindowsCapability -online -name App.Support.QuickAssist~~~~0.0.1.0 | select-object -ExpandProperty state)
            if ($Quickassist -eq 'Installed') {
                                                Remove-WindowsCapability -online -name App.Support.QuickAssist~~~~0.0.1.0
                                               }
                             }
