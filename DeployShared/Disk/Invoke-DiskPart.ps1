
function Invoke-DiskPart
{
    <#
    Invoke diskpart commands ( passed as a string array )
    #>
    
    param( [string[]] $Commands )

    $Commands | out-string | write-verbose
    $DiskPartCmd = [System.IO.Path]::GetTempFileName()
    $Commands | out-file -encoding ascii -FilePath $DiskPartCmd
    start-CommandHidden -FilePath "DiskPart.exe" -RedirectStandardInput $DiskPartCmd
}

