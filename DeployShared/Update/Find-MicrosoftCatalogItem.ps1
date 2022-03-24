
function Find-MicrosoftCatalogItem {

    <#
    .SYNOPSIS
    Get the latest Cumulative update for Windows

    .DESCRIPTION
    This script will return the list of Cumulative updates for Windows 10 and Windows Server 2016 from the Microsoft Update Catalog.

    .NOTES
    Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

    .LINK
    https://support.microsoft.com/en-us/help/4000823

    .PARAMETER SearchTerm

    Search term used to query Windows Update, same as found here https://www.catalog.update.microsoft.com/Home.aspx
    
    .PARAMETER Filter
    Specify a specific search filter to change the target update behaviour. 

    If Mulitple Filters are specified, only string that match *ALL* filters will be selected.

        Cumulative - Download Cumulative updates.
        Delta - Download Delta updates.
        x86 - Download x86
        x64 - Download x64

    .PARAMETER Exclude

    Same as Filter, except used to exclude content 

    .EXAMPLE
    Get the Sept 2017 Updates for Windows 10 x86

    Find-MicrosoftCatalogItem -$SearchTerm 'windows 10 1703 2017 09 update x64' -exclude 'delta'

    .EXAMPLE

    Get the latest Cumulative Updates for Windows 10

    Find-LatestCumulativeUpdate | % { $_.KB } | Find-MicrosoftCatalogItem -exclude '(delta|arm64)'

    .EXAMPLE

    Get the latest Cumulative Updates for Windows 10 (x64) and download to the %TEMP% directory.

    Find-MicrosoftCatalogItem 'Adobe Flash x64 10 1703' | select-object -first 1 | Start-BitsTransfer -Destination $env:Temp

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)]
        [string] $SearchTerm,

        [Parameter(Mandatory=$False, HelpMessage="Windows update Catalog Search Filter.")]
        [string[]] $Filter,

        [Parameter(Mandatory=$False, HelpMessage="Windows update Catalog Search Filter.")]
        [string[]] $Exclude

    )

    Write-Verbose "Search for: $SearchTerm"
    $kbObj = Invoke-WebRequest -Uri "http://www.catalog.update.microsoft.com/Search.aspx?q=$SearchTerm" 

    $Available_KBIDs = $kbObj.InputFields | 
        Where-Object { $_.type -eq 'Button' -and $_.Value -eq 'Download' } | 
        Select-Object -ExpandProperty  ID

    $Available_KBIDs | out-string | write-verbose

    $kbGUIDs = $kbObj.Links | 
        Where-Object ID -match '_link' |
        Where-Object { $_.OuterHTML -match $filter } |
        Where-Object { -not $exclude -or -not ( $_.OuterHTML -match $exclude ) } |
        ForEach-Object { $_.id.replace('_link','') } |
        Where-Object { $_ -in $Available_KBIDs }

    $links = @()
    foreach ( $kbGUID in $kbGUIDs )
    {
        Write-Verbose "`t`tDownload $kbGUID"
        $Uri = "https://www.catalog.update.microsoft.com/DownloadDialog.aspx?updateIDs=[{%22uidInfo%22:%22$kbGUID%22,%22updateID%22:%22$kbGUID%22,%22size%22:0}]"
		
		$Links += Invoke-WebRequest -Uri $Uri | Select-8Object -ExpandProperty Content| Select-String -AllMatches -Pattern "(http[s]?\://download\.windowsupdate\.com\/[^\'\""]*)" | 
            ForEach-Object { $_.matches.value }
    }

    $Links | Select-Object -Unique | ForEach-Object { [PSCustomObject] @{ Source = $_ } } | Write-Output

}
