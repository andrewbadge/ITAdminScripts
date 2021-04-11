<#
.SYNOPSIS
   Enables the Windows Quick Assist functionality. 
.DESCRIPTION
   Enables Quick assist using Add-WindowsCapability. When running this script you should remember to disable it afterwards.
.NOTES
    File Name      : Enable-Quick-Assist.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1
.EXAMPLE 
    Add-Quickassist
#>


function Add-Quickassist {
    Add-WindowsCapability -online -name App.Support.QuickAssist~~~~0.0.1.0
}
