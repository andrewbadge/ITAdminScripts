<#
.SYNOPSIS
   Downloads a file from a private GitHub Repo to a local file
.DESCRIPTION
    
.INPUTS
    [string] $GitHubPersonalAccessToken,
    [string] $GitHubFileURL,
    [string] $LocalFileName
.NOTES
    File Name      : Download-GitHub-File.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1
.EXAMPLE 
    $Token = 'token ABC123456789'
    $URL = 'https://raw.githubusercontent.com/Account/REPO/Branch/Path/Filename.txt'
    $File = 'C:\tmp\Filename.txt'
    Download-GitHub-File $Token $URL $File
#>

function Download-GitHub-File {
    param (
        [string] $GitHubPersonalAccessToken,
        [string] $GitHubFileURL,
        [string] $LocalFileName
    )    

    try {
        
        try {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add('Authorization',$GitHubPersonalAccessToken)
            $wc.Headers.Add('Accept','application/vnd.github.v4.raw')
            $wc.DownloadFile($GitHubFileURL,"$LocalFileName")
        } catch {
            Write-Host "Fatal Exception:[$_.Exception.Message]"
        }


    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

