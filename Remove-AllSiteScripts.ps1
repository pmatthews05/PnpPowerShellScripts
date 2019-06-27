<#
.SYNOPSIS
Removes all Site Scripts from Tenant,
You will need to connect using Connect-PnpOnline -url:https://<tenant>-admin.sharepoint.com 
.EXAMPLE

.\Remove-AllSiteScripts.ps1 -IgnoreScripts:"CF Project Site","CF Issues List"
#>

param(
    [Parameter(Mandatory)][array]$IgnoreScripts
)

$InformationPreference = 'continue'

$siteScripts = Get-PnPSiteScript | Where-Object { -not ($IgnoreScripts -contains $_.Title) }
if ($siteScripts.Count -eq 0) { break }
$siteScripts | Format-Table Title, Id
Read-Host -Prompt "Press Enter to start deleting (CTRL + C to exit)"
$progress = 0
$total = $siteScripts.Count
foreach ($siteScript in $siteScripts) {
    $progress++
    Write-Information -MessageData:"$progress / $total : $($siteScript.Title)"
    Remove-PnPSiteScript -Identity $siteScript.Id -Force
}

Write-Information -MessageData:"Completed"