<#
.SYNOPSIS
    Adds or Deletes Microsoft Word and Microsoft Outlook AutoCorrect Entries
.DESCRIPTION
    Modify the Variables below to Add or remove owrd from the AutoCorrect entries
.INPUTS
    None
.OUTPUTS
    Debug Console information only
.NOTES
    File Name      : Manage-Windows-WordAutocorrectEntries.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1    
#>

function Add-AutoCorrect-Entry {
    param (
        [Parameter(Mandatory = $true)]
        [string] $WordToMatch,
        [Parameter(Mandatory = $true)]
        [string] $ReplaceWith
    )    

    try {

        $AlreadyExists = AutoCorrect-Entry-Exists $WordToMatch
        if ($AlreadyExists -eq $FALSE) {
            $word = New-Object -ComObject word.application
            $word.visible = $false
            $entries = $word.AutoCorrect.entries
            $entries.add($WordToMatch,$ReplaceWith) | out-null
            $word.Quit()
            $word = $null
            [gc]::collect()
            [gc]::WaitForPendingFinalizers()
            Write-Host "Word added." 
        }
        else {
            Write-Host "Word already exists." 
        }

    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

function AutoCorrect-Entry-Exists {
    param (
        [Parameter(Mandatory = $true)]
        [string] $WordToMatch
    )    

    try {
        $WordMatched = $FALSE

        $word = New-Object -ComObject word.application
        $word.visible = $false
        $word.AutoCorrect.entries |
        Foreach { 
            if ($_.Name -eq $WordToMatch)
            {
                $WordMatched = $TRUE  
            }
        }
        
        $word.Quit()
        $word = $null
        [gc]::collect()
        [gc]::WaitForPendingFinalizers()


    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }

    return $WordMatched
}

function Delete-AutoCorrect-Entry {
    param (
        [Parameter(Mandatory = $true)]
        [string] $WordToMatch
    )    

    try {
        $WordMatched = $FALSE

        $word = New-Object -ComObject word.application
        $word.visible = $false
        $word.AutoCorrect.entries |
        Foreach { 
            if ($_.Name -eq $WordToMatch)
            {
                Write-Host "Word Found. Deleting."  
                $_.Delete()  
                $WordMatched = $TRUE  
            }
        }
        
        $word.Quit()
        $word = $null
        [gc]::collect()
        [gc]::WaitForPendingFinalizers()

        if ($WordMatched -eq $FALSE)
        {
            Write-Host "Word Not Found"    
        }

    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

# Add the Registered Trademark Symbol to the Company Name
$OldWord = "My Company"
$NewWord = "My Company " + [char]::ConvertFromUtf32(0x000AE)

# Checks if an Entry already exists
# $AlreadyExists = AutoCorrect-Entry-Exists $OldWord
# Write-Host "Aready Exists? $AlreadyExists"

# Adds a word to the entries if it doesn't already exist
Add-AutoCorrect-Entry $OldWord $NewWord

# Deletes a word from the entries
# Delete-AutoCorrect-Entry $OldWord
