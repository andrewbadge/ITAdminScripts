<#
.SYNOPSIS
    Lists all missing Windows Updates
.DESCRIPTION
    Lists missing updates as a table
.OUTPUTS
    Returns a table of updates including the Title, whether its downloaded, hidden etc
.NOTES
    File Name      : Get-Windows-MissingUpdates.ps1
    Author         : Andrew Badge
    Prerequisite   : PowerShell 5.1 
.EXAMPLE
    Get-MissingUpdates
.LINK
#>

function Get-MissingUpdates {
    try {
        #List all missing updates
        Write-Output "Creating Microsoft.Update.Session COM object" 
        $session1 = New-Object -ComObject Microsoft.Update.Session -ErrorAction silentlycontinue

        Write-Output "Creating Update searcher" 
        $searcher = $session1.CreateUpdateSearcher()

        Write-Output "Searching for missing updates..." 
        $result = $searcher.Search("IsInstalled=0")

        #Updates are waiting to be installed 
        $updates = $result.Updates;

        Write-Output "Found $($updates.Count) updates!" 
        $updates | Format-Table Title, AutoSelectOnWebSites, IsDownloaded, IsHiden, IsInstalled, IsMandatory, IsPresent, AutoSelection, AutoDownload -AutoSize
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

