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

function Script {
    
        #Wait-Debugger
        #$VerbosePreference = "Continue";
        Start-sleep 1
        Write-Verbose "Some verbose info"; 
        Write-Output "Standard"
        Get-Variable | where Name -match "Preference"; 
        Start-sleep 1
        #Write-Error "Some error info here"
}