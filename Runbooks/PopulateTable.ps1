Param($ResourceGroupName, $HostPoolName)

. .\Login.ps1
. .\CommonFunctions.ps1

$connectionString = Get-AutomationVariable -Name "ConnectionString"

Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName | Foreach-Object {
    Update-Status -ConnectionString $connectionString `
        -TableName status `
        -HostPoolName $HostPoolName `
        -Status "New" `
        -SessionHostName $_.ResourceId.Split("/")[-1]
}