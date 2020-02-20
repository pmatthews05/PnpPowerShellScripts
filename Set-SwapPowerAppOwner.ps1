<#
 .SYNOPSIS
 Swaps the previous Owners Name with the new owner.
 
 You need to be connected to AZ first so you can query AD.

 You need to have already connected to the PowerApp Admin module using 
 Add-PowerAppsAccount

If you don't have the module installed call the following first.
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope:CurrentUser -Force
Install-Module -Name Microsoft.PowerApps.PowerShell -Scope:CurrentUser -Force -AllowClobber

.EXAMPLE
.\Set-SwapPowerAppOwner -PreviousOwnerPrincipalName:olduser@tenant.onmicrosoft.com -NewOwnerPrincipalName:newuser@tenant.onmicrosoft.com

#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]
    $PreviousOwnerPrincipalName,
    [Parameter(Mandatory)]
    [string]
    $NewOwnerPrincipalName
)
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

Write-Information -MessageData:"Getting $PreviousOwnerPrincipalName from Azure AD..."
$oldOwnerObject = az ad user list --query "[?userPrincipalName == '$PreviousOwnerPrincipalName'].{ID:objectId,Name:displayName}" | ConvertFrom-Json    

if (-not $oldOwnerObject) {
    Write-Error "Unable to find $PreviousOwnerPrincipalName"
}

Write-Information -MessageData:"Getting $NewOwnerPrincipalName from Azure AD..."
$newOwnerObject = az ad user list --query "[?userPrincipalName == '$NewOwnerPrincipalName'].{ID:objectId,Name:displayName}" | ConvertFrom-Json

if (-not $newOwnerObject) {
    Write-Error "Unable to find $NewOwnerPrincipalName"
}
    

$PowerApps = Get-AdminPowerApp | `
    Where-Object { $_.Owner.id -eq $oldOwnerObject.ID }
    
Write-Information -MessageData:"Found $($PowerApps.Count) apps where the owner is $($oldOwnerObject.Name)"
     
$PowerApps | ForEach-Object { 
    Write-Information -MessageData:"Updating App '$($_.DisplayName)' in Environment '$($_.EnvironmentName)' to owner '$($newOwnerObject.Name)'"
    Set-AdminPowerAppOwner -AppName $_.AppName -AppOwner $newOwnerObject.ID -EnvironmentName $_.EnvironmentName | Out-Null
}
