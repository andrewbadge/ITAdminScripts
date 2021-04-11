# Using scripts in ConnectWise Automate

## You need an access token
Generate a Personal Acess Token from your Develper Account settings in GitHub.
NB: Ideally this should be from a service account with read only access to the repository (not your user account with write access)

## Running PowerShell scripts

Add two commands to your Automate script:

1. Execute Powershell

    ```
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('Authorization','token REPLACEWITHPERSONALTOKEN')
        $wc.Headers.Add('Accept','application/vnd.github.v3.raw')
        $wc.DownloadString('https://raw.githubusercontent.com/REPLACE/REPLACESCRIPTNAME.ps1') | iex
        FUNCTIONTOCALL PARAMETERS
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
    ```

2. Log the result

3. Check for an Exception. Does the returned value contain "Fatal Exception:"?

![CW Automate Script Block](https://github.com//andrewbadge/ITAdminScripts/blob/main/Help-and-Usage/CWAutomateScriptExample.png?raw=true)


## Handling errors

As the code downloads the script from GitHub, common internet issues maybe block access. Noting if they have no internet then the script probably won't start either.

When excuting any code expect; check the output for the string "Exception:".
If this exists then consider the code failed to run. It is suggested you handle this condition at a minimum.

### The remote server returned an error: (404) Not Found. 

If you get this error when downloading the script from GitHub its most likely one of two things:

- The Personal Access Token is incorrect. Check the value is valid.
- The Script path or name is incorrect. Use the "Raw" link in GitHub to compare.

### The remote server returned an error: (403) Forbidden.

If you get this error when downloading the script from GitHub; the GitHub URL could be blocked on the client.
Check Umbrella or whatever URL filtering they use.

