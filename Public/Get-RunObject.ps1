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
    

    #Use process MainWindowTitle so we can identify it from a separate debugging process
    if ($Debug) {        
        #$DebugID = (New-Guid).Guid
        $DebugID = 'dd0311a1-6aaf-44d5-810b-4de968151e0c'   #Mock

        $MWT = "Debug ID: {0}" -f $DebugID
        $Host.UI.RawUI.WindowTitle = $MWT
        Write-Host -ForegroundColor DarkYellow $MWT
    }


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
        $this.PS.Streams.Verbose | foreach {Write-Verbose $_}
        $this.PS.Streams.Debug | foreach {Write-Debug $_}
        $this.PS.Streams.Error | foreach {Write-Error $_}
        $this.RS.Dispose()
        $this.PS.Dispose()
    }

    $RunObj | Add-Member -MemberType ScriptMethod -Name BeginInvoke -Value {
        [CmdletBinding()]
        param()

        $Handle = $this.PS.BeginInvoke()
        
        #Should be event-driven, sleep is just for testing
        while (-not $Handle.IsCompleted) {
            Start-Sleep -Milliseconds 200
        }
        
        $Output = $this.PS.EndInvoke($Handle)
        $Output
        $this.PS.Streams.Verbose | foreach {Write-Verbose $_}
        $this.PS.Streams.Debug | foreach {Write-Debug $_}
        $this.PS.Streams.Error | foreach {Write-Error $_}
        $this.RS.Dispose()
        $this.PS.Dispose()
    }

    return $RunObj
}

$RunObj = Get-RunObject -Script '
    Write-Verbose "Some verbose info"; 
    Get-Variable | where Name -match "Preference"; 
    Write-Error "Some error info here"
' -Verbose -Debug
#$RunObj.BeginInvoke()
#$RunObj.Invoke()
