<#
.SYNOPSIS
Loops through the Tenant and output a csv string of all folders and files that are empty.
Requires a SharePoint ClientID and Secret that can read the entire tenant.
Store the client ID and Secret in a json File.

{
    "ClientId" : "<GUID>",
    "ClientSecret" : "<SECRET>"
}

Once run you can delete the progress file. The progress file allows you to stop, or the code might stop because of timeout, and you can run the code, which continues where
it left off.

.EXAMPLE
-AdminURL:'https://<tenant>-admin.sharepoint.com' -Path:Secret.json -CsvPathFile:c:\temp\tenantOutput.csv -JsonProgressFile:c:\temp\progresstenant.json

#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$AdminURL,
    [Parameter(Mandatory)][string]$SecretPath,
    [Parameter(Mandatory)][string]$CsvPathFile,
    [Parameter(Mandatory)][string]$JsonProgressFile
)


$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$Parameters = Get-Content -Raw -Path $SecretPath | ConvertFrom-Json

if ($VerbosePreference) {
    Set-PnPTraceLog -On -Level:Debug
}
else {
    Set-PnPTraceLog -Off
}

function Add-Details(
    [Parameter(Mandatory)]
    [string]$TenantUrl,
    [Parameter(Mandatory)]
    [datetime]$CreatedDate,
    [Parameter(Mandatory)]
    [string]$FileName,
    [Parameter(Mandatory)]
    [string]$CreatedBy,
    [Parameter(Mandatory)]
    [string]$WebTitle,
    [Parameter(Mandatory)]
    [string]$FilePath,
    [Parameter(Mandatory)]
    [string]$LastModifiedBy,
    [Parameter(Mandatory)]
    [datetime]$LastModifiedDate,
    [string]$EditorEmail
) {
    $detail = "" | Select-Object CreatedDate, FileName, CreatedBy, WebTitle, FilePath, LastModifiedBy, EditiorEmail, LastModifiedDate
    $detail.CreatedDate = $CreatedDate
    $detail.FileName = $FileName
    $detail.CreatedBy = $CreatedBy
    $detail.FilePath = $TenantUrl + $FilePath
    $detail.LastModifiedBy = $LastModifiedBy
    $detail.WebTitle = $WebTitle
    $detail.EditiorEmail = $EditiorEmail
    $detail.LastModifiedDate = $LastModifiedDate
    return $detail
}

function Get-EmptyFoldersForSite(
    [Parameter(Mandatory)]
    $Web,  
    [Parameter(Mandatory)]
    $Path 
) {

    $ExcludesDocLibraries = @(
        'Style Library',
        'Form Templates',
        'Site Assets'
    )

    $DocLibrary = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 -and ($ExcludesDocLibraries -notcontains $_.Title) } 

    $Uri = [System.Uri]$($Web.Url)
    $tenant = "$($Uri.Scheme)://$($Uri.host)"
    $details = @()

    $DocLibrary |
    ForEach-Object {
        $Library = $PSItem
        Write-Information -MessageData "Checking Library:$($_.Title) for site $($Web.Url)"
        $AllItems = Get-PnPListItem -PageSize 2000 -List $Library -Fields "SMTotalFileStreamSize", "Author"

        $AllItems | 
        Where-Object { $_["SMTotalFileStreamSize"] -eq 0 } |
        ForEach-Object {
            Write-Information -MessageData "Empty folder: $($_["FileLeafRef"])"

            $details += Add-Details -TenantUrl:$tenant `
                -CreatedDate:$_["Created_x0020_Date"] `
                -FileName:$_["FileLeafRef"] `
                -CreatedBy:$_.FieldValues.Author.LookupValue `
                -WebTitle: $($Web.Title) `
                -FilePath: $_["FileRef"] `
                -LastModifiedBy: $_.FieldValues.Editor.LookupValue `
                -EditorEmail: $_.FieldValues.Editor.Email `
                -LastModifiedDate: $_["Modified"]
        }
    }

    if ($details.count -gt 0) {       
        $details | Export-Csv -Path $Path -Append -NoTypeInformation
    }
}


function Get-UrlPreviouslyCompleted(
    [Parameter(Mandatory)]
    $WebUrl,
    [Parameter(Mandatory)]
    $ProgressFile 
) {
    $found = $false;

    try {
        $content = Get-Content -Path $ProgressFile -Raw | ConvertFrom-Json

        $value = $content.Urls | Where-Object { $_.Url -eq $WebUrl }
    
        if ($value) {
            $found = $true
        }
    }
    catch {
        #file doesn't exit.
    }
   
    return $found
} 

function Set-UrlToFile(
    [Parameter(Mandatory)]
    $WebUrl,  
    [Parameter(Mandatory)]
    $ProgressFile 
) {
    try {
        $content = Get-Content -Path $ProgressFile -Raw | ConvertFrom-Json   
        $toAdd = "{'Url':'" + $WebUrl + "'}"
        [System.Collections.ArrayList]$urls = $content.Urls
        $urls.Add((ConvertFrom-Json -input $toAdd))
        $content.Urls = $urls
        $content | ConvertTo-Json | Set-Content -Path:$ProgressFile -Force -Confirm:$false
    }
    catch {
        $urlJson = "{'Urls':[{'Url':'" + $WebUrl + "'}]}"
        $urlJson | Set-Content -Path:$ProgressFile -Force -Confirm:$false
    }
    
}   


Connect-PnPOnline -url:$AdminURL -AppId:$Parameters.ClientId -AppSecret:$Parameters.ClientSecret

$ExcludesSiteTemplates = @(
    'APPCATALOG#0',
    'EHS#1',
    'POINTPUBLISHINGHUB#0',
    'POINTPUBLISHINGTOPIC#0',
    'SITEPAGEPUBLISHING#0',
    'SPSMSITEHOST#0',
    'PWA#0',
    'BLANKINTERNET#0',
    'POINTPUBLISHINGPERSONAL#0',
    'SRCHCEN#0'
)

Get-PnPTenantSite -Detailed | 
Where-Object { $ExcludesSiteTemplates -notcontains $_.Template } |
ForEach-Object {
    Write-Information -MessageData "Site: $($PSItem.Url)"
    $SiteProperties = $PSItem
    $found = Get-UrlPreviouslyCompleted -WebUrl:$SiteProperties.Url -ProgressFile:$JsonProgressFile

    Write-Information -MessageData "Getting blank folders from SiteCollection $($SiteProperties.Url)"
    Connect-PnpOnline -Url:$SiteProperties.Url -AppId:$Parameters.ClientId -AppSecret:$Parameters.ClientSecret
    $web = Get-PnPWeb
    
    if (-not $found) {
        Get-EmptyFoldersForSite -Web:$web -Path:$CsvPathFile
        Set-UrlToFile -WebUrl:$SiteProperties.Url -ProgressFile:$JsonProgressFile
    }
    
    Get-PnPSubWebs -Recurse |
    ForEach-Object {
        $subWeb = $PSItem
        Write-Information -MessageData "SubSite: $($subWeb.Url)"
        $found = Get-UrlPreviouslyCompleted -WebUrl:$subWeb.Url -ProgressFile:$JsonProgressFile
        if (-not $found) {
            Get-EmptyFoldersForSite -Web:$subWeb -Path:$CsvPathFile
            Set-UrlToFile -Web:$subWeb.Url -ProgressFile:$JsonProgressFile
        }
    }
}

Write-Information -MessageData:"Complete";