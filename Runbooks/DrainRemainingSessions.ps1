Param(
    [string]$ResourceGroupName, 
    [string]$HostPoolName
)

. .\Login.ps1
. .\CommonFunctions.ps1

$connectionString = Get-AutomationVariable -Name "ConnectionString"

$rows = Get-AllCurrentStatus -ConnectionString $connectionString -TableName status -HostPoolName $HostPoolName

foreach ($row in $rows) {
    if ($row.Status -eq "New") {
        Write-Output "Enabling drain on $($row.RowKey)"
        Update-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -Name $row.RowKey -AllowNewSession:$false
        Update-Status -ConnectionString $connectionString `
            -TableName status `
            -HostPoolName $HostPoolName `
            -Status "Draining" `
            -SessionHostName $row.RowKey
    }
}