
<#
.SYNOPSIS 
Copy one deployment share to another 

.DESCRIPTION
Copy a template to a new deployment share.

(Note this script will copy *OVER* customsettings.ini, bootstrap.ini, and settings.xml, so best to use only on empty targets.

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

        [parameter(mandatory=$true,HelpMessage="Location of Template Deployment Share.")]
        [string] $SourcePath,   # Example: c:\DeploymentTemplate

        [string[]] $CopyDirectories = "scripts","tools","winpe.x86","winpe.x64", "`$OEM`$" 

    )

    "Add MDT Source Share DS00D $SourcePath" | write-Verbose
    new-PSDrive -Name DS00D -PSProvider MDTProvider -Root $DeploymentLocalPath -Description "MDT Source Share" -scope Script |out-string |write-verbose
    
    "Add MDT Source Share DS00S $SourcePath" | write-Verbose
    new-PSDrive -Name DS00S -PSProvider MDTProvider -Root $SourcePath -Description "MDT Source Share" -scope Script |out-string |write-verbose

    foreach ( $Folder in "Applications", "Operating Systems", "Out-of-Box Drivers", "Packages", "Task Sequences", "Selection Profiles" )
    {
        "Copy [DS00S`:\$Folder] to [DS00D`:\$Folder]" | write-verbose
        Copy-Item -Path "DS00S`:\$Folder" -Destination "DS00D`:\$Folder" -Recurse | Out-String |Write-Verbose
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
