function Get-LoggerObject {

    #Placeholder - Log4Net seems to be a good choice

    [CmdletBinding()]
    param (
        $LogFolder = $PSScriptRoot
    )

    

    $Logger = New-Object psobject -Property @{
        LogFolder = $LogFolder
        LogFile = (Join-Path $LogFolder 'Elf.log')
    }
    
    
    $Logger | Add-Member -MemberType ScriptMethod -Name Log -Value {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [string]$DeviceID,

            [Parameter(Mandatory=$true, Position=1)]
            [ValidateSet(
                'Error',
                'Verbose',
                'Debug',
                'Warning',
                'Information'
            )]
            $ErrorLevel,

            [Parameter(Mandatory=$true, Position=2)]
            [string]$Message
        )

        $Now = Get-Date
        $LogLine = "{0,-20}:: {1,-12}:: {2,-12}:: {3}" -f (
            $Now.ToString('s'),
            $DeviceID,
            $ErrorLevel,
            $Message
        )
        
        $LogLine | Out-File $this.LogFile -Append
    }

    $Logger.Log(
        'Elf',
        'Information',
        'Starting logging'
    )
    return $Logger
}



function Read-Log {
    #Read-Log -Wait
    param(
        $DeviceID,  #filter
        [switch]$Wait    
    )

    $LogFile = Join-Path $PSScriptRoot 'Elf.log'

    if ($DeviceID) {
        $DeviceID = $DeviceID.Substring(8)
        $Filter = {$_ -match $DeviceID}
    } else {
        $Filter = {$true}
    }

    $Colours = @{
        'Error' = 'Red'
        'Verbose' = 'Gray'
        'Debug' = 'DarkGray'
        'Warning' = 'Yellow'
        'Information' = 'White'
    }

    Get-Content $LogFile -Tail 40 -Wait:$Wait | where $Filter | foreach {
        $Colour = $Colours[$(
            $_.SubString(38, 12).Trim()
        )]
        Write-Host -ForegroundColor $Colour $_

    }

}


