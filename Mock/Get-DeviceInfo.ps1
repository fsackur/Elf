function Get-DeviceInfo {
    #Query DB for IPs and credentials for target computers

    #The real thing will need authentication and will implement caching

    param (
        [string[]]$DeviceID
    )

    #Mock by returning connection info for localhost
    foreach ($ID in $DeviceID) {
        if (-not $Global:ELF_MOCK_TARGET_CRED) {
            $Global:ELF_MOCK_TARGET_CRED = Get-Credential -Message 'Enter your password for localhost' -UserName $env:USERNAME
        }
        
        New-Object psobject -Property @{
            DeviceID = $ID
            IP = [ipaddress]'127.0.0.1'
            Credential = $Global:ELF_MOCK_TARGET_CRED
        }
    }

}