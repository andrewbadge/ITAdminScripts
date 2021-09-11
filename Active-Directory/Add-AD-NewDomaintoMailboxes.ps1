<#
.SYNOPSIS
   Adds a new email alias to all uses in a OU
.DESCRIPTION
    Used when an Org adds a new domain to all users (e.g. in a rebrand)
.INPUTS
    Update the Settings prior to running
        $OldEmailDomain: Domain to check they already have. If it doesn't exist, then nothing will be added
        $NewEmailDomain: New Domain to add
        $SearchBase:  where to search for users in AD. Test by setting to a test OU only
.OUTPUTS
    Debug information only.
    NB: quite a chatty debug. So comment out any info you wdon't want
.NOTES
    File Name      : Add-AD-NewDomainToAllMailboxes.sp1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1
#>

# Update these domains to your new and old email domain names
$OldEmailDomain = "@olddomain.com"
$NewEmailDomain = "@newdomain.com"

# Update this OU to Match your domain
$SearchBase = 'OU=Users OU,DC=mydomain,DC=com'

# Import the ActiveDirectory Module. 
# FYI: If you are running from the ActiveDirectory Powershell shell don't need this 
function Get-Module-ActiveDirectory 
{
    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        Write-Host "Module exists"
    } 
    else 
    {
        Write-Host "Module does not exist, now trying to install module"
        Install-Module -Name ActiveDirectory
    }
    Import-Module ActiveDirectory
}

Get-Module-ActiveDirectory

# Step 1
# Loop all users in the Domain and Add a new Email alias if they 
#   1. have an email address
#   2. have the old email address
# NB: No filter yet as we want to inspect all users

$USERS = Get-ADUser -SearchBase $SearchBase -Filter * -Properties mail,ProxyAddresses 
foreach ($USER in $USERS)
{
    $Username = $USER.SamAccountName
    $Mail = $USER.Mail
    $proxies = $USER.ProxyAddresses

    Write-Output "Processing" $Username 

    if (-not ([string]::IsNullOrEmpty($Mail)))
    {
        if (-not ([string]::IsNullOrEmpty($proxies)))
        {
            if ($Mail -match $OldEmailDomain)
            {
                $NewEmailAddress = $Mail.ToLower() -replace $OldEmailDomain, $NewEmailDomain

                if (($proxies -NotContains "smtp:$NewEmailAddress") -And ($proxies -NotContains "SMTP:$NewEmailAddress"))
                {

                    Write-Output "Adding new address" $NewEmailAddress
                    try {
                        Set-ADUser -Identity $Username -Add @{proxyAddresses = ("smtp:" + $NewEmailAddress)}
                    } catch {
                        Write-Host "Exception:[$_.Exception.Message]"
                    }
                }
                else {
                    Write-Output "Skipping. Email Address already exists for " $Username
                }
            }
            else {
                Write-Output "Skipping. Mail attribute does contain the old domain for " $Username
            }
        }
        else {
            Write-Output "Skipping. No Email addresses for " $Username
        }
    }
    else {
        Write-Output "Skipping. Empty Mail Attribute for " $Username
    }
}

# Step 2
# Loop through each user where they have a New domain's email address and set it primary

$SearchFilter = "ProxyAddresses -like ""SMTP:*$NewEmailDomain"""
Get-ADUser -SearchBase $SearchBase -Filter $SearchFilter -Properties mail,ProxyAddresses |
    Foreach {  
        $proxies = $_.ProxyAddresses | 
            ForEach-Object{
                $a = $_ -replace 'SMTP','smtp'
                if($a -match $NewEmailDomain){
                    $a -replace 'smtp','SMTP'
                }else{
                    $a
                }
            }
        $_.ProxyAddresses = $proxies
        $_.mail = $_.mail -replace $OldEmailDomain, $NewEmailDomain

        Set-ADUser -instance $_
    }


    
