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
    #$ConnectionInfos | foreach {
        #Wait-Debugger
        #Write-Output $_.ComputerName
        #Write-Output $_.Credential
        #<#
        $Global:Sesh = New-PSSession -ComputerName $_.ComputerName -Credential $_.Credential -UseSSL -SessionOption (
            New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
        )
        Invoke-Command -Session $Sesh -ScriptBlock {
            $VerbosePreference = 'Continue'
            #Get-Process
            Write-Output 'Std out'
            Write-Verbose "Verbose out"
            Write-Error "Error out"
        }
        #Remove-PSSession $Sesh
        #>
        <#
        $WsmanInfo = New-Object System.Management.Automation.Runspaces.WSManConnectionInfo (
            $true, #useSsl
	        $_.ComputerName,
	        5986,
	        '/wsman',
	        'http://schemas.microsoft.com/powershell/Microsoft.PowerShell',
	        $_.Credential,
	        1000 #int openTimeout
        )
        $WsmanInfo.SkipCACheck = $true
        $WsmanInfo.SkipCNCheck = $true
        $WsmanInfo.SkipRevocationCheck = $true
        $RS = [runspacefactory]::CreateRunspace($WsmanInfo)
        $RS.Open()
        $PS = [powershell]::Create()
        $PS.Runspace = $RS
        $PS.AddScript('$env:COMPUTERNAME') | Out-Null
        $PS.Invoke()
        #>
    } | Wait-RSJob | Receive-RSJob

}


$Out = Run-Elf -DeviceID FSJ2