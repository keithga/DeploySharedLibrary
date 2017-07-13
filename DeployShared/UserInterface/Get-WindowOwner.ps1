
function Get-WindowOwner
{
<#
 .SYNOPSIS
Get the Window Owner

.DESCRIPTION
Get the Window handle of the parent $host process
Otherwise a DialogBox can appear in the background. 

.LINK
http://poshcode.org/2002

#>

Add-Type -TypeDefinition @"
using System;
using System.Windows.Forms;

public class Win32Window : IWin32Window
{
    private IntPtr _hWnd;
    
    public Win32Window(IntPtr handle)
    {
        _hWnd = handle;
    }

    public IntPtr Handle
    {
        get { return _hWnd; }
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms.dll"

    New-Object Win32Window -ArgumentList ([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle) | write-output

}
