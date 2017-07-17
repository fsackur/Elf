function Get-RunObject {

    #Mock for the RunObject class

    [CmdletBinding()]
    param (
        $Script,
        $Dependencies,
        $ConnectionInfo = @{DeviceID = '1234testing'}
    )

    
    [bool]$Debug = $PSBoundParameters["Debug"].IsPresent -eq $true
    [bool]$Verbose = $PSBoundParameters["Verbose"].IsPresent -eq $true
    Write-Verbose ("Debug = {0}" -f $Debug)
    

    $RunObj = New-Object psobject -Property @{
        Script = $Script;
        Dependencies = $Dependencies;
        ConnectionInfo = $ConnectionInfo;
        PS = [powershell]::Create();
        RS = [runspacefactory]::CreateRunspace()
    }
    
    
    $SessionVariables = @{
        "MyPreference" = "MOAR CODE"
    }
    if ($Debug) {$SessionVariables.Add("DebugPreference", "Continue")}
    if ($Verbose) {$SessionVariables.Add("VerbosePreference", "Continue")}


    $RunObj.RS.Name = $ConnectionInfo.DeviceID
    $RunObj.PS.Runspace = $RunObj.RS
    #if ($Debug) {$null = $RunObj.PS.AddScript('Wait-Debugger;')}
    $null = $RunObj.PS.AddScript($RunObj.Script)
    $RunObj.RS.Open()
    $SessionVariables.GetEnumerator() | foreach {
        $RunObj.RS.SessionStateProxy.SetVariable($_.Name, $_.Value)
    }

    $RunObj | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
        [CmdletBinding()]
        param()

        $Output = $this.PS.Invoke()
        $Output
        $this.RS.Dispose()
        $this.PS.Dispose()
    }

    $RunObj | Add-Member -MemberType ScriptMethod -Name BeginInvoke -Value {
        [CmdletBinding()]
        param()

        $Handle = $this.PS.BeginInvoke()
      
        $Output = $this.PS.EndInvoke($Handle)
        $Output
        $this.RS.Dispose()
        $this.PS.Dispose()
    }

    return $RunObj
}

$Logger = Get-LoggerObject

$RunObj = Get-RunObject -Script '
        $VerbosePreference = "COntinue";
        Start-sleep 1
    Write-Verbose "Some verbose info"; 
    Write-Output "Standard"
    Get-Variable | where Name -match "Preference"; 
    Start-sleep 1
    Write-Error "Some error info here"
' -Verbose -Debug


$null = Register-ObjectEvent -InputObject $RunObj.PS -EventName 'InvocationStateChanged' -Action {
    if ($Eventargs.InvocationStateInfo.State -eq [System.Management.Automation.PSInvocationState]::Completed) {
        Write-Verbose $Eventargs.InvocationStateInfo.State
        $Event.Sender.Streams.Verbose | foreach {Write-Verbose $_}
        $Event.Sender.Streams.Error | foreach {Write-Error $_}
    }
}

    
$null = Register-ObjectEvent -InputObject $RunObj.PS -EventName 'InvocationStateChanged' -Action {
    $Logger.Log(
        $event.Sender.Runspace.InstanceId.Guid.Substring(0, 8),
        'Information',
        "PS state {0}" -f $Eventargs.InvocationStateInfo.State
    )
}

$RunObj.Invoke()