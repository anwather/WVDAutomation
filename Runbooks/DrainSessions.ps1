Param(
    [string]$ResourceGroupName, 
    [string]$HostPoolName,
    [ValidateRange(1, 100)]
    [int]$Percentage
)

. .\Login.ps1
. .\CommonFunctions.ps1

$connectionString = Get-AutomationVariable -Name "ConnectionString"

$hostPool = Get-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName

$sessionHosts = $hostPool | Get-AzWvdSessionHost

$take = [math]::Floor(($sessionHosts.Length * $Percentage) / 100) - 1

for ($i = 0; $i -lt $take; $i++) {
    try {
        $sessionHosts[$i] | Update-AzWvdSessionHost -AllowNewSession $false -ErrorAction Stop
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