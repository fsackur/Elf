#requires -Modules PoshSecret, PoshRSJob

. $PSScriptRoot\Get-LoggerObject.ps1
. $PSScriptRoot\..\Mock\Get-ScriptFromLibrary.ps1
. $PSScriptRoot\..\Mock\Get-DeviceInfo.ps1
. $PSScriptRoot\Get-RunObject.ps1

$Global:Logger = Get-LoggerObject


function Run-Elf {
    
    [CmdletBinding()]
    param(
        #IDs of devices to look up in DB of IP and credential info
        [string[]]$DeviceID = 'localhost',

        #What script you want to run
        [string]$Script = 'Write-Output "You invoked, sir?"',

        #Exposes Log() method
        [psobject]$Logger = $Global:Logger
    )
    
    $Logger.Log(
        $null, 
        'Information', 
        "Starting Elf: {0}" -f $ScriptName
    )

    #Query DB for IPs and credentials for target computers
    $ConnectionInfos = Get-DeviceInfo -DeviceID $DeviceID   #Mock!

    $ConnectionInfos | Start-RSJob -ScriptBlock {
        Write-Output $_.ComputerName
        Write-Output $_.Credential
        iex $using:Script

    } | Wait-RSJob | Receive-RSJob

}


Run-Elf