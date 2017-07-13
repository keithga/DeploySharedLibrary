
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

function Get-PrivateProfileString
	(
	$Path,
	$Category,
	$Key
	)
{
	## The signature of the Windows API that retrieves INI settings
	$signature = @'
	[DllImport("kernel32.dll")]
	public static extern uint GetPrivateProfileString(
		string lpAppName,
		string lpKeyName,
		string lpDefault,
		StringBuilder lpReturnedString,
		uint nSize,
		string lpFileName);
'@

	## Create a new type that lets us access the Windows API function
	$type = Add-Type -MemberDefinition $signature -Name Win32Utils -Namespace GetPrivateProfileString -Using System.Text  -PassThru

	## Invoke the method
	Write-Verbose "ReadINI($Path [$Category] $Key)"
	$builder = New-Object System.Text.StringBuilder 1024
	$null = $type::GetPrivateProfileString($category, $key, "", $builder, $builder.Capacity, $path)
	return $builder.ToString()
}

