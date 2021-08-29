<#
.SYNOPSIS
   Update the root site and subsites to the logo specified
.DESCRIPTION
    Creds supplied will need to be a site wonerr for all sites
.INPUTS
    [String] $SiteUrl (Root site to Process)
    [String] $LogoURL (Logo Path to Set)
.NOTES
    File Name      : Update-SharePointSiteLogos.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1
    Thanks and Reference: https://www.sharepointdiary.com/2016/11/sharepoint-online-how-to-change-logo-using-powershell.html
#>

#Add PowerShell Module for SharePoint Online
Import-Module Microsoft.Online.SharePoint.Powershell -DisableNameChecking
 
##Configuration variables. Change these to suit
$SiteUrl = "https://orgname.sharepoint.com/sites/sitename"
$LogoURL="/sites/sitename/Style Library/Logos/Logo.png"

$Cred = Get-Credential
$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
 
 
Try {
    
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
    $Ctx.Credentials = $Credentials
 
    #Get the Root web
    $Web = $Ctx.Web
    $Ctx.Load($Web)
    $Ctx.ExecuteQuery()
 
    #Function to change Logo for the given web
    Function Update-Logo($Web)
    {
        try {
            #Update Logo
            $Web.SiteLogoUrl = $LogoURL
            $Web.Update()
            $Ctx.ExecuteQuery()
            Write-host "Updated Logo for Web:" $Web.URL
    
            #Process each subsite in the site
            $Subsites = $Web.Webs
            $Ctx.Load($Subsites)
            $Ctx.ExecuteQuery()        
            Foreach ($SubSite in $Subsites)
            {
                #Call the function Recursively
                Update-Logo($Subsite)
            }
        }
        Catch {
            write-host -f Red "Error updating Logo for " $Web.URL $_.Exception.Message
        }
    }
     
    #Call the function to change the logo of the web
    Update-Logo($Web)
}
Catch {
    write-host -f Red "Error updating Logo!" $_.Exception.Message
}
