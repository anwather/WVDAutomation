Param(
    [string]$ResourceGroupName, 
    [string]$HostPoolName,
    [ValidateRange(1, 100)]
    [int]$Percentage
)

. .\Login.ps1
. .\CommonFunctions.ps1

$connectionString = Get-AutomationVariable -Name "ConnectionString"



$sessionHosts = Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName

$take = [math]::Floor(($sessionHosts.Length * $Percentage) / 100) - 1

for ($i = 0; $i -lt $take; $i++) {
    try {
        Update-AzWvdSessionHost -HostPoolName $HostPoolName -Name $sessionHosts[$i].Id.Split("/")[-1] -AllowNewSession:$false
        Update-Status -ConnectionString $connectionString `
            -TableName status `
            -HostPoolName $HostPoolName `
            -Status "Draining" `
            -SessionHostName $sessionHosts[$i].Name
    }
    catch {
        Write-Error $_.Exception
        break;
    }
}