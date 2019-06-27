<#
.SYNOPSIS
Removes all Non Connected Modern SharePoint Sites,
You will need to connect using Connect-PnpOnline -url:https://<tenant>-admin.sharepoint.com 
.EXAMPLE

.\Remove-AllNonGroupConnectedModernSPSite -IgnoreSites:"Extranet","Hub"
#>

param(
    [Parameter(Mandatory)][array]$IgnoreSites
)
# Show basic information
$InformationPreference = 'continue'

$sites = Get-PnPTenantSite | Where-Object { $_.template -eq "SITEPAGEPUBLISHING#0" -or $_.template -eq "STS#3" 
    -and -not ($IgnoreSites -contains $_.Title) } # -or $_.template -eq "GROUP#0"

if ($sites.Count -eq 0) { break }

$sites | Format-Table Title, Url, Template
Read-Host -Prompt "Press Enter to start deleting (CTRL + C to exit)"
$progress = 0
$total = $sites.Count
foreach ($site in $sites) {
    $progress++
    write-Information -MessageData: "$progress / $total : $($site.Title)"
    Remove-PnPTenantSite -Url $site.Url -Force
}

write-Information -MessageData:"Complete"