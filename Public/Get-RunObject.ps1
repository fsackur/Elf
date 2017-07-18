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
        RS = [runspacefactory]::CreateRunspace();
        Handle = $null;
        Output = $null;
        Streams =$null;
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

        $this.PS.Invoke()
        $this.RS.Dispose()
        $this.PS.Dispose()
        New-Object psobject -Property @{
            Output = $Output
            Streams = $this.PS.Streams
            HadErrors = $this.PS.Streams
        }
    }

    $RunObj | Add-Member -MemberType ScriptMethod -Name BeginInvoke -Value {
        [CmdletBinding()]
        param()

        $this.Handle = $this.PS.BeginInvoke()
    }

    $RunObj | Add-Member -MemberType ScriptMethod -Name EndInvoke -Value {
        [CmdletBinding()]
        param()

        $Output = $this.PS.Endinvoke($this.Handle)
        $this.RS.Dispose()
        $this.PS.Dispose()
        New-Object psobject -Property @{
            Output = $Output
            Streams = $this.PS.Streams
            HadErrors = $this.PS.Streams
        }
    }

    return $RunObj
}

#$Logger = Get-LoggerObject

#$RunObj = Get-RunObject -Script (Get-Command Script).Definition -Verbose -Debug

<#
$null = Register-ObjectEvent -InputObject $RunObj.PS -EventName 'InvocationStateChanged' -Action {
    $Logger.Log(
        $event.Sender.Runspace.InstanceId.Guid.Substring(0, 8),
        'Information',
        "PS state {0}" -f $Eventargs.InvocationStateInfo.State
    )

    if ($Eventargs.InvocationStateInfo.State -eq [System.Management.Automation.PSInvocationState]::Completed) {
        Wait-Debugger
        Write-Verbose $Eventargs.InvocationStateInfo.State
        $Event.Sender.Streams.Verbose | foreach {Write-Verbose $_}
        #$Event.Sender.Streams.Error | foreach {Write-Error $_}
        $this.Output = EndInvoke($RunObj.Handle)
        
    }
}

    
$null = Register-ObjectEvent -InputObject $RunObj.PS -EventName 'InvocationStateChanged' -Action {
    $Logger.Log(
        $event.Sender.Runspace.InstanceId.Guid.Substring(0, 8),
        'Information',
        "PS state {0}" -f $Eventargs.InvocationStateInfo.State
    )
}

$RunObj.BeginInvoke()
#>