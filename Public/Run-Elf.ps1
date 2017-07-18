

function Run-Elf {
    
    [CmdletBinding()]
    param(
        #IDs of devices to look up in DB of IP and credential info
        [string[]]$DeviceID = 'localhost',

        #What script you want to run
        [string]$ScriptName = 'Get-PowerShellVersion',

        #Exposes Log() method
        [psobject]$Logger = $(. $PSScriptRoot\Get-LoggerObject.ps1; Get-LoggerObject)
    )

    . $PSScriptRoot\..\Mock\Get-ScriptFromLibrary.ps1
    . $PSScriptRoot\..\Mock\Get-DeviceInfo.ps1

    $Logger.Log(
        $null, 
        'Information', 
        "Starting Elf: {0}" -f $ScriptName
    )

    #[string]$Script = Get-ScriptFromLibrary -ScriptName $ScriptName
    $Script = (Get-Command Script).Definition
    #$Script = 'Write-Output "You invoked, sir?"'

    #Query DB for IPs and credentials for target computers
    $ConnectionInfos = Get-DeviceInfo -DeviceID $DeviceID

    #Thread-safe hashtable to hold data for each run
    $Script:Fleet = @{}


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
        #Start the run in a new thread
        $null = Register-ObjectEvent -InputObject $Kvp.Value.PS -EventName 'InvocationStateChanged' -Action $ElfPsCallback
        $Kvp.Value.BeginInvoke()
    }

}

$ElfPsCallback = {
    $RunspaceID = $event.Sender.Runspace.InstanceId.Guid
    $Logger.Log(
        $RunspaceID.Substring(0, 8),
        'Information',
        "PS state {0}" -f $Eventargs.InvocationStateInfo.State
    )

    if ($Eventargs.InvocationStateInfo.State -eq [System.Management.Automation.PSInvocationState]::Completed) {
        #$Return = $Fleet[$RunspaceID].EndInvoke()
        $Return = $event.Sender.EndInvoke()
        Write-host $Return.Output
    }
}






Run-Elf #-Debug