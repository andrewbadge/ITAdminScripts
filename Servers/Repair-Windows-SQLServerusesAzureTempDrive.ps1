<#
.SYNOPSIS
   Gives "Everyone" Full Control of an Azure Temporary Drive and ensures the service is started.
   It is intended to be run as a script on server start.
.DESCRIPTION
    If an Azure Server has runs SQL Server and the Azure Temporary drive is used for SQL TempDB
    storage; then the SQL Server service may not start after a reboot as the drive doesn't have permissions (the Temp Drive is recreated on reboot). 
    
    This may occur if the SQL Service account Network Service account and can't write the drive by default.
    This script will give Everyone access and restart the service.
.INPUTS
    [string] $DriveLetter,
    [string] $ServiceName
.OUTPUTS
    Debug Console information only
.NOTES
    File Name      : Repair-Windows-SQLServerusesAzureTempDrive.ps1
    Author         : Andrew Badge
    Prerequisite   : Powershell 5.1    
.EXAMPLE
  $Logfile = "C:\tmp\Repair-Windows-SQLServerusesAzureTempDrive.log"
  $DriveToFix = "D:"
  $ServiceName = "MSSQL`$InstanceName"

  Repair-Windows-SQLServerusesAzureTempDrive $DriveToFix $ServiceName
#>


Function LogWrite
{
   Param ([string]$logstring)

   Write-Host $logstring

   $CurrentDate = Get-Date
   $CurrentDateString =  $CurrentDate.ToString("yyyy-MM-dd HH:mm:ss")

   Add-content $Logfile -value "$CurrentDateString $logstring"
}

function Set-Folder-EveryoneAccess {
    param (
        [String] $Folder
    )    

    try {
        $Acl = Get-Acl $Folder
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl","ContainerInherit, ObjectInherit", "InheritOnly", "Allow")
        $Acl.SetAccessRule($Ar)
        Set-Acl $Folder $Acl

    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

function IsServiceRunning {
    param (
        [String] $ServiceName
    )    

    try {
        $arrService = Get-Service -Name $ServiceName

        return ($arrService.Status -eq 'Running')
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
        return $false
    }
}

function Restart-ServiceIfStopped {
    param (
        [String] $ServiceName
    )    

    try {
        $arrService = Get-Service -Name $ServiceName

        if ($arrService.Status -ne 'Running')
        {

            Start-Service $ServiceName
            LogWrite "Service status is" $arrService.status
            LogWrite 'Service starting'
            Start-Sleep -seconds 60
            $arrService.Refresh()
            if ($arrService.Status -eq 'Running')
            {
                LogWrite 'Service is now running'
            }
            else {
                LogWrite 'Service failed to start'
                Throw 'Service failed to start'
            }
        }
        else {
            LogWrite 'Service is already running'
        }
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}
function Repair-Windows-SQLServerusesAzureTempDrive {
    param (
        [string] $DriveLetter,
        [string] $ServiceName
    )    

    try {

        $ServiceIsRunning = IsServiceRunning $ServiceName
        if (!$ServiceIsRunning)
        {
            Set-Folder-EveryoneAccess $DriveLetter
            Start-Sleep -seconds 20
            Restart-ServiceIfStopped $ServiceName
        }  
        else {
            LogWrite 'Service is already running'
        }      
        
    } catch {
        Write-Host "Fatal Exception:[$_.Exception.Message]"
    }
}

$Logfile = "C:\tmp\Validate-ServiceStartsforTempDrive.log"
$DriveToFix = "D:"
$ServiceName = "MSSQL`$InstanceName"

Repair-Windows-SQLServerusesAzureTempDrive $DriveToFix $ServiceName
