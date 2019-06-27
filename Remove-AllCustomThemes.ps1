
<#
.SYNOPSIS
Removes all Custom Themes from Tenant,
You will need to connect using Connect-PnpOnline -url:https://<tenant>-admin.sharepoint.com 
.EXAMPLE

.\Remove-AllCustomThemes.ps1 -IgnoreThemes:"CF Code Default","Blue CF Code"
#>

param(
    [Parameter(Mandatory)][array]$IgnoreThemes
)

# Show basic information
$InformationPreference = 'continue'

$themes = Get-PnPTenantTheme | Where-Object { -not ($IgnoreThemes -contains $_.Name) }
$themes | Format-Table Name
if ($themes.Count -eq 0) { break }
Read-Host -Prompt "Press Enter to start deleting (CTRL + C to exit)"
$progress = 0
$total = $themes.Count
foreach ($theme in $themes) {
    $progress++
    write-Information -MessageData: "$progress / $total : $($theme.Name)"
    Remove-PnPTenantTheme -name $theme.Name
}

Write-Information -MessageData:"Complete"