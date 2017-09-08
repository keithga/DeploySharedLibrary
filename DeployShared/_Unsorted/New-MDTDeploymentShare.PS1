
<#
.SYNOPSIS 
Hydration Script for MDTEx

.DESCRIPTION
_TEMPLATE_

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared

#>

function New-MDTDeploymentShare
{
    param(

        [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share.")]
        [string] $DeploymentLocalPath, # Example: c:\DeploymentShare

        [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share from network.")]
        [string] $DeploymentNetShare, #Example: DeploymentShare$

        [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share from network.")]
        [string] $DeploymentName,  # Example: 

        [string] $DPDrive = "DS001",

        [string] $SourcePath = "$PsScriptROot\..\..\..\templates\Distribution",

        [parameter(ValueFromRemainingArguments=$true)] $Remaining

    )

    "### Create a new Deployment Folder" | write-Verbose

    if ( ! (Test-Path $DeploymentLocalPath ) )
    {
        "Clean Persistent Shares" | write-Verbose
        Get-MDTPersistentDrive | Where-Object Name -eq $DPDrive | Where-Object Path -eq $DeploymentLocalPath | %{ Remove-MDTPersistentDrive -name $_.Name }

        "Create Local Deployment Path: $DeploymentLocalPath" |write-Verbose
        new-item -Path $DeploymentLocalPath -type directory -Force |out-string |write-Verbose
        icacls $DeploymentLocalPath /grant "NT AUTHORITY\Authenticated Users:(OI)(CI)(RX)" |out-string |write-Verbose
    }

    "### Create a new Deployment Share" | write-Verbose

    if (-not (gwmi win32_share -filter "name='$DeploymentNetShare'") )
    {
        "Create Share $DeploymentNetShare=$DeploymentLocalPath /GRANT:NT Authority\Authenticated Users,Full" | out-string |write-Verbose
        net share "$DeploymentNetShare=$DeploymentLocalPath" "/GRANT:NT Authority\Authenticated Users,Full" |out-string |write-Verbose
    }

    "### Create new MDT share $DPDrive [$DeploymentLocalPath] [$DeploymentName]" |write-Verbose
    New-PSDrive -Name $DPDrive -PSProvider MDTProvider -Scope global -Root $DeploymentLocalPath -description $DeploymentName | add-MDTPersistentDrive |out-string |write-Verbose

    if ( $SourcePath ) 
    {
        "Add MDT Source Share DS00S $SourcePath" | write-Verbose
        new-PSDrive -Name DS00S -PSProvider MDTProvider -Root $SourcePath -Description "MDT Source Share" -scope Script |out-string |write-verbose

        foreach ( $Folder in "Applications", "Operating Systems", "Out-of-Box Drivers", "Packages", "Task Sequences", "Selection Profiles" )
        {
            "Copy [DS00S`:\$Folder] to [$($DPDrive)`:\$Folder]" | write-verbose
            Copy-Item -Path "DS00S`:\$Folder" -Destination "$($DPDrive)`:\$Folder" -Recurse | Out-String |Write-Verbose
        }

        foreach ( $File in "CustomSettings.ini","BootStrap.ini","settings.xml")
        {
            "Copy [$File]" | write-Verbose
            copy-item "$SourcePath\Control\$File" "$DeploymentLocalPath\Control" | write-verbose
        }

        foreach ( $directory in "scripts","tools","winpe.x86","winpe.x64", "`$OEM`$" )
        {
            copy-item -recurse "$SourcePath\$directory\*" "$DeploymentLocalPath\$directory" -Force -ErrorAction SilentlyContinue | write-verbose
        }

    }

    [XML]$Settings = get-content "$DeploymentLocalPath\control\Settings.xml"

    # $Settings.Settings.'Boot.x64.ExtraDirectory' = "%DEPLOYROOT%\WinPE.x64"
    # $Settings.Settings.'Boot.x86.ExtraDirectory' = "%DEPLOYROOT%\WinPE.x86"
    $Settings.Settings.'Boot.x64.IncludeAllDrivers' = "True"
    $Settings.Settings.'Boot.x86.IncludeAllDrivers' = "True"
    $Settings.Settings.'Boot.x64.SelectionProfile' = "_WinPE"
    $Settings.Settings.'Boot.x86.SelectionProfile' = "_WinPE"

    $Settings.Save("$DeploymentLocalPath\control\Settings.xml")


}
