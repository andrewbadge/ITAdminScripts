<#
.SYNOPSIS
    Check if users are member of the local Administrator groups
.DESCRIPTION
    Checks each user that is enabled and a member of the local administrator group
.INPUTS
    AdminToIgnore (String) = the username of the Local Admin to ignore. It will not be returned as an output even if detected 
.OUTPUTS
    Returns blank for no others users
    Otherwise Returns a list of usernames with suffixes
        (Local) where its a local account
        (AD or AAD) where its not a local account
.NOTES
    File Name      : Local-Accounts-CheckForOtherAdmins.ps1
    Author         : Andrew Badge
    Prerequisite   : PowerShell 5.1 
.EXAMPLE
    CheckForOtherAdmins "myAdminToExclude"
.LINK
#>

function CheckForOtherAdmins {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AdminToIgnore
    )
    try {
        $localadmins = @()
        $members = net localgroup administrators | Select-Object -skip 6 | Select-Object -skiplast 2 
        Foreach ($member in $members)
        {
                #Find the local user. If empty then the user is not local (AD or AAD?)
                $localadmin = Get-LocalUser | Where-Object {$_.Name -eq $member}
                
                #If Empty then not a local Account
                if ($localadmin)
                {
                    if ($localadmin.Enabled -eq $true)
                    {   
                        #Skip the defined Local Admin
                        if ($member -ne $AdminToIgnore)
                        {
                            #Skip the Essentials Server Built in Admin 
                            if ($member -ne "MediaAdmin$")
                            {
                                if ($member.EndsWith("`\Domain Admins") -eq $false)
                                {
                                    $localadmins += $member + " (Local)"
                                }
                            }
                        }
                    }
                }
                else
                {
                    if ($member.EndsWith("`\Domain Admins") -eq $false)
                    {
                        #Skip the Local Admin Group (assuming there is one
                        if ($member.EndsWith("`\Desktop Local Admins") -eq $false)
                        {
                            $localadmins += $member + " (AD or AAD)"
                        }
                    }
                }
        }
        ($localadmins | Group-Object | Select-Object -ExpandProperty Name) -join ","
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}
