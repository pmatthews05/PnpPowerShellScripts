<#
.SYNOPSIS
Removes all Office 365 Groups Using Exchange
You will need to run this from Powershell Exchange.
You will need to connect using Connect-EXOPSSession -UserPrincipalName

.EXAMPLE
.\Remove-AllOffice365GroupsviaExchange.ps1 -IgnoreGroups:"All Company","TEMPLATE Project"
#>

param(
    [Parameter(Mandatory)][array]$IgnoreGroups
)
# Show basic information
$InformationPreference = 'continue'

$groups = Get-UnifiedGroup | Where-Object { -not ($IgnoreGroups -contains $_.DisplayName) }

if ($groups.Count -eq 0) { break }

$groups | Format-Table DisplayName, SharePointSiteUrl
Read-Host -Prompt "Press Enter to start deleting (CTRL + C to exit)"
$progress = 0
$total = $groups.Count
foreach ($group in $groups) {
    $progress++
    Write-Information -MessageData:"$progress / $total :  $($group.DisplayName)"
    Remove-UnifiedGroup -identity $group.Id -Confirm:$false
}

Write-Information -MessageData:"Complete"