<#
.SYNOPSIS
   Goes through all the site, subsites and libraries and deletes old verisons of files (but not the file itself).
.DESCRIPTION
    A popup will prompt for credentials.Ensure you login with an Admin account that has Full Access right to the SharePoint site.

.INPUTS
    [String] $SiteUrl (Root site to Process)
    [String] $DataFolder (ensure the folder listed exists)

.NOTES
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1

    To Tweak Settings

    ResumeProgress determines whether the script will always process all files and libraries. If $Falso it will progress all even if already processed
    VersionsToKeep (Levels 1-3) determines how many versions are retained for the OnlyFilesOlderThan (Levels 1-3) age of files (based onModified Date)  

    Default Values:
        Files older than 5 Years retain 3 versions    
        Files older than 3 Years retain 10 versions
        Files older than 6 Months retain 50 versions
        otherwise (Newer than 6 Months) retain 75 versions
#>

# Important settings
# Duplicates the OldUsername permissions to the New Username Permissions
# For the SiteURL and its SubSites and Libraries
$SiteURL ="https://YourOrg.sharepoint.com/sites/YourSite/"

# Folder will be created if missing
# Used to store Resume file and Logs
$DataFolder = "C:\Temp\SharePointDeleteOldVersions\"

$DateString = (Get-Date).ToString("yyyyMMddHhmmss")
$Logfile = Join-Path $DataFolder "SharePointDeleteOldVersions$DateString.log"
$SiteLogfile = Join-Path $DataFolder "SharePointDeleteOldVersions.log"
$StorageRecoveredfile = Join-Path $DataFolder "SharePointStorageRecovered.csv"

[string[]]$global:SiteExclusionList = @()

# Toggle whether Progress resumed each run after the last Site and Library you completed
# Useful for very large SharePoint sites
[bool]$global:ResumeProgress = $True

# Toggle whether versions are deleted or just reported
[bool]$global:DeleteVersions = $True

# Number of Versions ot keep based on modified date
# Expect Level 3 to the oldest files with Level 1 the youngest
[int]$global:Default_VersionsToKeep = 75

[int]$global:Level1_VersionsToKeep = 50
[DateTime]$global:Level1_OnlyFilesOlderThan = (Get-Date).AddMonths(-6)

[int]$global:Level2_VersionsToKeep = 10
[DateTime]$global:Level2_OnlyFilesOlderThan = (Get-Date).AddYears(-3)

[int]$global:Level3_VersionsToKeep = 3
[DateTime]$global:Level3_OnlyFilesOlderThan = (Get-Date).AddYears(-5)

# Global Flag if a Rate Limiting exception was thrown
[Bool]$global:RateLimited = $False
[int]$global:RateLimit_RetryAttempts = 3
[int]$global:RateLimit_DelayMinutes = 60

# Load PNP Powershell Module
Import-Module Pnp.Powershell

#region File and Log Functions

Function CreateFolderIfMissing
{
    Param (
    [Parameter(Mandatory=$true)][string]$folderPath
   )

   New-Item -ItemType Directory -Force -Path $folderPath -ErrorAction SilentlyContinue  | Out-Null
}

Function ReadFileAsArray
{
    Param (
    [Parameter(Mandatory=$true)][string]$filePath
   )

   If (Test-Path $filePath) {
    $global:SiteExclusionList = Get-Content -Path $filePath 
   }
}

Function LogWrite
{
   Param (
    [Parameter(Mandatory=$true)][string]$logstring,
    [Parameter(Mandatory=$false)]$foreColour
   )
    If ($null -eq $foreColour) {
        Write-host $logstring
    } else {
        Write-host -ForegroundColor $foreColour $logstring
    }
   
   Add-content $Logfile -value $logstring
}

Function SiteLogWrite
{
   Param (
    [Parameter(Mandatory=$true)][string]$siteurl
   )
    
   Add-content $SiteLogfile -value $siteurl
}

Function StorageRecoveredWrite
{
   Param (
    [Parameter(Mandatory=$true)][string]$storageRecovered
   )
    
   Add-content $StorageRecoveredfile -value $storageRecovered
}

Function IsRateLimitingException
{
   Param (
    [Parameter(Mandatory=$true)][string]$ExceptionMessage
   )
    
   return ($ExceptionMessage -like "*The remote server returned an error: (429)*") 
}

Function RateLimitDelay
{
    Write-Progress -Activity "Rate Limit Delay" -Status "$([math]::Round($global:RateLimit_DelayMinutes,2)) Minutes remaining..."
    [DateTime]$DelayUntil = (Get-Date).AddMinutes($global:RateLimit_DelayMinutes)
    while ($DelayUntil -gt (Get-Date))
    {
        Start-Sleep -Seconds 15

        $DelayRemaining = (Get-Date) - $DelayUntil
        Write-Progress -Activity "Rate Limit Delay" -Status "$(-[math]::Round($DelayRemaining.TotalMinutes,2)) Minutes remaining..."
    }
}


#endregion

#region Site functions

Function Test-AllSites{
    try {
        
        $Attempt = 0
        $AttemptSuccess = $False

        while (($Attempt -lt $global:RateLimit_RetryAttempts) -and ($AttemptSuccess -eq $false))
        {
            $Attempt++
            LogWrite "Attempt $Attempt starting" Green

            $global:RateLimited = $False

            #Get All Site collections - Exclude: Seach Center, Redirect sites, Mysite Host, App Catalog, Content Type Hub, eDiscovery and Bot Sites
            Write-Progress -Activity "Getting the Site list" -Status "This can take a while"
            $AllSites = Get-PnPSubWeb -Recurse -IncludeRootWeb

            #Loop through each site collection
            ForEach($Site in $AllSites)
            {
                try {
                    #Check if Rate Limited
                    If ($global:RateLimited -eq $true) { break }

                    #Chrck the Site wasn't alreayd procssed
                    If (!$global:SiteExclusionList.Contains($Site.URL)) {
                        Test-Site $Site.URL $oldUsername1 $oldUsername2 $newUserName
                    }
                }
                catch {
                    if (IsRateLimitingException $($_.Exception.Message)) {
                        LogWrite "Rate Limited:[$_.Exception.Message]" Red
                        $global:RateLimited = $true
                        break
                    }
                    else {
                        LogWrite "Exception:[$_.Exception.Message]" Red
                    }
                }
            }

            if ($global:RateLimited -eq $true) {
                $AttemptSuccess = $False
                RateLimitDelay
            }
            else {
                $AttemptSuccess = $True
            }
        }
    }
    catch {
        LogWrite "Fatal Exception:[$_.Exception.Message]" Red
    }
}



Function Test-Site{
    param (
        $processSiteURL
    )

    try {
        
        Write-Progress -Activity "Processing Site:"$processSiteURL
        LogWrite  "Processing Site $($processSiteURL)" White

        #Connect to the site
        Connect-PnPOnline -Url $processSiteURL -Interactive

        $siteObject = Get-PnPWeb -Includes HasUniqueRoleAssignments,RoleAssignments
        
        #Get all document libraries from the site
        $DocumentLibraries = Get-PnPList -Includes HasUniqueRoleAssignments, RoleAssignments | Where-Object {$_.BaseType -eq "DocumentLibrary" -and $_.Hidden -eq $False}
            
        #Iterate through document libraries
        ForEach ($List in $DocumentLibraries)
        {
            #Check if Rate Limited
            If ($global:RateLimited -eq $true) { break }

            $SiteAndLibrary = "$($processSiteURL),$($List.Title)"
            If (!$global:SiteExclusionList.Contains($SiteAndLibrary)) {

                # Process all files
                Test-LibraryFiles $processSiteURL $List 

                # Save progress that site and library is complete
                If ($global:RateLimited -eq $False) { SiteLogWrite $SiteAndLibrary }
            }
        }

        # Save progress that site and all libraries are complete
        If ($global:RateLimited -eq $False) { SiteLogWrite $processSiteURL }

    }
    catch {
        if (IsRateLimitingException $($_.Exception.Message)) {
            LogWrite "Rate Limited:[$_.Exception.Message]" Red
            $global:RateLimited = $true
        }
        else {
            LogWrite "Exception:[$_.Exception.Message]" Red
        }
    }
}

#endregion

#region File Functions

Function Test-LibraryFiles{
    param (
        $processSiteURL,
        $library
    )

    try {
        
        Write-Progress -Activity "Processing Files in Library:[$($library.Title)]" -Status "Getting the list of files..."
        LogWrite  "Processing Files in $($processSiteURL) [$($library.Title)]" White

        $Ctx= Get-PnPContext

        $DocumentItems = Get-PnPListItem -List $library -PageSize 500 | Where {$_.FileSystemObjectType -eq "File"}
        $DocumentCount = $DocumentItems.Length
        $DocumentNumber = 1
  
        #Loop through all documents
        ForEach($DocumentItem in $DocumentItems)
        {
            #Check if Rate Limited
            If ($global:RateLimited -eq $true) { break }

            $progressPercent = ($DocumentNumber/$DocumentCount)*100
            Write-Progress -Activity "Processing Files in Library:[$($library.Title)]" -Status $($DocumentItem["FileRef"]) -PercentComplete $progressPercent

            #Determine how many versions to keep based on the Modofied date

            $VersionToKeep = $global:Default_VersionsToKeep

            try {

                if ($DocumentItem["Modified"] -lt $global:Level3_OnlyFilesOlderThan) {
                    $VersionToKeep = $global:Level3_VersionsToKeep
                }
                else {
                    if ($DocumentItem["Modified"] -lt $global:Level2_OnlyFilesOlderThan) {
                        $VersionToKeep = $global:Level2_VersionsToKeep
                    }
                    else {
                        if ($DocumentItem["Modified"] -lt $global:Level1_OnlyFilesOlderThan) {
                            $VersionToKeep = $global:Level1_VersionsToKeep
                        }
                        else {
                            $VersionToKeep = 100
                        }
                    }
                }
                
                #Get File Versions
                $File = $DocumentItem.File
                $Versions = $File.Versions
                $Ctx.Load($File)
                $Ctx.Load($Versions)
                $Ctx.ExecuteQuery()
            
                $VersionsCount = $Versions.Count
                $VersionsToDelete = $VersionsCount - $VersionToKeep
                If($VersionsToDelete -gt 0)
                {
                    LogWrite "`t  $($DocumentItem["FileRef"]): Removing $($VersionsToDelete) of $($VersionsCount)"  Cyan
                    $VersionCounter= 0
                    #Delete versions
                    For($i=0; $i -lt $VersionsToDelete; $i++)
                    {
                        If($Versions[$VersionCounter].IsCurrentVersion)
                        {
                            $VersionCounter++
                            LogWrite  "`t Retaining Current Major Version $($VersionCounter)" Cyan
                            Continue
                        }
                        if ($global:DeleteVersions -eq $true) {
                            #LogWrite  "`t Deleting Version: $($VersionCounter)" Cyan
                            $Versions[$VersionCounter].DeleteObject()
                        }
                        else {
                            #LogWrite  "`t Would have deleted Version: $($VersionCounter)" Cyan
                        }
                    }
                    if ($global:DeleteVersions -eq $true) {
                        $Ctx.ExecuteQuery()

                        # Write the amount of data (in KB) removed
                        #   Bytes/1024 = KB * Number of Versions removed
                        #   Exported as CSV (Site,Library,File,KBRecovered)

                        $KBRecovered = [Math]::Round(($DocumentItem["File_x0020_Size"] / 1024)*$VersionsToDelete,2)
                        StorageRecoveredWrite """$($processSiteURL)"",""$($library.Title)"",""$($DocumentItem["FileRef"])"",$($KBRecovered),$VersionsToDelete"

                        LogWrite  "`t Updated" Cyan
                    }
                    else {
                        LogWrite  "`t No change" Cyan
                    }
                    
                }
            } catch {
                if (IsRateLimitingException $($_.Exception.Message)) {
                    LogWrite "Rate Limited:[$_.Exception.Message]" Red
                    $global:RateLimited = $true
                    break
                }
                else {
                    LogWrite "Exception:[$_.Exception.Message]" Red
                }
            }

            $DocumentNumber++
        }
        
    } catch {
        if (IsRateLimitingException $($_.Exception.Message)) {
            LogWrite "Rate Limited:[$_.Exception.Message]" Red
            $global:RateLimited = $true
        }
        else {
            LogWrite "Exception:[$_.Exception.Message]" Red
        }
    }
}

#endregion

Clear-Host

LogWrite "-----Script Started $($DateString)" Green
SiteLogWrite "-----Script Started $($DateString)"

# Connect to Sharepoint Site
Write-Progress -Activity "Logging in"
Connect-PnPOnline -URL $SiteURL -Interactive

#init folders and read exclusions
CreateFolderIfMissing $DataFolder
If ($global:ResumeProgress) { ReadFileAsArray $SiteLogfile }

#Iterate the sites
Test-AllSites

Write-Progress -Completed -Activity " "
LogWrite "-----Script Complete" Green
SiteLogWrite "-----Script Complete $($DateString)"