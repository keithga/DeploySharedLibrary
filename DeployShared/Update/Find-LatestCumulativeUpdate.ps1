
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

        # 10240 - Windows 10 Version 1507 
        # 10586 - Windows 10 Version 1511 
        14393 - Windows 10 Version 1607 and Windows Server 2016
        # 15063 - Windows 10 Version 1703
        16299 - Windows 10 Version 1709
        17134 - Windows 10 Version 1803
        17763 - Windows 10 Version 1809 and Windows Server 2019
        18362 - Windows 10 Version 1903
        18363 - Windows 10 Version 1909

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
        [Parameter(Mandatory=$False, HelpMessage="Windows build number.")]
        [ValidateSet('17763','17134','16299','14393','18362','18363')]
        [string] $Build = '17763'

    )

    '4529964','4498140','4464619','4099479','4043454','4000825' | 
        %{ iwr "https://support.microsoft.com/en-us/help/$_" } | 
        % Content | 
        select-string '"([^\-\"]*)\p{Pd}(KB[0-9]*) \(OS Build ([0-9\.]*)\)"' -AllMatches | 
        % { $_.Matches } | 
        % { [pscustomobject]@{ Date = [datetime]$_.Groups[1].Value ; KB = $_.Groups[2].Value ; Build = [version]('10.0.' + $_.Groups[3].Value) } } |
        % { write-verbose $_ ; $_ } | 
        ? { $_.Build.Build -eq $Build } |
        sort -Property Date |
        select -last 1

}
