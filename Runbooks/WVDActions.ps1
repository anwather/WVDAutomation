Param(
    [object]$WebHookData
)

. .\Login.ps1
. .\CommonFunctions.ps1

$connectionString = Get-AutomationVariable -Name "ConnectionString"
$Delay = Get-AutomationVariable -Name "Delay"

Write-Output "Delay is set to $Delay hours."

$params = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)

$rows = Get-AllCurrentStatus -ConnectionString $connectionString -TableName status -HostPoolName $params.HostPoolName

foreach ($row in $rows) {
    switch ($row.Status) {
        "Draining" { 
            Write-Output "$($row.RowKey) is draining - check the sessions remaining and proceed"
            $result = Get-ActiveSessions -ConnectionString $connectionString `
                -ResourceGroupName $params.ResourceGroupName `
                -HostPoolName $params.HostPoolName `
                -SessionHost $row.RowKey
            if ($result -eq 1) {
                Write-Output $row.LastUpdateTime
                $t = $row.LastUpdateTime -as [datetime]
                Write-Output "Last update time: $t"
                if (($t).AddHours($Delay) -lt (Get-Date)) {
                    Write-Output "Sending 30 minute warning"
                    # Send message and update status to 30
                }
                else {
                    $remainingTime = [math]::Round([math]::Abs((New-TimeSpan -Start $t -End (Get-Date).AddHours($Delay)).TotalMinutes))
                    Write-Output "Remaining time until 30 min message to be sent is $remainingTime"
                }
            }
        }
        "30" { Write-Output "Sending 20 minute warning" }
        "20" { Write-Output "Sending 10 minute warning" }
        "10" { Write-Output "Rebooting the session host" }
        "RebootReady" { 
            Write-Output "Calling for reboot of node $($row.RowKey)"
            Restart-SessionHost -ConnectionString $connectionString `
                -ResourceGroupName $params.ResourceGroupName `
                -HostPoolName $params.HostPoolName `
                -SessionHost $row.RowKey
        }
        "Rebooting" { 
            Write-Output "Checking if node $SessionHost is available"
            Check-Completion -ConnectionString $connectionString `
                -ResourceGroupName $params.ResourceGroupName `
                -HostPoolName $params.HostPoolName `
                -SessionHost $row.RowKey
        }
        "Complete" { Write-Output "Node is complete" }
    }
}