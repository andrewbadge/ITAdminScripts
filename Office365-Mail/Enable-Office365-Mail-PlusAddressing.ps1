<#
.SYNOPSIS
    Enables Plus addressing for the Office 365 Tenant
.DESCRIPTION
    Enables Plus addressing for the whole tenant. e.g. alias+route@domain.com is delivered to the alias@domain.com mailbox
.NOTES
    File Name      : Enable-Office365-Mail-PlusAddressing.ps1
    Author         : James Maclean
    Prerequisite   : Office 365, Account Credentials with Exchange Administrator role active.
.EXAMPLE 
    Enable-PlusAddressing
#>

#Checks to see if the ExchangeOnlineManagement Module is installed, tries to install it if its not.
function Get-ExchangeOnlineManagement {

if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
    Write-Host "Module exists"
} 
else {
    Write-Host "Module does not exist, now trying to install module"
    Install-Module -Name ExchangeOnlineManagement
    }
}
#Connects to Exchange Online then attempts to Enable plus addressing.
function Enable-PlusAddressing {
    try {
        Get-ExchangeOnlineManagment
        Connect-ExchangeOnline
        Set-OrganizationConfig -AllowPlusAddressInRecipients $true
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
        finally {
            Disconnect-ExchangeOnline
            }
}
