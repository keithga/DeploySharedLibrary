
function Save-XMLFile
{
    <#

     .SYNOPSIS
    Save an XML file

    .DESCRIPTION
    Save an XML Document to a file

    .NOTES
    Copyright Keith Garner, All rights reserved.

    .EXAMPLE
    Take an XML file as a piped input and write to .\test.xml

    "<foo><bar /></foo>" -as [xml] | Save-XMLFile -Path .\test.xml

    #>
    param
    (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Xml.XmlDocument] $XML,
        [parameter(Mandatory=$true,Position=0)]
        [string] $Path
    )
    
    $XML.Save($Path)
}

