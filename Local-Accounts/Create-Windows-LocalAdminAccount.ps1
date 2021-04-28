<#
.SYNOPSIS
    Creates a new local admin if it doesn't exist
.DESCRIPTION
    Checks that the user doesn't exist then creates.
    the user is a member of the local Administrators group, the password does not expiry and the user cannot change the password.

    NB: use LAPs to manage the account's password
.INPUTS
    [string] $Username          The Username to create
	[string] $Description       The description for the new user
    [securestring] $Password    The password (as a secure string). See the example
.OUTPUTS
    Logging information only
.NOTES
    File Name      : Create-Windows-LocalAdminAccount.ps1
    Author         : Andrew Badge
    Prerequisite   : PowerShell 5.1 
.EXAMPLE
    $NewUsername = "MyNewAdminUsername"
    $Description = "My Admins Description"
    $NewPassword = ConvertTo-SecureString 'NewComplexPassword' –asplaintext –force 
    Create-NewLocalAdmin -Username $NewUsername -Description $Description -Password $NewPassword
.LINK
#>

function Create-NewLocalAdmin {
    param (
        [string] $Username,
		[string] $Description,
        [securestring] $Password
    )    

    try {
        $op = Get-LocalUser | Where-Object {$_.Name -eq "$Username"}
        if ( -not $op) {
			New-LocalUser "$Username" -Password $Password -FullName "$Username" -Description $Description 
			Set-LocalUser -Name "$Username" -UserMayChangePassword $false -PasswordNeverExpires $true 
			Write-Host "$Username local user created"
			Add-LocalGroupMember -Group "Administrators" -Member "$Username"
			Write-Host "$Username added to the local administrator group"
		}
        else {
            Write-Host "$Username already exists"
        }
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}