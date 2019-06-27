<#
.SYNOPSIS
Removes all Office 365 Groups using Graph
You will need to connect Connect-PnPOnline -Graph -LaunchBrowser

.EXAMPLE
.\Remove-AllOffice365GroupsViaGraph.ps1 -IgnoreGroups:"All Company","TEMPLATE Project"
#>

param(
    [Parameter(Mandatory)][array]$IgnoreGroups
)
# Show basic information
$InformationPreference = 'continue'

$groups = Get-PnPUnifiedGroup | Where-Object { -not ($IgnoreGroups -contains $_.DisplayName) }

if ($groups.Count -eq 0) { break }

$groups | Format-Table DisplayName, SharePointSiteUrl

Read-Host -Prompt "Press Enter to start deleting (CTRL + C to exit)"
$progress = 0
$total = $groups.Count
foreach ($group in $groups) {
    $progress++
    Write-Information -MessageData:"$progress / $total : $($group.DisplayName)"
    Remove-PnPUnifiedGroup -Identity $group.Id -Force
}

Write-Information -MessageData:"Complete"