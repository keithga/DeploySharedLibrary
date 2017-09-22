
function Add-ImageToUpdate {
<#

.EXAMPLE

f:\PS> Add-ImageToUpdate -Images f:\isos\*.iso -verbose | Export-CliXML -path f:\ISO\Config.xml

#>
[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string[]] $Images
    )


    foreach ($Image in get-childitem -Path $Images ) {

        if ( -not ( Test-Path $Image ) ) { throw "Missing $Image" } 

        $ImageDetail = Get-WindowsImageFromISO $Image.fullname |
            where-object { $_ -is [Microsoft.Dism.Commands.WimImageInfoObject] } | 
            Select-object ImageIndex,EditionID,ImageName,Architecture,Version,ModifiedTime,Languages

        if ( $ImageDetail.count -gt 1 ){
            $result = $ImageDetail | Out-GridView -OutputMode Single 
        }
        elseif ( $ImageDetail ) {
            $Result =  $ImageDetail
        }

        $result | Out-String | write-verbose

        $result | select-object -first 1 -Property *,@{name='iso';expression={$Image.FullName}} | Write-Output
    }

}

