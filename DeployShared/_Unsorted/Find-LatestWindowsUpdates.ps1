
function Find-LatestWindowsUpdates {

    <#
    .SYNOPSIS
    Get the latest Cumulative update for Windows

    .DESCRIPTION
    This script will return the list of Cumulative updates for Windows 10 and Windows Server 2016 from the Microsoft Update Catalog.

    .NOTES
    Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

    .LINK
    https://support.microsoft.com/en-us/help/4000823

    .EXAMPLE
    Get the latest Cumulative Update for Windows 10 x64

    .\Get-LatestUpdate.ps1 

    .PARAMETER Build
    Windows 10 Build Number used to filter avaible Downloads

        10240 - Windows 10 Version 1507 
        10586 - Windows 10 Version 1511 
        14393 - Windows 10 Version 1607 and Windows Server 2016
        15063 - Windows 10 Version 1703

    .PARAMETER Filter
    Specify a specific search filter to change the target update behaviour. The default will only Cumulative updates for x86 and x64.

    If Mulitple Filters are specified, only string that match *ALL* filters will be selected.

        Cumulative - Download Cumulative updates.
        Delta - Download Delta updates.
        x86 - Download x86
        x64 - Download x64

    .EXAMPLE
    Get the latest Cumulative Update for Windows 10 x86

    .\Get-LatestUpdate.ps1 -Filter 'Cumulative','x86'

    .EXAMPLE

    Get the latest Cumulative Update for Windows Server 2016

    .\Get-LatestUpdate.ps1 -Filter 'Cumulative','x64' -Build 14393

    .EXAMPLE

    Get the latest Cumulative Updates for Windows 10 (both x86 and x64) and download to the %TEMP% directory.

    .\Get-LatestUpdate.ps1 | Start-BitsTransfer -Destination $env:Temp

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False, HelpMessage="JSON source for the update KB articles.")]
        [string] $StartKB = 'https://support.microsoft.com/api/content/asset/4000816',

        [Parameter(Mandatory=$False, HelpMessage="Windows build number.")]
        [ValidateSet('15063','14393','10586','10240')]
        [string] $BUild = '15063',

        [Parameter(Mandatory=$False, HelpMessage="Windows update Catalog Search Filter.")]
        [ValidateSet('x64','x86','Cumulative','Delta',$null)]
        [string[]] $Filter = @( "Cumulative" )

    )

    #region Support Routine

    Function Select-LatestUpdate {
        [CmdletBinding(SupportsShouldProcess=$True)]
        Param(
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
            $Updates
        )
        Begin { 
            $MaxObject = $null
            $MaxValue = [version]::new("0.0")
        }
        Process {
            ForEach ( $Update in $updates ) {
                Select-String -InputObject $Update -AllMatches -Pattern "(\d+\.)?(\d+\.)?(\d+\.)?(\*|\d+)" |
                ForEach-Object { $_.matches.value } |
                ForEach-Object { $_ -as [version] } |
                ForEach-Object { 
                    if ( $_ -gt $MaxValue ) { $MaxObject = $Update; $MaxValue = $_ }
                }
            }
        }
        End { 
            $MaxObject | Write-Output 
        }
    }

    #endregion

    #region Find the KB Article Number

    Write-Verbose "Downloading $StartKB to retrieve the list of updates."
    $kbID = Invoke-WebRequest -Uri $StartKB |
        Select-Object -ExpandProperty Content |
        ConvertFrom-Json |
        Select-Object -ExpandProperty Links |
        Where-Object level -eq 2 |
        Where-Object text -match $BUild |
        Select-LatestUpdate |
        Select-Object -First 1

    #endregion

    #region get the download link from Windows Update

    Write-Verbose "Found ID: KB$($kbID.articleID)"
    $kbObj = Invoke-WebRequest -Uri "http://www.catalog.update.microsoft.com/Search.aspx?q=KB$($KBID.articleID)" 

    $Available_KBIDs = $kbObj.InputFields | 
        Where-Object { $_.type -eq 'Button' -and $_.Value -eq 'Download' } | 
        Select-Object -ExpandProperty  ID

    $Available_KBIDs | out-string | write-verbose

    $kbGUIDs = $kbObj.Links | 
        Where-Object ID -match '_link' |
        Where-Object { $_.OuterHTML -match ( "(?=.*" + ( $Filter -join ")(?=.*" ) + ")" ) } |
        ForEach-Object { $_.id.replace('_link','') } |
        Where-Object { $_ -in $Available_KBIDs }

    foreach ( $kbGUID in $kbGUIDs )
    {
        Write-Verbose "`t`tDownload $kbGUID"
        $Post = @{ size = 0; updateID = $kbGUID; uidInfo = $kbGUID } | ConvertTo-Json -Compress
        $PostBody = @{ updateIDs = "[$Post]" } 
        Invoke-WebRequest -Uri 'http://www.catalog.update.microsoft.com/DownloadDialog.aspx' -Method Post -Body $postBody |
            Select-Object -ExpandProperty Content |
            Select-String -AllMatches -Pattern "(http[s]?\://download\.windowsupdate\.com\/[^\'\""]*)" | 
            Select-Object -Unique |
            ForEach-Object { [PSCustomObject] @{ Source = $_.matches.value } }  # Output for BITS
    }

    #endregion

}