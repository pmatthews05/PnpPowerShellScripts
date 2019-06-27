<#
.SYNOPSIS
Removes all Site Designs from Tenant,
You will need to connect using Connect-PnpOnline -url:https://<tenant>-admin.sharepoint.com 
.EXAMPLE

.\Remove-AllSiteDesigns.ps1 -IgnoreDesigns:"CF Project Site","CF Issues List"
#>

param(
    [Parameter(Mandatory)][array]$IgnoreThemes
)

$InformationPreference = 'continue'

$siteDesigns = Get-PnPSiteDesign | Where-Object { -not ($IgnoreDesigns -contains $_.Title) }

if ($siteDesigns.Count -eq 0) { break }
$siteDesigns | Format-Table Title, SiteScriptIds, Description
Read-Host -Prompt "Press Enter to start deleting (CTRL + C to exit)"
$progress = 0
$total = $siteDesigns.Count
foreach ($siteDesign in $siteDesigns) {
    $progress++
    Write-Information -MessageData:"$progress / $total : $($siteDesign.Title)"
    Remove-PnPSiteDesign -Identity $siteDesign.Id -Force
}

Write-Information -MessageData:"Complete"