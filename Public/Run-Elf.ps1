
<#
    You can't reload a class without closing and reopening, which is a chore in ISE

    THis is a dirty hack to give a different object type each run

    So I can dev faster while the pace of change is high
#>
function Import-ElfType {
    $TypeDef = Get-Content $PSScriptRoot\..\Elf\Classes\MockRunObject.cs -Raw

    try {
        $null = Get-Variable NextTypeSuffix -Scope Global
        $Global:NextTypeSuffix++
    } catch {
        $Global:NextTypeSuffix = 0
    }

    $TypeDef = $TypeDef -replace 'MockRunObject', "RunObject$Global:NextTypeSuffix"
    Add-Type -TypeDefinition $TypeDef -PassThru

}


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


    #See my excuses in the comment block for this function
    $RunObjType = Import-ElfType


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
        $RunObj = New-Object $RunObjType (
            $Script,
            $Dependencies,
            $ConnectionInfo
        )
        Write-Verbose $RunObj
        $Fleet.Add($ConnectionInfo.DeviceID, $RunObj)
    }

    foreach  ($Kvp in $Fleet.GetEnumerator()) {
        #Start the run in a new thread
        $Kvp.Value.Invoke()
    }

}

Run-Elf -Debug