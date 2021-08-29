<#
.SYNOPSIS
   Disable the Local Account specified
.DESCRIPTION
    
.INPUTS
    [string] $Username
.OUTPUTS
    Debug Console information only
.NOTES
    File Name      : Disable-Windows-LocalAccount.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1    
.EXAMPLE
    Disable-LocalAccount "OldAccountName"
#>
function Disable-LocalAccount {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Username
    )    

    try {
        if ($Username) {
            Disable-LocalUser -Name $Username
        } else {
            Write-Host "Username is blank"
        }
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}
