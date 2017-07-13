
<#

.SYNOPSIS 
Hydration Script Module - Profile

.DESCRIPTION
Hydration Environment for MDTEx Powershell Common Modules
PrivateProfile tools (INI files)

.NOTES
Copyright Keith Garner (KeithGa@DeploymentLive.com), All rights reserved.

.LINK
https://github.com/keithga/DeployShared

#>

function Set-MDTCustomSettings
(
    $DPShare,
    $Category,
    $Key,
    $Value
)
{
    ## The signature of the Windows API that retrieves INI settings
    $signature = @'
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern bool WritePrivateProfileString(
       string lpAppName,
       string lpKeyName,
       string lpString,
       string lpFileName);
'@

    ## Create a new type that lets us access the Windows API function
    $type = Add-Type -MemberDefinition $signature -Name Win32Utils -Namespace WritePrivateProfileString -PassThru

    ## Invoke the method
    Write-Verbose "WriteINI($DPShare\control\customsettings.ini [$Category] $Key) = $Value"
    $type::WritePrivateProfileString($category, $key, $Value, "$DPShare\control\customsettings.ini") | out-null
}
