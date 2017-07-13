
<#

Powershell tools for the manipulation and creation of Windows Unattend.xml files

Goal is to provide a native language for XML files within powershell:

UNATTEND  {
    SETTINGS generalize  {
        COMPONENT Microsoft-Windows-Shell-Setup {
            ELEMENT DoNotCleanTaskBar {
                VALUE $True.ToString().ToLower()
            }
        }
    }
} | Save-XMLFile -path '.\Unattend.xml'

Copyright Keith Garner, DeploymentLive.com

#>

function UNATTEND
{
    param
    (
        [parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [XML] $XML,
        [parameter(Mandatory=$true,Position=0)]
        [scriptblock] $ScriptBlock
    )

    if ( -not $XML ) { $XML = '<unattend xmlns="urn:schemas-microsoft-com:unattend" />' -as [XML] }

    Write-verbose "<unattend>"
    invoke-command $ScriptBlock

    $XML | write-output 
}

function SETTINGS
{
    param
    (
        [parameter(Mandatory=$true,Position=0)]
        [ValidateSet("auditSystem","auditUser","generalize","offlineServicing","oobeSystem","specialize","windowsPE")]
        [string] $Pass,

        [parameter(Mandatory=$true,Position=1)]
        [scriptblock] $ScriptBlock
    )

    Write-verbose "  <settings pass=""$Pass"">"

    $ns = @{urn ="urn:schemas-microsoft-com:unattend"; wcn = "http://schemas.microsoft.com/WMIConfig/2002/State" }
    $Xpath = "/urn:unattend/urn:settings[@pass='$pass']"
    if ( -not ( Select-Xml -Xml $XML -Namespace $ns -XPath $xpath ) )
    {
        write-verbose "Create <settings pass=""$Pass"">"
        $NewSettings = $XML.CreateElement('settings',$ns.urn)
        $NewSettings.SetAttribute('pass',$Pass) | out-null
        $CurrentSettings = $XML.DocumentElement.AppendChild($NewSettings)
    }
    else
    {
        $CurrentSettings = Select-Xml -Xml $XML -Namespace $ns -XPath $xpath | Select-object -ExpandProperty Node
    }

    invoke-command $ScriptBlock
}

function COMPONENT
{
    param (
        [parameter(Mandatory=$true,Position=0)]
        [string] $Name,

        [ValidateSet("x86","amd64")]
        [string] $Architecture = 'amd64',

        [parameter(Mandatory=$true,Position=1)]
        [scriptblock] $ScriptBlock
    )

    Write-verbose "    <component name=""$name"" processorArchitecture""$architecture"">"
    $Xpath = "urn:component[@name = '$Name' and @processorArchitecture = '$architecture']"
    if ( -not (Select-Xml -Xml $CurrentSettings -Namespace $ns -XPath $Xpath ) ) 
    {
        write-verbose "Create <component name=""$name"" processorArchitecture""$architecture"">"
        $newComponent = $xml.CreateElement('component',$ns.urn)
        $newComponent.SetAttribute('name',$name) | out-null
        $newComponent.SetAttribute('processorArchitecture',$architecture) | out-null
        $newComponent.SetAttribute('publicKeyToken','31bf3856ad364e35') | out-null
        $newComponent.SetAttribute('language','neutral') | out-null
        $newComponent.SetAttribute('versionScope','nonSxS') | out-null
        $newComponent.SetAttribute('xmlns:wcm',$ns.wcn) | out-null
        $newComponent.SetAttribute('xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance') | out-null
        $currentElement = $CurrentSettings.AppendChild($newComponent)
    }
    else
    {
        $currentElement = Select-Xml -Xml $CurrentSettings -Namespace $ns -XPath $Xpath | Select-object -ExpandProperty Node
    }

    invoke-command $scriptBlock

}

FUNCTION ELEMENT
{
    param (
        [parameter(Mandatory=$true,Position=0)]
        [string] $Name,

        [string[]] $Attributes,
        [switch] $ForceNew,
        [switch] $TypeAdd,
        [string] $Namespace,
        [string] $XPath = "urn:$($name)",

        [parameter(Position=1,ParameterSetName='ChildScript')]
        [scriptblock] $ScriptBlock,

        [parameter(Position=1,ParameterSetName='ChildValue')]
        [string] $Value

    )

    Write-Verbose "      <$Name />"

    if ( $TypeAdd )
    {
        # For elements like <RunSynchronousCommand> that require a wcm:action="add" attribute
        $Attributes += 'action=add' 
        $Namespace = $ns.wcn
    }

    if ( -not (Select-Xml -Xml $currentElement -Namespace $ns -XPath $Xpath ) -or $ForceNew ) 
    {
        $newComponent = $xml.CreateElement($name,$ns.urn)
        foreach ( $attribute in $Attributes ) 
        { 
            $newComponent.SetAttribute( $attribute.Split('=')[0], $NameSpace, $attribute.Split('=')[1] ) | out-null
        }
        $currentElement = $currentElement.AppendChild($newComponent)
    }
    else
    {
        $currentElement = Select-Xml -Xml $currentElement -Namespace $ns -XPath $Xpath | Select-object -ExpandProperty Node -First 1
    }

    if ( $Value ) 
    { 
        $CurrentElement.InnerText = $Value
    }
    elseif ( $ScriptBlock ) 
    {
        invoke-command $scriptBlock
    }
    else
    {
        write-warning "Does not contain either a Value or a Scirptblock"
    }

}

FUNCTION PASSWORD
{
    param (
        [parameter(Mandatory=$true,Position=0)]
        [string] $Name,

        [bool]   $PlainText = $false,

        [parameter(Mandatory=$True,Position=1)]
        [string] $Password

    )

    ELEMENT -name $Name -scriptblock {
        if ( $PlainText )
        {
            ELEMENT Value $Password 
        }
        else
        {
            $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Password + $Name)
            ELEMENT "Value" ([Convert]::ToBase64String($Bytes) -as [string])
        } 
        ELEMENT PlainText $PlainText.ToString().ToLower()
    }

}