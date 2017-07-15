function Get-RunObject {

    #Mock for the RunObject class

    [CmdletBinding()]
    param (
        $Script,
        $Dependencies,
        $ConnectionInfo = @{DeviceID = '1234testing'}
    )

    
    [bool]$Debug = $PSBoundParameters["Debug"].IsPresent -eq $true
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
    

    $RunObj.RS.Name = $ConnectionInfo.DeviceID
    $RunObj.PS.Runspace = $RunObj.RS
    $null = $RunObj.PS.AddScript($RunObj.Script)
    $RunObj.RS.Open()
    if ($Debug) {
        $RunObj.RS.SessionStateProxy.SetVariable("ELF_DEBUG", $Debug)
    }

    $RunObj | Add-Member -MemberType ScriptMethod -Name BeginInvoke -Value {
        [CmdletBinding()]
        param()

        $Output = $RunObj.PS.BeginInvoke()
        $Output
        #$RunObj.RS.Dispose()
    }

    return $RunObj
}

$RunObj = Get-RunObject -Script 'Wait-Debugger; return $ELF_DEBUG' -Debug -Verbose
$RunObj.BeginInvoke()
