function Update-Status {
    [CmdletBinding()]
    Param($TableName, $HostPoolName, $SessionHostName, $Status, $ConnectionString)

    $ctx = New-AzStorageContext -ConnectionString $connectionString

    $table = (Get-AzStorageTable -Name $TableName -Context $ctx).CloudTable

    $row = Get-AzTableRow -Table $table -PartitionKey $HostPoolName -RowKey $SessionHostName

    if ($null -eq $row) {
        Add-AzTableRow -Table $table -PartitionKey $HostPoolName -RowKey $SessionHostName -property @{
            Status         = $status
            LastUpdateTime = $(Get-Date)
        }
    }
    else {
        $row.Status = $status
        $row.LastUpdateTime = $(Get-Date)
        $row | Update-AzTableRow -Table $table
    }
}

function Get-AllCurrentStatus {
    [CmdletBinding()]
    Param($ConnectionString, $TableName, $HostPoolName)

    $ctx = New-AzStorageContext -ConnectionString $connectionString

    $table = (Get-AzStorageTable -Name $TableName -Context $ctx).CloudTable

    $rows = Get-AzTableRowByPartitionKey -Table $table -PartitionKey $HostPoolName

    return $rows
}

function Get-SingleCurrentStatus {
    [CmdletBinding()]
    Param($ConnectionString, $TableName, $HostPoolName, $SessionHost)

    $ctx = New-AzStorageContext -ConnectionString $connectionString

    $table = (Get-AzStorageTable -Name $TableName -Context $ctx).CloudTable

    $row = Get-AzTableRowByPartitionKey -Table $table -PartitionKey $HostPoolName | Where-Object RowKey -eq $SessionHost

    return $row
}

function Get-ActiveSessions {
    [CmdletBinding()]
    Param($ResourceGroupName, $HostPoolName, $SessionHost, $ConnectionString)

    $sessions = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -Name $SessionHost

    Write-Output "Detected $($sessions.Session) sessions on $SessionHost"

    if ($sessions.Session -eq 0) {
        Write-Output "No active sessions - rebooting"
        Update-Status -ConnectionString $connectionString `
            -TableName status `
            -HostPoolName $HostPoolName `
            -Status "RebootReady" `
            -SessionHostName $SessionHost
        return 0
    }
    else {
        Write-Output "Active sessions detected"
        return 1
    }
}

function Restart-SessionHost {
    [CmdletBinding()]
    Param($ResourceGroupName, $HostPoolName, $SessionHost, $ConnectionString)

    $reboothost = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -Name $SessionHost
    Write-Output "Rebooting host $SessionHost"
    Update-Status -ConnectionString $connectionString `
        -TableName status `
        -HostPoolName $HostPoolName `
        -Status "Rebooting" `
        -SessionHostName $SessionHost

    Restart-AzVM -Id $reboothost.ResourceId -NoWait
}

function Check-Completion {
    [CmdletBinding()]
    Param($ResourceGroupName, $HostPoolName, $SessionHost, $ConnectionString)

    $hostMachine = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -Name $SessionHost
    if ($hostMachine.Status -eq "Available") {
        Write-Output "Allowing new sessions on $SessionHost"
        Update-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -Name $sessionHost -AllowNewSession
        Update-Status -ConnectionString $connectionString `
            -TableName status `
            -HostPoolName $HostPoolName `
            -Status "Complete" `
            -SessionHostName $SessionHost
    }
    else {
        Write-Output "Host $SessionHost is not available"
    }
}

function Send-Reminder {
    [CmdletBinding()]
    Param()
}