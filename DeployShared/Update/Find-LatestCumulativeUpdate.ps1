
function Find-LatestCumulativeUpdate {

    <#
    .SYNOPSIS
    Find the latest Cumulative update for Windows

    .DESCRIPTION
    This script will return the KB article for the latest Cumulative updates for Windows 10 and Windows Server 2016 from the Microsoft Update Catalog.

    .NOTES
    Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

    .LINK
    https://support.microsoft.com/en-us/help/4000823

    .PARAMETER Build
    Windows 10 Build Number used to filter avaible Downloads

        10240 - Windows 10 Version 1507 
        10586 - Windows 10 Version 1511 
        14393 - Windows 10 Version 1607 and Windows Server 2016
        15063 - Windows 10 Version 1703
        16299 - Windows 10 Version 1709

    .EXAMPLE
    Get the latest Cumulative Update for Windows 10 x64

    .\Get-LatestUpdate.ps1 

    .EXAMPLE
    Get the latest Cumulative Update for Windows 10 x86

    Get the latest Cumulative Update for Windows Server 2016

    .\Get-LatestUpdate.ps1 -Build 14393

    .EXAMPLE

    Get the latest Cumulative Updates for Windows 10 (both x86 and x64) and download to the %TEMP% directory.

    .\Get-LatestUpdate.ps1 | Start-BitsTransfer -Destination $env:Temp

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False, HelpMessage="JSON source for the update KB articles.")]
        [string] $StartKB = 'https://support.microsoft.com/app/content/api/content/asset/en-us/4000816',

        [Parameter(Mandatory=$False, HelpMessage="Windows build number.")]
        [ValidateSet('16299','15063','14393','10586','10240')]
        [string] $BUild = '16299'

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

    Write-Verbose "Downloading $StartKB to retrieve the list of updates."

    Invoke-WebRequest -Uri $StartKB |
        Select-Object -ExpandProperty Content |
        ConvertFrom-Json |
        Select-Object -ExpandProperty Links |
        Where-Object level -eq 2 |
        Where-Object text -match $BUild |
        Select-LatestUpdate |
        Select-Object -First 1 

}