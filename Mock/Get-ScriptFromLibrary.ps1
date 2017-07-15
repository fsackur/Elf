function Get-ScriptFromLibrary {

    #Scripts to run on remote boxes.

    #This mock returns some simple scripts.

    param(
        #What script you want to run
        [string]$ScriptName
    )

    switch ($ScriptName) {
        'Get-PowerShellVersion' {
            return 'Write-Output $PSVersionTable.PSVersion.Major'
        }
        'Get-Hostname' {
            return 'Write-Output $env:COMPUTERNAME'
        }
        'Get-Host' {
            return 'Get-Host'
        }
    }
}