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

Write-Output $sessionHosts

$take = [math]::Floor(($sessionHosts.Length * ($Percentage / 100)))

for ($i = 0; $i -lt $take; $i++) {
    try {
        Write-Output "Enabling drain on $($sessionHosts[$i].Id.Split("/")[-1])"
        Update-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName -Name $sessionHosts[$i].Id.Split("/")[-1] -AllowNewSession:$false
        Update-Status -ConnectionString $connectionString `
            -TableName status `
            -HostPoolName $HostPoolName `
            -Status "Draining" `
            -SessionHostName $sessionHosts[$i].Id.Split("/")[-1]
    }
    catch {
        Write-Error $_.Exception
        break;
    }
}