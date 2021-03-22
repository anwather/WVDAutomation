Param(
    [string]$ResourceGroupName, 
    [string]$HostPoolName,
    [ValidateRange(1, 100)]
    [int]$Percentage
)

. .\Login.ps1
. .\CommonFunctions.ps1

$connectionString = Get-AutomationVariable -Name "ConnectionString"