$sourceUrl = "https://tenant1.sharepoint.com/sites/test"
$destinationUrl = "https://tenant2.sharepoint.com/sites/test"

#Connect to the sharepoint environment
Connect-PnPOnline -url $sourceUrl -UseWebLogin
$WebTitle = (Get-PnPWeb).Title
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
    if ($listItems.FieldValues["ContentTypeId"].StringValue.StartsWith("0x0101009D1CB255DA76424F860D91F20E6C4118")) {
        $pageXml = [xml](Export-PnPClientSidePage -Identity $items.FieldValues["FileLeafRef"])
        $pageXElement = [System.Xml.Linq.XElement]::Parse($pageXml.Provisioning.Templates.ProvisioningTemplate.ClientSidePages.ClientSidePage.OuterXml)
        $clientSidePages.Add($pageXElement)
    }
}
$fileName = "Source_" + $WebTitle + ".xml"
$template.save($fileName)

Connect-PnpOnline -url $destinationUrl -UseWebLogin
Apply-PnPProvisioningTemplate -Path $fileName
