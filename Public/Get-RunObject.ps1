function Get-RunObject {

    #Mock for the RunObject class

    param (
        $Script,
        $Dependencies,
        $ConnectionInfo
    )

    $RunObj = New-Object psobject -Property @{
        Script = $Script;
        Dependencies = $Dependencies;
        ConnectionInfo = $ConnectionInfo;
        PS = [powershell]::Create();
        RS = [runspacefactory]::CreateRunspace()
    }
    
    $RunObj.PS.Runspace = $RunObj.RS
    $null = $RunObj.PS.AddScript($RunObj.Script)
    $RunObj.RS.Open()

    $RunObj | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
        [CmdletBinding()]
        param()
        $Output = $RunObj.PS.Invoke()
        $Output
        $RunObj.RS.Dispose()
    }

    return $RunObj
}
