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
    . $PSScriptRoot\Get-RunObject.ps1

    $LOgger.Log(
        $null, 
        'Information', 
        "Starting Elf: {0}" -f $ScriptName
    )

    #[string]$Script = Get-ScriptFromLibrary -ScriptName $ScriptName
    $Script = 'Write-Output "You invoked, sir?"'

    #Query DB for IPs and credentials for target computers
    $ConnectionInfos = Get-DeviceInfo -DeviceID $DeviceID

    #Thread-safe hashtable to hold data for each run
    $Fleet = @{}


    #Set up the job objects
    foreach ($ConnectionInfo in $ConnectionInfos) {
        $RunObj = Get-RunObject (
            $Script,
            $Dependencies,
            $ConnectionInfo
        )
        $Fleet.Add($ConnectionInfo.DeviceID, $RunObj)
    }

    foreach  ($Kvp in $Fleet.GetEnumerator()) {
        #Start the run in a new thread
        $Kvp.Value.Invoke()
    }

}

Run-Elf -Debug