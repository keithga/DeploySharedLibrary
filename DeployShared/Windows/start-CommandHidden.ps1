Function start-CommandHidden 
{

<# 
.SYNOPSIS
Run a Console program Hidden and capture the output.

.PARAMETER
FilePath - Program Executable

.PARAMETER
ArgumentList - Array of arguments

.PARAMETER
RedirectStandardInput - text file for StdIn

.NOTES
Will output StdOut to Verbose.
#>

    param
    (
        [string] $FilePath,
        [string[]] $ArgumentList,
        [string] $RedirectStandardInput
    )

    $StartArg = @{
        RedirectStandardError = [System.IO.Path]::GetTempFileName()
        RedirectStandardOutput = [System.IO.Path]::GetTempFileName()
        PassThru = $True
    }

    $StartArg | out-string |  write-verbose
    $ArgumentList | out-string |write-verbose

    $prog = start-process -WindowStyle Hidden @StartArg @PSBoundParameters

    $Prog.WaitForExit()

    get-content $StartArg.RedirectStandardOutput | Write-Output
    get-content $StartArg.RedirectStandardError  | Write-Error

    $StartArg.RedirectStandardError, $StartArg.RedirectStandardOutput, $RedirectStandardInput | Remove-Item -ErrorAction SilentlyContinue

}