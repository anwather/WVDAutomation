function Update-Status {
    [CmdletBinding()]
    Param($TableName, $HostPoolName, $SessionHostName, $Status, $ConnectionString)

    $ctx = New-AzStorageContext -ConnectionString $connectionString

    $table = (Get-AzStorageTable -Name $tableName -Context $ctx).CloudTable

    $row = Get-AzTableRow -Table $table -PartitionKey $partitionKey -RowKey $hostName

    if ($null -eq $row) {
        Add-AzTableRow -Table $table -PartitionKey $partitionKey -RowKey $hostname -property @{
            Status         = $status
            LastUpdateTime = $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
        }
    }
    else {
        $row.Status = $status
        $row.LastUpdateTime = $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
        $row | Update-AzTableRow -Table $table
    }
}

function Get-AllCurrentStatus {
    [CmdletBinding()]
    Param($ConnectionString, $TableName, $HostPoolName)

    $ctx = New-AzStorageContext -ConnectionString $connectionString

    $table = (Get-AzStorageTable -Name $tableName -Context $ctx).CloudTable

    $rows = Get-AzTableRowByPartitionKey -Table $table -PartitionKey $HostPoolName

    return $rows
}

function Restart-Host {
    [CmdletBinding()]
    Param()
}

function Get-ActiveSessions {
    [CmdletBinding()]
    Param()
}

function Send-Reminder {
    [CmdletBinding()]
    Param()
}