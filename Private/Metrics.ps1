#$WF = Get-WmiObject Win32_PerfFormattedData_PerfProc_Process -Filter "Name LIKE 'powershell_ise_17616'"
#$CPU = Get-WmiObject Win32_PerfRawData_PerfOS_Processor

$W = Get-WmiObject Win32_PerfRawData_PerfProc_Process -Filter "Name LIKE 'powershell_ise_17616'"


$W | select `
@{Name="PercentProcessorTime";Expression={"{0:0.00}" -f ($_.PercentProcessorTime/100000/100)/60}}

Measure-Command {1..1000 | %{
    $PS = [powershell]::Create()
    [void]$PS.AddScript('Write-Output "You invoked, sir?"')
    $PS.Invoke()
    $PS.Dispose()
}}

$W = Get-WmiObject Win32_PerfRawData_PerfProc_Process -Filter "Name LIKE 'powershell_ise_17616'"


$W | select `
@{Name="PercentProcessorTime";Expression={"{0:0.00}" -f ($_.PercentProcessorTime/100000/100)/60}}
