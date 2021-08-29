<#
.SYNOPSIS
    Prefixes the words "Former - " in the title for all users in a OU
.DESCRIPTION
    Intended to update old users. If their title was "Marketing Manager" and they are a retirned user update the title to "Former - Marketing Manager".
    Useful for new users if an old user is referred to in a permission, conversation or reference.
.INPUTS
    
.OUTPUTS
    Debug Information only
.NOTES
    File Name      : Update-AD-TitleForAllUsersInOU.ps1
    Author         : Andrew Badge
    Prerequisite   : PowerShell 5.1 
#>

#Find users in the Retired OU that are disabled
#Change the Path to suit
$OUpath = 'ou=Retired Users,dc=domainname,dc=com,dc=au'
$adusers = Get-ADUser -Filter * -SearchBase $OUpath -Property Enabled, Title, Manager | Where-Object {$_.Enabled -like “false”} 

#Add the word Former in the title for disabled users in that OU
Foreach ($user in $adusers)
{
    if (![string]::IsNullOrEmpty($user.Title))
    {
        if (!$user.Title.StartsWith("Former - "))
        {
            Write-Host (-join("Updating title for ",$user.Name))
            $newtitle = -join("Former - ",$user.Title)
            Write-Host $newtitle
            $user | Set-ADUser -Title $newtitle 
        }
    }
}
