<#
.SYNOPSIS
Exports Modern pages except the welcome page and returns a pnp Provisioning template
You need to connect using Connect-pnponline before calling the function.

.EXAMPLE
./Get-ExportClientSidePages.ps1

#>
function Get-ExportClientSidePages {
    $Web = Get-PnPWeb
    $Context = Get-PnPContext
    $Context.Load($Web)
    Invoke-PnPQuery

    # Define global constants
    $pnp = [System.Xml.Linq.XNamespace]"http://schemas.dev.office.com/PnP/2018/07/ProvisioningSchema"

    #Get the site tempalte as an XML DOM document
    $templateXml = Get-PnPProvisioningTemplate -Handlers PageContents
    $template = [System.Xml.Linq.XElement]::Parse($templateXml)
    $clientSidePages = $template.Element($pnp + [System.Xml.Linq.XName]"Templates").Element($pnp + [System.Xml.Linq.XName]"ProvisioningTemplate").Element($pnp + [System.Xml.Linq.XName]"ClientSidePages")

    #get all pages to export
    $listItems = Get-PnpListItem -list "Site Pages"

    #Add every single page to the target template
    foreach ($items in $listItems) {
        if ($items.FieldValues["ContentTypeId"].StringValue.StartsWith("0x0101009D1CB255DA76424F860D91F20E6C4118")) {
        
            if ($Web.WelcomePage.EndsWith($items.FieldValues["FileLeafRef"])){
                #Welcome page already included from getting ProvisioningTemplate PageContents.
                continue;
            }
        
            $pageXml = [xml](Export-PnPClientSidePage -Identity $items.FieldValues["FileLeafRef"])
            $pageXElement = [System.Xml.Linq.XElement]::Parse($pageXml.Provisioning.Templates.ProvisioningTemplate.ClientSidePages.ClientSidePage.OuterXml)
            $clientSidePages.Add($pageXElement)
        }
    }
    
    Write-Output $template
}





