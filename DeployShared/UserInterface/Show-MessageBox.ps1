function Show-MessageBox
{
<#
 .SYNOPSIS
Display a MessageBox()

.DESCRIPTION
Display a message box with various parameters

.PARAMETER Message
    Body of Messagebox text

.PARAMETER Title
    Caption of Messagebox

.PARAMETER Buttons
    Type of buttons

    0 OK button only 
    1 OK and Cancel buttons 
    2 Abort, Retry, and Ignore buttons 
    3 Yes, No, and Cancel buttons 
    4 Yes and No buttons 
    5 Retry and Cancel buttons 

.PARAMETER Icon
    Type of Icon, one of:

    16 Stop sign 
    32 Question mark 
    48 Exclamation point 
    64 Information (i) icon 

.OUTPUTS
    Returns a [System.Windows.Forms.DialogResult] object, can be one of:

    1 OK 
    2 Cancel 
    3 Abort 
    4 Retry 
    5 Ignore 
    6 Yes 
    7 No 

.EXAMPLE
    Show-MessageBox "Hello World"

.EXAMPLE
    (Show-MessageBox "Do you like Ice Cream?" -Buttons 4) -eq 6

.NOTES
Copyright Keith Garner, All rights reserved.

#>

    Param(
        [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [String] $Message,
        [String] $Title,
        [ValidateRange(0,5)]
        [int] $Buttons = 0,
        [ValidateRange(16,64)]
        [int] $Icons = 0
    )

    Write-verbose "MessageBox('$Message','$Title')"
    [System.Windows.Forms.MessageBox]::Show((Get-WindowOwner),$Message,$Title,$Buttons,$Icons) | Write-Output
    
}
