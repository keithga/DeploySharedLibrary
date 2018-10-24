
function Invoke-DISM
{
<#

Many of the commands in the Powershell DISM module are SLOW, call dism.exe directly to speed things up.

example:

$result = Invoke-Dism -ArgumentList "/capture-image /imagefile:c:\users\keith.garner\desktop\foo.wim /capturedir:g:\ /name:foo /compress:none" -verbose

#>
    [cmdletbinding()]
    param (
        [switch] $NoNewWindow,
        [string] $WorkingDirectory = '.',
        [string] $LogPath,
        [string] $Description = 'Dism',
        [int]    $LogLevel = 3,
        [system.diagnostics.ProcessWindowStyle] $WindowStyle = [system.diagnostics.ProcessWindowStyle]::Hidden,
        [Parameter(Mandatory = $true,ValueFromRemainingArguments=$true)] 
        [string[]] $ArgumentList
    )

    function Format-LogData {
        param ( 
            [string] $Description = 'dism',
            [string] $LogFile,
            [int] $ID = 1,
            [ref] $index
        )

        $ShowBlanks = $True
        $logData = get-content $LogFile
        if ( $logData ) {
            while ( $index.Value -lt $logdata.count ) {
                if ( $logData[$index.Value] -match "(100|\d?\d)\.?\d?\%" ) {
                    write-progress $Description -ID $ID -PercentComplete $Matches[1]
                    $ShowBlanks = $false
                }
                elseif ( ( $logData[$index.Value].length -gt 0 ) -or $ShowBlanks ) {
                    write-output $logData[$index.Value]
                    $ShowBlanks = $True
                }
                $index.Value += 1
            }
            if ( (-not $showBlanks) -and ( $index.value -gt 1 ) ) {
                $index.value -= 1
            }
        }
    }

    if ( -not $LogPath ) {
        $LogPath = [IO.Path]::GetTempFileName() + ".$($Description).log"
    }

    $ProcessArgs = @{
        PassThru = $True
        FilePath = "dism.exe"
        RedirectStandardError = [IO.Path]::GetTempFileName()
        RedirectStandardOutput = [IO.Path]::GetTempFileName()
        WindowStyle = $WindowStyle
        ArgumentList = $ArgumentList + " /LogLevel:$LogLevel /LogPath:""$($LogPath)"""
        NoNewWindow = $NoNewWindow.IsPresent
        WorkingDirectory = $WorkingDirectory

    }

    if ( [string]::IsNullOrEmpty($ProcessArgs.WorkingDirectory) ) { $ProcessArgs.WorkingDirectory = '.' }

    $ProcessArgs | out-string | write-verbose
    $DismRun = start-process @ProcessArgs
    $handle = $dismRun.Handle

    [int]$i = 0
    while (!$DismRun.HasExited) {
        Format-LogData -index ([ref]$i) -LogFile $ProcessArgs.RedirectStandardOutput -Description $Description -ID $DismRun.ID | write-verbose
        start-sleep -Milliseconds 200
    }
    Format-LogData -index ([ref]$i) -LogFile $ProcessArgs.RedirectStandardOutput  -Description $Description | write-verbose
    write-progress  $Description -id $DismRun.ID -Completed

    write-verbose "Flush Errors"
    get-content $ProcessArgs.RedirectStandardError | write-verbose

    $exitcode = Get-ExitCodeProcess -Handle $handle

    if ( $exitcode -gt 0 ) {
        get-content $ProcessArgs.RedirectStandardOutput | select-object -last 20 | write-warning
    }

    Write-Verbose "Cleanup"
    remove-item $ProcessArgs.RedirectStandardError,$ProcessArgs.RedirectStandardOutput

    write-verbose "Result: $exitcode"
    $exitcode | write-output

}

