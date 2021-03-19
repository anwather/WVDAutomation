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
                $t = $row.LastUpdateTime -as [datetime]
                Write-Output "$($row.RowKey) last update time: $t"
                Write-Output "Current time is $(Get-Date)"
                if (($t).AddHours($Delay) -lt (Get-Date)) {
                    Write-Output "Sending 30 minute warning"
                    Send-Reminder -ConnectionString $connectionString `
                        -ResourceGroupName $params.ResourceGroupName `
                        -HostPoolName $params.HostPoolName `
                        -SessionHost $row.RowKey `
                        -ReminderTime 30 
                }
                else {
                    $remainingTime = [math]::Round((New-TimeSpan -Start $t.AddHours($Delay) -End (Get-Date)).TotalMinutes)
                    Write-Output "$($row.RowKey) - remaining time until 30 min message to be sent is $remainingTime"
                }
            }
        }
        "30" { 
            Write-Output "$($row.RowKey) has passed 30 minute warning - check the sessions remaining and proceed"
            $result = Get-ActiveSessions -ConnectionString $connectionString `
                -ResourceGroupName $params.ResourceGroupName `
                -HostPoolName $params.HostPoolName `
                -SessionHost $row.RowKey
            if ($result -eq 1) {
                $t = $row.LastUpdateTime -as [datetime]
                Write-Output "Sending 20 minute warning"
                Send-Reminder -ConnectionString $connectionString `
                    -ResourceGroupName $params.ResourceGroupName `
                    -HostPoolName $params.HostPoolName `
                    -SessionHost $row.RowKey `
                    -ReminderTime 20 
            }
        }
        "20" { 
            Write-Output "$($row.RowKey) has passed 20 minute warning - check the sessions remaining and proceed"
            $result = Get-ActiveSessions -ConnectionString $connectionString `
                -ResourceGroupName $params.ResourceGroupName `
                -HostPoolName $params.HostPoolName `
                -SessionHost $row.RowKey
            if ($result -eq 1) {
                $t = $row.LastUpdateTime -as [datetime]
                Write-Output "Sending 10 minute warning"
                Send-Reminder -ConnectionString $connectionString `
                    -ResourceGroupName $params.ResourceGroupName `
                    -HostPoolName $params.HostPoolName `
                    -SessionHost $row.RowKey `
                    -ReminderTime 10 
            }
        }
        "10" { 
            Write-Output "$($row.RowKey) has passed 10 minute warning - scheduling reboot for next cycle"
            Update-Status -ConnectionString $connectionString `
                -TableName status `
                -HostPoolName $params.HostPoolName `
                -Status "RebootReady" `
                -SessionHostName $row.RowKey
        }
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