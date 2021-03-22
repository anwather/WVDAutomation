Param(
    [string]$ResourceGroupName, 
    [string]$HostPoolName,
    [ValidateRange(1, 100)]
    [int]$Percentage
)

. .\Login.ps1
. .\CommonFunctions.ps1

$connectionString = Get-AutomationVariable -Name "ConnectionString"

$rows = Get-AllCurrentStatus -ConnectionString $connectionString -TableName status -HostPoolName $params.HostPoolName

foreach ($row in $rows) {
    if ($row.status -eq "New") {
        Write-Output "Enabling drain on $($row.RowKey)"
        Update-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -Name $row.RowKey -AllowNewSession:$false
        Update-Status -ConnectionString $connectionString `
            -TableName status `
            -HostPoolName $HostPoolName `
            -Status "Draining" `
            -SessionHostName $row.RowKey
    }
}