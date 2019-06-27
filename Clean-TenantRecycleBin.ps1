<#
.SYNOPSIS
Empty all sites in your Tenant Recycle Bin
You will need to connect using Connect-PnpOnline -url:https://<tenant>-admin.sharepoint.com 
.EXAMPLE
./Clean-TenantRecycleBin.ps1 

#>
 
# Show basic information
$InformationPreference = 'continue'

$deletedSites = Get-PnPTenantRecycleBinItem
$deletedSites | Format-Table Url
if ($deletedSites.Count -eq 0) { break }
Read-Host -Prompt "Press Enter to start deleting (CTRL + C to exit)"
$progress = 0
$total = $deletedSites.Count
foreach ($deletedSite in $deletedSites) {
    $progress++
    Write-Information -MessageData: "$progress / $total : $($deletedSite.Url)"
    Clear-PnPTenantRecycleBinItem -Url $deletedSite.Url -Force
}

Write-Information "Complete" 