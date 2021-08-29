<#
.SYNOPSIS
    Finds user in the Retired OU that are disabled and clears the Manager
.DESCRIPTION
    Clears the manager so the Org chart on Delves or Teams doesn't include disabled users.
.INPUTS
    
.OUTPUTS
    Debug Information only
.NOTES
    File Name      : Clear-AD-ManagerForAllUsersInOU.ps1
    Author         : Andrew Badge
    Prerequisite   : PowerShell 5.1 
#>

#Find users in the Retired OU that are disabled
$OUpath = 'ou=Retired Users,dc=orgname,dc=com,dc=au'
$adusers = Get-ADUser -Filter * -SearchBase $OUpath -Property Enabled, Title, Manager | Where-Object {$_.Enabled -like “false”} 

#Clear the manager for disabled users in that OU
Foreach ($user in $adusers)
{
    if (![string]::IsNullOrEmpty($user.Manager))
    {
        Write-Host (-join("Clearing manager for ",$user.Name))
        $user | Set-ADUser -manager $null
    }
}
