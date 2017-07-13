
<#
.SYNOPSIS 
Create a New MDT Deployment Share

.DESCRIPTION

Create a new MDT Deployment Share with the following permissions:
* Give the Network Share Full Read/Write access to Authenticated Users
* Give the local File Folder 
    Administrator: Full 
    Authenticated users: Read
* Create a Logs Folder and grant special premissions 

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
    https://keithga.wordpress.com/2015/01/06/security-week-locking-down-your-deployment/

#>

function New-MDTDeploymentShare
{
    param(

        [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share.")]
        [string] $DeploymentLocalPath, # Example: c:\DeploymentShare

        [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share from network.")]
        [string] $DeploymentNetShare, #Example: DeploymentShare$

        [parameter(mandatory=$true,HelpMessage="Location of Local Deployment Share Name.")]
        [string] $DeploymentName,  # Example: 

        [string] $DPDrive = "DS001"

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

    if ( ! ( Test-Path $DeploymentLocalPath\Logs ) ) 
    {
        new-item -Path $DeploymentLocalPath\Logs -type directory -Force |out-string |write-Verbose
        cacls $DeploymentLocalPath\Logs /S:"D:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICIIO;FA;;;CO)(A;;0x100004;;;AU)" |out-string |write-Verbose
    }

    "### Create a new Deployment Share" | write-Verbose

    if (-not (gwmi win32_share -filter "name='$DeploymentNetShare'") )
    {
        "Create Share $DeploymentNetShare=$DeploymentLocalPath /GRANT:NT Authority\Authenticated Users,Full" | out-string |write-Verbose
        net share "$DeploymentNetShare=$DeploymentLocalPath" "/GRANT:NT Authority\Authenticated Users,Full" |out-string |write-Verbose
    }

    "### Create new MDT share $DPDrive [$DeploymentLocalPath] [$DeploymentName]" |write-Verbose
    New-PSDrive -Name $DPDrive -PSProvider MDTProvider -Scope global -Root $DeploymentLocalPath -description $DeploymentName | add-MDTPersistentDrive |out-string |write-Verbose

}

