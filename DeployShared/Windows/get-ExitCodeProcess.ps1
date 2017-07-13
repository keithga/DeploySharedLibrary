
function Get-ExitCodeProcess 
{
<#
Start-process may not return the ExitCode, this function can extract it.
http://stackoverflow.com/questions/10262231/obtaining-exitcode-using-start-process-and-waitforexit-instead-of-wait

#>
    param( $Handle )

    $code = "[DllImport(""kernel32.dll"")] public static extern int GetExitCodeProcess(IntPtr hProcess, out Int32 exitcode);"
    $type = Add-Type -MemberDefinition $code -Name "Win32" -Namespace Win32 -PassThru
    [Int32]$exitCode = 0
    $type::GetExitCodeProcess($Handle, [ref]$exitCode) | out-null
    $exitCode | Write-Output
}

