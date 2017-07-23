<#
    Run on dev box to stash the connection info & creds:
    Add-PoshSecret -Name $DeviceID -Username $Username -Password ********** -Property @{ComputerName=$IP}
#>

function Get-DeviceInfo {
    #Query DB for IPs and credentials for target computers

    #The real thing will need authentication and will implement caching

    param (
        [Parameter(Position=0)]
        [string[]]$DeviceID
    )

    #Mock by returning connection info for localhost
    foreach ($ID in $DeviceID) {
        switch -Wildcard ($ID) {
            'localhost' {
                if (-not $Global:ELF_MOCK_TARGET_CRED) {
                    $Global:ELF_MOCK_TARGET_CRED = Get-Credential -Message 'Enter your password for localhost' -UserName $env:USERNAME
                }
                $ComputerName = $env:COMPUTERNAME
                #$Username = $env:USERNAME
                #$Password = $ELF_MOCK_TARGET_CRED.GetNetworkCredential().Password
                $Cred = $ELF_MOCK_TARGET_CRED
            }

            'FSJ?' {
                $Secret = Get-PoshSecret -Name $_ -Username Administrator -AsPlaintext
                $ComputerName = $Secret.ComputerName
                #$Username = $Secret.UserName
                #$Password = $Secret.Password
                $Cred = New-Object pscredential ($Secret.Username, $Secret.SecurePassword)
            }
        }
        
        New-Object psobject -Property @{
            DeviceID = $ID
            ComputerName = $ComputerName
            #Username = $Username
            #Password = $Password
            Credential = $Cred
        }
    }

}