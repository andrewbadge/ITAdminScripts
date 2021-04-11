<#
.SYNOPSIS
   Cleans Temporary files, Cached Files and Windows Updates Temp Files
.DESCRIPTION
   
.NOTES
    File Name      : Clear-Windows-DiskandTempFiles.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1
.EXAMPLE 
    Clear-Windows-DiskandTempFiles
#>

function Clear-Windows-DiskandTempFiles {
    try {
        #Internet Cache and Cookies Cleanup section 
        $ErrorActionPreference = "SilentlyContinue"
        #Temp Locations for Google Chrome
        $ChromeTemp = @(
            "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\Cache"
            #Below can be enabled to delete cookies, You will need to ad a comma after the line above and remove the comment before the lines below
            #"C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\Cookies",
            #"C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\Cookies-Journal"
            )
            Write-Host "Clearing Chrome Temp files for all users...."
                Remove-Item $ChromeTemp -force -recurse


        #Temp Locations for Mozilla Firefox
        $FirefoxTemp = @( 
            "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache\*",
            "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache2\*",
            "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*.default-release\cache2\*"
            #Below can be enabled to delete cookies, You will need to ad a comma after the line above and remove the comment before the lines below
            #"C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*.default\cookies.sqlite"
            )
            Write-Host "Clearing Firefox Temp files for all users...."
                Remove-Item $FirefoxTemp -force -recurse

        $InternetExplorerTemp = @(
            "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\*"
            )
            Write-Host "IE Temp files for all users...."
                Remove-Item $InternetExplorerTemp -force -recurse
        #Temp Folder locations, If there is an error it is because a file in the location is in use or the location doesnt exist
        $Tempfolders = @(
            "C:\Windows\Temp\*", 
            "C:\Users\*\Appdata\Local\Temp\*",
            "C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*",
            "$env:SystemRoot\TEMP\*",
            "$env:windir\minidump\*"
            #"$env:windir\Prefetch\"  #Commented out because this can cause programs to take longer to start after until new Prefetch cache is created

            )

            Write-Host "Removing %TEMP%...."
            Write-Host "Removing Appdata Temp Files for all users...."
            Write-Host "Removing Temporary Internet files for all users...."
            Write-Host "Clearing MiniDump Files...."
            #Write-Host "Clearing Prefetch Cache...."
                Remove-Item $tempfolders -force -recurse

        Write-Host "Phase 1 Complete"


        ## Starts cleanmgr.exe


        # Create Cleanmgr profile by setting the check mark options in the registry to create a sageset profile 
        Write-host "Running Windows System Cleanup" -foreground yellow
        #Set StateFlags setting for each item in Windows disk cleanup utility
        $StateFlags = 'StateFlags0013'
        $StateRun = $StateFlags.Substring($StateFlags.get_Length()-2)
        $StateRun = '/sagerun:' + $StateRun 
            if  (-not (get-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders' -name $StateFlags)) {
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Offline Pages Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations' -name $StateFlags -type DWORD -Value 2
                #set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Memory Dump Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files' -name $StateFlags -type DWORD -Value 2
                #set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files' -name $StateFlags -type DWORD -Value 2
                #set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache' -name $StateFlags -type DWORD -Value 2
                #set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Archive Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Queue Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Archive Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Queue Files' -name $StateFlags -type DWORD -Value 2
                set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files' -name $StateFlags -type DWORD -Value 2
            }

        Write-host "Starting CleanMgr.exe.." -foreground yellow
            Start-Process -FilePath CleanMgr.exe -ArgumentList $StateRun  

        #Makes sure the process is still running and not hung at a prompt screen (Click Okay to Exit). 
        #Lets try this where it takes the TotalProcessorTime and waits 30 seconds, then compares against a current TotalProcessorTime.
        #The thinking here is that if the values are the same when it gets compared against itself from 30 seconds prior, then it should be done running
            do {
            Write-Host "Disk Cleanup Utility is still running. Checking again in 30 seconds."
            $cleanmgr = (Get-Process -Name cleanmgr).TotalProcessorTime
            Start-Sleep -Seconds 30
        } Until ($cleanmgr -eq (Get-Process -Name cleanmgr).TotalProcessorTime)
        Stop-Process -Name cleanmgr -Force
        Write-host "The disk cleanup script has finished runnning. Disk cleanup is now complete."
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}