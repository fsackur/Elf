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
        ConnectionInfo = $ConnectionInfo
    }

    $RunObj | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
        [CmdletBinding()]
        param()
        Write-Output "You invoked, sir?"
    }

    return $RunObj
}