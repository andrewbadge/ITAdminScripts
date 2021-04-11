<#
.SYNOPSIS
    Not production Ready. Need Parameters

    This script will create a new AD User account when run on a DC. 
.DESCRIPTION
    A detailed description of the function or script. This keyword can be
    used only once in each topic.
.INPUTS
    Parameters for Inputs for the function
.OUTPUTS
    Return values or outputs of the function
.NOTES
    File Name      : xxxx.ps1
    Author         : Name
    Prerequisite   : List any requirements
.EXAMPLE
    Usage: xxxx
.LINK
    Docmentation or related Control Template
    https://exigence.itglue.com/DOCUMENTEXAMPLE
#>

#Variables for New user 
#Variables that Contain "<>" Need to be defined for the script to run.
$GivenName = "@GivenName@"
$Surname = "@Surname@"
$Company = "@Company@"
$Manager = "@Manager@"
$Department = "@Department@"
$LocalDomain = "@LocalDomain@"
$Title = "@Title@"
$Domain = "@Domain@"

#Automatically generated variables
$FullName = "$GivenName $Surname"
$SamAccountName = "$GivenName.$Surname"
$UserPrincipleName = "$GivenName.$Surname$Domain"
$Path = "CN=Users,DC=$LocalDomain,DC=local"
$AccountPassword = "Welcometo$Company123!"


function New-User {
    try {
        New-ADUser -Name $FullName -GivenName $GivenName -Surname $Surname -SamAccountName $SamAccountName `
          -UserPrincipalName $UserPrincipleName -Path $Path -AccountPassword $AccountPassword -Department $Department -Title $Title `
          -Enabled $true
    }
    catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}
