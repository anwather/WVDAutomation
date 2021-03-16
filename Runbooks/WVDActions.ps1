Param($HostPoolName, $ResourceGroupName)

. .\Login.ps1
. .\CommonFunctions.ps1

$connectionString = Get-AutomationVariable -Name "ConnectionString"

$rows = Get-AllCurrentStatus -ConnectionString $connectionString -TableName status -HostPoolName $HostPoolName

foreach ($row in $rows) {
    switch ($row.Status) {
        "Draining" { Write-Output "$($row.RowKey) is draining - check the sessions remaining and send a warning" }
        "30" { Write-Output "Sending 20 minute warning" }
        "20" { Write-Output "Sending 10 minute warning" }
        "10" { Write-Output "Rebooting the session host" }
        "Rebooting" { Write-Output "Checking if node is green" }
        "Complete" { Write-Output "Node is complete" }
    }
}