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

    #Thread-safe hashtable to hold data for each run
    $Script:Fleet = @{}   #Will be made thread-safe


    #Set up the job objects
    foreach ($ConnectionInfo in $ConnectionInfos) {
        $RunObj = Get-RunObject (
            $Script,
            $Dependencies,
            $ConnectionInfo
        )
        $Fleet.Add($RunObj.RS.InstanceId.Guid, $RunObj)
    }

    foreach  ($Kvp in $Fleet.GetEnumerator()) {
        #Set up the callback on the powershell changing state
        $null = Register-ObjectEvent -InputObject $Kvp.Value.PS -EventName 'InvocationStateChanged' -Action $ElfPsCallback
        #Start the run in a new thread
        $Kvp.Value.BeginInvoke()
    }

}

$ElfPsCallback = {
    Write-Host 'In callback'
    $RunspaceID = $event.Sender.Runspace.InstanceId.Guid

    $Logger.Log(
        $RunspaceID.Substring(0, 8),
        'Information',
        "PS state {0}" -f $Eventargs.InvocationStateInfo.State
    )

    if ($Eventargs.InvocationStateInfo.State -eq [System.Management.Automation.PSInvocationState]::Completed) {
        $Return = $Fleet[$RunspaceID].EndInvoke()
        Write-Host $PSCmdlet
        Write-Output $Return.Output
    }
}


Run-Elf