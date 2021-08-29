<#
.SYNOPSIS
   Create a shortcut for a URL or an Application
.DESCRIPTION
    Use the .URL for websites
    or .LNK for aapplications
.INPUTS
    
.OUTPUTS
    Debug Console information only
.NOTES
    File Name      : Create-Windows-Shortcut.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1    
.EXAMPLE
    Create-Shortcut "https://google.com" "C:\tmp\Google.lnk",""
#>

function Create-Shortcut {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceExe, 
        [Parameter(Mandatory = $true)] 
        [string]$DestinationPath
        
    )    

    try {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($DestinationPath)
        $Shortcut.TargetPath = $SourceExe
        $Shortcut.Save()
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

$BaseFolder = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$ShortcutFilename = "$BaseFolder\MyGoogleURL.URL" 
$URL ="https://google.com.au/"

Create-Shortcut $URL $ShortcutFilename 
