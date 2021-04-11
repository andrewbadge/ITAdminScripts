# Using scripts in ConnectWise Automate

## You need an access token
See the [ITGlue doc](https://exigence.itglue.com/1025747/docs/6909008) on how to get a token. This also links to the current read-only token generated for Automate.

## Running PowerShell scripts

See [!EXIMSP Github Example Script] for an example. 
Add two commands to your Automate script:

1. Execute Powershell

    ```
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('Authorization','token REPLACEWITHPERSONALTOKEN')
        $wc.Headers.Add('Accept','application/vnd.github.v3.raw')
        $wc.DownloadString('https://raw.githubusercontent.com/ExigenceIT/ExigenceScripts/main/REPLACEFOLDER/REPLACESCRIPTNAME.ps1') | iex
        FUNCTIONTOCALL PARAMETERS
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
    ```

2. Log the result

3. Check for an Exception. Does the returned value contain "Fatal Exception:"?

![CW Automate Script Block](https://github.com/ExigenceIT/ExigenceScripts/blob/main/Help-and-Usage/CWAutomateScriptExample.png?raw=true)


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

