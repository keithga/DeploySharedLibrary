<# 

.SYNOPSIS 
Hydration Script Module - Setup

.DESCRIPTION
Hydration Environment for MDTEx Powershell Common Modules
PrivateProfile tools (INI files)

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared

#>


function Get-MSIProperties ( $Path )
{
    if(!(Test-Path $Path))
    {
        throw "Could not find $Path"
    }
    $FullPath = (get-item $Path).FullName

    write-host "Open: $FullPath"
    $WindowsInstaller = New-Object -com WindowsInstaller.Installer
    $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase","InvokeMethod",$Null,$WindowsInstaller,@($FullPath,0))
    if ( $MSIDatabase )
    {
        $View = $MSIDatabase.GetType().InvokeMember("OpenView","InvokeMethod",$null,$MSIDatabase,"SELECT * FROM Property") 
        $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null) | out-null
        while($Record = $View.GetType().InvokeMember("Fetch","InvokeMethod",$null,$View,$null)) 
        {
            @{ $Record.GetType().InvokeMember("StringData","GetProperty",$null,$Record,1) = 
                $Record.GetType().InvokeMember("StringData","GetProperty",$null,$Record,2)}
        }
        $View.GetType().InvokeMember("Close","InvokeMethod",$null,$View,$null) | out-null
    }

}

