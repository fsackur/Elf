function Run-Elf {

    param(
        #IDs of devices to look up in DB of IP and credential info
        [string[]]$DeviceID,

        #What script you want to run
        [string]$ScriptName,

        #Some object that provides a Log() method (thread-safe)
        [LogProvider]$Log
    )

    #We are in the main thread!

    [string]$Script = Get-ScriptFromLibrary -ScriptName $ScriptName
    
    #PS modules, binary objects, need to be copied to the target computer
    [dictionary]$Dependencies = Get-DependencyPackages -ScriptName $ScriptName

    #Query DB for IPs and credentials for target computers
    [ConnectionInfo[]]$ConnectionInfos = Get-DeviceInfo -DeviceID $DeviceID

    #Thread-safe hashtable to hold data for each run
    [SynchronizedDictionary]$Fleet = New-Object SynchronizedDictionary<string, RunObject>


    #Set up the job objects
    foreach ($ConnectionInfo in $ConnectionInfos) {
        $RunObj = New-Object RunObject (
            $Script,
            $Dependencies,
            $ConnectionInfo
        )

        $Fleet.Add($ConnectionInfo.DeviceID, $RunObj)

        #Event handlers for logging purposes
        $RunObj.EventCreated += $Log.Log($Sender, $EventArgs)
        $RunObj.EventConnected += $Log.Log($Sender, $EventArgs)
        $RunObj.EventDisconnected += $Log.Log($Sender, $EventArgs)
        $RunObj.EventDisposed += $Log.Log($Sender, $EventArgs)

        #Event handlers to get data back from the script
        $RunObj.EventDataAdded += {$Fleet[$Sender].Data.Pop()}   #Pull the PSObject and write to pipeline. It will contain DeviceID
        $RunObj.EventFinished += {$Fleet[$Sender].Data.Pop(); $Fleet[$Sender].Dispose()}
    }

    foreach  ($Run in $Fleet) {
        #Start the run in a new thread
        $Run.BeginInvoke()
    }

}

class RunObject {
    #Fields

    #Publicly accessible
    [string]$DeviceID
    [string]$RunID
    [string[]]$LogMessages
    [int]$CpuUsage
    [int]$MemUsage  #on target machine

    #Private
    [string]$Script
    [Package[]]$Dependencies
    [ConnectionInfo]$ConnectionInfo
    [RunSpace]$RunSpace
    [PowerShell]$PowerShell
    
    #What we really care about!
    #
    [Queue<ResultObj>]$Data    


    #Constructors
    RunObject ($Script, $Dependencies, $ConnectionInfo) {
        this.$Script = $Script
        #etc.
    }

    #Events

}