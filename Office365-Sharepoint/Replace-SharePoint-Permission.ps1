<#
.SYNOPSIS
   Goes through all the site, subsites and libraries and adds a new group with permissions to match the existing permissions of an old group
.DESCRIPTION
    A popup will prompt for credentials.Ensure you login with an Admin account that has Full rights to your SharePoint site.

.INPUTS
    [String] $SiteUrl (Root site to Process)
    [String] $OldUserName1 (Copies the permissions if the old username has permissions)
    [String] $OldUserName2 (Copies the permissions if the old username has permissions)
    [String] $NewUserName (Username to create with the copied permissions)

    [String] $Logfile (ensure the folder listed exists)
.NOTES
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1
#>

# Important settings
# Duplicates the OldUsername permissions to the New Username Permissions
# For the SiteURL and its SubSites and Libraries
$SiteURL ="https://YourOrg.sharepoint.com/sites/YourSite/YourSubsite"
# Change with your Group names (AD or SharePoint)
$OldUserName1 = "Old Group A"
$OldUserName2 = "Old Group B"
$NewUserName = "Replace with thgis Group"

# Folder will be created if missing
# Used to store Resume file and Logs
$DataFolder = "C:\Temp\"

$DateString = (Get-Date).ToString("yyyyMMddHhmmss")
$Logfile = Join-Path $DataFolder "SharePointPermissionUpdate$DateString.log"
$SiteLogfile = Join-Path $DataFolder "SharePointPermissionSites.log"

[string[]]$global:SiteExclusionList = @()

# Toggle whether Progress resumed each run after the last Site and Library you completed
# Useful for very large SharePoint sites
[bool]$global:ResumeProgress = $True

# Toggle what objects are checked
[bool]$global:ProcessLibraries = $True
#NB: you must process Libraries if you want to process Folders or Files
[bool]$global:ProcessFolders = $True
[bool]$global:ProcessFiles = $True

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

#endregion

#region Site functions

Function Test-AllSites{
    param (
        $oldUsername1,
        $oldUsername2,
        $newUsername
    )
    try {
        Write-Progress -Activity "Getting the Site list" -Status "This can take a while"

        #Get All Site collections - Exclude: Seach Center, Redirect sites, Mysite Host, App Catalog, Content Type Hub, eDiscovery and Bot Sites
        $AllSites = Get-PnPSubWeb -Recurse -IncludeRootWeb

        #Loop through each site collection
        ForEach($Site in $AllSites)
        {
            Try {

                If (!$global:SiteExclusionList.Contains($Site.URL)) {
                    #LogWrite "Site To be processed $($Site.URL)" Green
                    Test-Site $Site.URL $oldUsername1 $oldUsername2 $newUserName
                }
                else {
                    #LogWrite "Site Excluded $($Site.URL)" Gray
                }
            }
            Catch {
                write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
            }
        }
    }
    catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

Function Test-SiteRoleAssignmentExists{
    param (
        $roleAssignments,
        $newUsername
    )

    [bool]$assignmentExists = $False 

    try {
        
        foreach($siteRole in $roleAssignments) {
            Get-PnPProperty -ClientObject $siteRole -Property RoleDefinitionBindings, Member
                
            $PermissionType = $siteRole.Member.PrincipalType     
            $PermissionLevels = $siteRole.RoleDefinitionBindings | Select -ExpandProperty Name
            
            If ($PermissionLevels.Length -eq 0) { Continue } 

            If ($PermissionType -eq "SecurityGroup") {
                
                If (($siteRole.Member.Title -eq $newUsername) -and ($PermissionLevels -ne "Limited Access") -and ($PermissionLevels -ne "Web-Only Limited Access") -and ($PermissionLevels -ne "Limited Access, Web-Only Limited Access"))
                {
                    $assignmentExists = $True 
                }
            }  
        }   
    }
    catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
    return $assignmentExists
}


Function Test-Site{
    param (
        $processSiteURL,
        $oldUsername1,
        $oldUsername2,
        $newUsername
    )

    try {
        
        Write-Progress -Activity "Processing Site:"$processSiteURL

        #Connect to the site
        Connect-PnPOnline -Url $processSiteURL -Interactive

        $siteObject = Get-PnPWeb -Includes HasUniqueRoleAssignments,RoleAssignments
        If($siteObject.HasUniqueRoleAssignments)
        {
            If ($siteObject.RoleAssignments.Length -eq 0) { 
                LogWrite "Site role assigments for: $($processSiteURL) [$($List.Title)] are empty" Red
            } 

            If (Test-SiteRoleAssignmentExists $siteObject.RoleAssignments $newUsername)
            {
                LogWrite "Site: $($processSiteURL) permissions already exist" Yellow
            }
            else {
                
                [bool]$usersFound = $false
                [int]$validPermissionCount = 0

                foreach($siteRole in $siteObject.RoleAssignments) {
                    Get-PnPProperty -ClientObject $siteRole -Property RoleDefinitionBindings, Member
                        
                    $PermissionType = $siteRole.Member.PrincipalType     
                    $PermissionLevels = $siteRole.RoleDefinitionBindings | Select -ExpandProperty Name

                    If ($PermissionLevels.Length -eq 0) { 
                        LogWrite "Site: $($processSiteURL) permissions are empty" Red
                    } 
                    else
                    {
                        If (($PermissionLevels -ne "Limited Access") -and ($PermissionLevels -ne "Web-Only Limited Access") -and ($PermissionLevels -ne "Limited Access, Web-Only Limited Access"))
                        {
                            $validPermissionCount++
                            #Debug
                            #LogWrite "Site: $($processSiteURL) Role: $($siteRole.Member.Title) Level: $($PermissionLevels)" White
                            
                            
                
                            If (($siteRole.Member.Title -eq $oldUsername1) -or ($siteRole.Member.Title -eq $oldUsername2))
                            {
                                $usersFound = $true

                                If ($PermissionType -eq "SharePointGroup") {
                                    LogWrite "Site permission for: $($processSiteURL) was a SharePoint group. Review." Red
                                }

                                [bool]$permissionSet = $false
                                [string]$newPermission = ""

                                $newPermission = "Contribute but not Delete"
                                If ($PermissionLevels.Contains($newPermission) -and ($permissionSet -eq $false)) {
                                    LogWrite "Fixing Site permission for: $($processSiteURL) with $($newPermission) permissions" Green
                                    Set-PnPWebPermission -User $newUsername -AddRole $newPermission
                                }

                                $newPermission = "Contribute"
                                If ($PermissionLevels.Contains($newPermission) -and ($permissionSet -eq $false)) {
                                    LogWrite "Fixing Site permission for: $($processSiteURL) with $($newPermission) permissions" Green
                                    Set-PnPWebPermission -User $newUsername -AddRole $newPermission
                                }

                                $newPermission = "Read"
                                If ($PermissionLevels.Contains($newPermission) -and ($permissionSet -eq $false)) {
                                    LogWrite "Fixing Site permission for: $($processSiteURL) with $($newPermission) permissions" Green
                                    Set-PnPWebPermission -User $newUsername -AddRole $newPermission
                                }

                                If ($permissionSet -eq $false) {
                                    LogWrite "Site: $($processSiteURL) has other permissions $($PermissionLevels)" Red
                                }
                            }
                        }
                    }
                }

                If ($usersFound -eq $false) {
                    LogWrite "Site: $($processSiteURL) old users didn't have permission" Red
                }

                If ($validPermissionCount -eq 0) {
                    LogWrite "  Fixing Site permission for: $($processSiteURL). No valid permissions. Reset to Inherit" Green
                    $Context = Get-PnPContext
                    $siteObject.ResetRoleInheritance()
                    $siteObject.update()
                    $Context.ExecuteQuery()
                    $permissionSet = $True
                }
            }
            
        } else {
            LogWrite "Site: $($processSiteURL) has inherited permissions" Gray
        }
 
        If ($global:ProcessLibraries -eq $True) 
        {
            #Get all document libraries from the site
            $DocumentLibraries = Get-PnPList -Includes HasUniqueRoleAssignments, RoleAssignments | Where-Object {$_.BaseType -eq "DocumentLibrary" -and $_.Hidden -eq $False}
            
            #Iterate through document libraries
            ForEach ($List in $DocumentLibraries)
            {
                $SiteAndLibrary = "$($processSiteURL),$($List.Title)"
                If (!$global:SiteExclusionList.Contains($SiteAndLibrary)) {

                    If ($List.RoleAssignments.Length -eq 0) { 
                        LogWrite "  Library role assigments for: $($processSiteURL) [$($List.Title)] are empty" Red
                    } 

                    If($List.HasUniqueRoleAssignments)
                    {
                        If (Test-LibraryRoleAssignmentExists $List.RoleAssignments $newUsername)
                        {
                            LogWrite "  Library: $($processSiteURL)  [$($List.Title)] permissions already exist" Yellow
                        }
                        else
                        {
                            [bool]$usersFound = $false
                            [int]$validPermissionCount = 0

                            Foreach ($RoleAssignment in $List.RoleAssignments) {                
                                Get-PnPProperty -ClientObject $RoleAssignment -Property RoleDefinitionBindings, Member
                                
                                $PermissionType = $RoleAssignment.Member.PrincipalType     
                                $PermissionLevels = $RoleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name

                                #Debug
                                #LogWrite "   Library: $($processSiteURL) [$($List.Title)] Role: $($RoleAssignment.Member.Title) Level: $($PermissionLevels)" White

                                
                                
                                If ($PermissionLevels.Length -eq 0) { 
                                    LogWrite "  Library permission for: $($processSiteURL) [$($List.Title)] are empty" Red
                                }
                                else
                                { 
                                    If (($PermissionLevels -ne "Limited Access") -and ($PermissionLevels -ne "Web-Only Limited Access") -and ($PermissionLevels -ne "Limited Access, Web-Only Limited Access"))
                                    {
                                        $validPermissionCount++

                                        If (($RoleAssignment.Member.Title -eq $oldUsername1) -or ($RoleAssignment.Member.Title -eq $oldUsername2))
                                        {
                                            $usersFound = $true

                                            If ($PermissionType -eq "SharePointGroup") {
                                                LogWrite "  Library permission for: $($processSiteURL) [$($List.Title)] was a SharePoint group" Red
                                            }

                                            [bool]$permissionSet = $false
                                            [string]$newPermission = ""

                                            $newPermission = "Contribute but not Delete"
                                            If ($PermissionLevels.Contains($newPermission) -and ($permissionSet -eq $false)) {
                                                LogWrite "  Fixing Library permission for: $($processSiteURL) [$($List.Title)]  with $($newPermission) permissions" Green
                                                Set-LibraryRole $list.Title $newUsername $newPermission
                                            }

                                            $newPermission = "Contribute"
                                            If ($PermissionLevels.Contains($newPermission) -and ($permissionSet -eq $false)) {
                                                LogWrite "  Fixing Library permission for: $($processSiteURL) [$($List.Title)]  with $($newPermission) permissions" Green
                                                Set-LibraryRole $list.Title $newUsername $newPermission
                                            }

                                            $newPermission = "Read"
                                            If ($PermissionLevels.Contains($newPermission) -and ($permissionSet -eq $false)) {
                                                LogWrite "  Fixing Library permission for: $($processSiteURL) [$($List.Title)]  with $($newPermission) permissions" Green
                                                Set-LibraryRole $list.Title $newUsername $newPermission
                                            }

                                            If ($permissionSet -eq $false) {
                                                LogWrite "  Library: $($processSiteURL) [$($List.Title)] has other permissions $($PermissionLevels)" Red
                                            }   
                                        }
                                    }
                                }
                                                            
                            }   

                            If ($usersFound -eq $false) {
                                LogWrite "  Library: $($processSiteURL) [$($List.Title)] old users didn't have permission" Red
                            }

                            If ($validPermissionCount -eq 0) {
                                LogWrite "  Fixing Library permission for: $($processSiteURL) [$($List.Title)]. No valid permissions. Reset to Inherit" Green
                                #Set-PnPListPermission -Identity $($List.Title) -InheritPermissions
                                $Context = Get-PnPContext
                                $List.ResetRoleInheritance()
                                $List.update()
                                $Context.ExecuteQuery()
                                $permissionSet = $True
                            }
                        }
                    } else {
                        LogWrite "  Library: $($processSiteURL) [$($List.Title)] has inherited permissions" Gray
                    }

                    # Process all folders
                    If ($global:ProcessFolders -eq $True) {
                        Test-LibraryFolders $List $oldUsername1 $oldUsername2 $newUsername
                    }

                    # Process all files
                    If ($global:ProcessFiles -eq $True) {
                        Test-LibraryFiles $List $oldUsername1 $oldUsername2 $newUsername
                    }

                    # Save progress that site and library is complete
                    SiteLogWrite $SiteAndLibrary
                }
            }
        }

        # Save progress that site and all libraries are complete
        SiteLogWrite $processSiteURL

    }
    catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

#endregion

#region Library functions

Function Test-LibraryRoleAssignmentExists{
    param (
        $roleAssignments,
        $newUsername
    )

    [bool]$assignmentExists = $False 

    try {
        
        Foreach ($RoleAssignment in $List.RoleAssignments) {                
            Get-PnPProperty -ClientObject $RoleAssignment -Property RoleDefinitionBindings, Member
                
            $PermissionType = $RoleAssignment.Member.PrincipalType     
            $PermissionLevels = $RoleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name
            
            If ($PermissionLevels.Length -eq 0) { Continue } 

            If ($PermissionType -eq "SecurityGroup") {
                
                If (($RoleAssignment.Member.Title -eq $newUsername) -and ($PermissionLevels -ne "Limited Access") -and ($PermissionLevels -ne "Web-Only Limited Access") -and ($PermissionLevels -ne "Limited Access, Web-Only Limited Access"))
                {
                    $assignmentExists = $True 
                }
            }                            
        }   
    }
    catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
    return $assignmentExists
}

Function Set-LibraryRole{
    param (
        $listTitle,
        $userName,
        $permissionLevel
    )

    try {
        Set-PnPListPermission -Identity $listTitle -User $userName -AddRole $permissionLevel
    }
    catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

#endregion

#region Folder Functions

Function Test-LibraryFolders{
    param (
        $library,
        $oldUsername1,
        $oldUsername2,
        $newUsername
    )

    [bool]$oldUserExists = $False 
    [bool]$newUserExists = $False 
    [string]$olduserPermissionLevel = ""

    try {
        
        Write-Progress -Activity "Processing Folders in Library:[$($library.Title)]" -Status "Getting the list of folders..."

        $FolderObjects = Get-PnPListItem -List $library -PageSize 500 | Where {$_.FileSystemObjectType -eq "Folder"}
        $FolderCount = $FolderObjects.Length
        $FolderIndex = 1
  
        #Loop through all documents
        ForEach($FolderObject in $FolderObjects)
        {
            $progressPercent = ($FolderIndex/$FolderCount)*100
            Write-Progress -Activity "Processing Folder in Library:[$($library.Title)]" -Status $($FolderObject["FileRef"]) -PercentComplete $progressPercent

            $oldUserExists = $False 
            $newUserExists = $False 

            $folder = Get-PnPFolder -Url $FolderObject["FileRef"] -Includes ListItemAllFields.HasUniqueRoleAssignments, ListItemAllFields.RoleAssignments
            #Get-PnPProperty -ClientObject $folder -Property ListItemAllFields.HasUniqueRoleAssignments, ListItemAllFields.RoleAssignments

            #Only do anything if not Inheritted
            if($folder.ListItemAllFields.HasUniqueRoleAssignments -eq $True) 
            {
                [int]$validPermissionCount = 0
                LogWrite "     Folder: [$($FolderObject["FileRef"])] has unique permissions" Yellow

                #Check for Existing Permissions
                foreach($RoleAssignment in $folder.ListItemAllFields.RoleAssignments )  
                {
                    Get-PnPProperty -ClientObject $RoleAssignment -Property RoleDefinitionBindings, Member
                        
                    #$PermissionType = $RoleAssignment.Member.PrincipalType     
                    $PermissionLevels = $RoleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name

                    #Ignore Limtied access permissions
                    If (($PermissionLevels -ne "Limited Access") -and ($PermissionLevels -ne "Web-Only Limited Access") -and ($PermissionLevels -ne "Limited Access, Web-Only Limited Access"))
                    {
                        $validPermissionCount++

                        If (($RoleAssignment.Member.Title -eq $newUsername))
                        {
                            $newUserExists = $true
                        }

                        If (($RoleAssignment.Member.Title -eq $oldUsername1))
                        {
                            $oldUserExists = $true
                            $olduserPermissionLevel = $PermissionLevels
                        }
                    }
                }

                [bool]$permissionSet = $false
                If (($newUserExists -eq $False) -and ($oldUserExists -eq $True))
                {
                    [string]$newPermission = ""

                    $newPermission = "Contribute but not Delete"
                    If ($olduserPermissionLevel.Contains($newPermission) -and ($permissionSet -eq $false)) {
                        LogWrite "     Folder: [$($FolderObject["FileRef"])] permissions set to $($newPermission)" Green
                        Set-PnPFolderPermission -List $library.Title -Identity $FolderObject["FileRef"] -User $newUsername -AddRole $newPermission
                        $permissionSet = $True
                    }

                    $newPermission = "Contribute"
                    If ($olduserPermissionLevel.Contains($newPermission) -and ($permissionSet -eq $false)) {
                        LogWrite "     Folder: [$($FolderObject["FileRef"])] permissions set to $($newPermission)" Green
                        Set-PnPFolderPermission -List $library.Title -Identity $FolderObject["FileRef"] -User $newUsername -AddRole $newPermission
                        $permissionSet = $True
                    }

                    $newPermission = "Read"
                    If ($olduserPermissionLevel.Contains($newPermission) -and ($permissionSet -eq $false)) {
                        LogWrite "     Folder: [$($FolderObject["FileRef"])] permissions set to $($newPermission)" Green
                        Set-PnPFolderPermission -List $library.Title -Identity $FolderObject["FileRef"] -User $newUsername -AddRole $newPermission
                        $permissionSet = $True
                    }

                    If ($permissionSet -eq $false) {
                        LogWrite "     Folder: [$($FolderObject["FileRef"])] has other permissions $($olduserPermissionLevel)" Red
                    }
                }

                #Fix permissions where they are empty. Reset to Inherit
                If (($validPermissionCount -eq 0) -and ($permissionSet -eq $false)) {
                    LogWrite "     Folder: [$($FolderObject["FileRef"])] No valid permissions. Reset to Inherit." Green
                    Set-PnPFolderPermission -List $library.Title -Identity $FolderObject["FileRef"]  -InheritPermissions
                    $permissionSet = $True
                }

            }
            else {
                #LogWrite "     Folder: [$($FolderObject["Title"])] has inherited permissions" Green
            }


            $FolderIndex++
        }
        
    }
    catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
    return $assignmentExists
}

#endregion

#region File Functions

Function Test-LibraryFiles{
    param (
        $library,
        $oldUsername1,
        $oldUsername2,
        $newUsername
    )

    [bool]$oldUserExists = $False 
    [bool]$newUserExists = $False 
    [string]$olduserPermissionLevel = ""

    try {
        
        Write-Progress -Activity "Processing Files in Library:[$($library.Title)]" -Status "Getting the list of files..."

        $DocumentItems = Get-PnPListItem -List $library -PageSize 500 | Where {$_.FileSystemObjectType -eq "File"}
        $DocumentCount = $DocumentItems.Length
        $DocumentNumber = 1
  
        #Loop through all documents
        ForEach($DocumentItem in $DocumentItems)
        {
            $progressPercent = ($DocumentNumber/$DocumentCount)*100
            Write-Progress -Activity "Processing Files in Library:[$($library.Title)]" -Status $($DocumentItem["FileRef"]) -PercentComplete $progressPercent

            $oldUserExists = $False 
            $newUserExists = $False 

            $file = Get-PnPFile -Url $DocumentItem["FileRef"] -AsListItem
            Get-PnPProperty -ClientObject $file -Property HasUniqueRoleAssignments, RoleAssignments

            #Only do anything if not Inheritted
            if($file.HasUniqueRoleAssignments -eq $True) 
            {
                [int]$validPermissionCount = 0
                LogWrite "     File: [$($DocumentItem["FileRef"])] has unique permissions" Yellow

                #Check for Existing Permissions
                foreach($RoleAssignment in $file.RoleAssignments )  
                {
                    Get-PnPProperty -ClientObject $RoleAssignment -Property RoleDefinitionBindings, Member
                        
                    #$PermissionType = $RoleAssignment.Member.PrincipalType     
                    $PermissionLevels = $RoleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name

                    #Ignore Limtied access permissions
                    If (($PermissionLevels -ne "Limited Access") -and ($PermissionLevels -ne "Web-Only Limited Access") -and ($PermissionLevels -ne "Limited Access, Web-Only Limited Access"))
                    {
                        $validPermissionCount++

                        If (($RoleAssignment.Member.Title -eq $newUsername))
                        {
                            $newUserExists = $true
                        }

                        If (($RoleAssignment.Member.Title -eq $oldUsername1))
                        {
                            $oldUserExists = $true
                            $olduserPermissionLevel = $PermissionLevels
                        }
                    }
                }

                [bool]$permissionSet = $false
                If (($newUserExists -eq $False) -and ($oldUserExists -eq $True))
                {
                    [string]$newPermission = ""

                    $newPermission = "Contribute but not Delete"
                    If ($olduserPermissionLevel.Contains($newPermission) -and ($permissionSet -eq $false)) {
                        LogWrite "     File: [$($DocumentItem["FileRef"])] permissions set to $($newPermission)" Green
                        Set-PnPListItemPermission -List $library -Identity $file -User $newUsername -AddRole $newPermission
                        $permissionSet = $True
                    }

                    $newPermission = "Contribute"
                    If ($olduserPermissionLevel.Contains($newPermission) -and ($permissionSet -eq $false)) {
                        LogWrite "     File: [$($DocumentItem["FileRef"])] permissions set to $($newPermission)" Green
                        Set-PnPListItemPermission -List $library -Identity $file -User $newUsername -AddRole $newPermission
                        $permissionSet = $True
                    }

                    $newPermission = "Read"
                    If ($olduserPermissionLevel.Contains($newPermission) -and ($permissionSet -eq $false)) {
                        LogWrite "     File: [$($DocumentItem["FileRef"])] permissions set to $($newPermission)" Green
                        Set-PnPListItemPermission -List $library -Identity $file -User $newUsername -AddRole $newPermission
                        $permissionSet = $True
                    }

                    If ($permissionSet -eq $false) {
                        LogWrite "     File: [$($DocumentItem["FileRef"])] has other permissions $($olduserPermissionLevel)" Red
                    }
                }

                #Fix permissions where they are empty. Reset to Inherit
                If (($validPermissionCount -eq 0) -and ($permissionSet -eq $false)) {
                    LogWrite "     File: [$($DocumentItem["FileRef"])] No valid permissions. Reset to Inherit." Green
                    Set-PnPListItemPermission -List $library -Identity $file -InheritPermissions
                    $permissionSet = $True
                }

            }
            else {
                #LogWrite "     File: [$($DocumentItem["Title"])] has inherited permissions" Green
            }


            $DocumentNumber++
        }
        
    }
    catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
    return $assignmentExists
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
Test-AllSites $OldUserName1 $OldUserName2 $NewUserName

Write-Progress -Completed -Activity " "
LogWrite "-----Script Complete" Green
SiteLogWrite "-----Script Complete $($DateString)"