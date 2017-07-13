
function New-ISOImage
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory=$true)]
        [string] $SourcePath,

        [parameter(Mandatory=$true)]
        [string] $ISOTarget,

        [parameter(Mandatory=$false)]
        [ValidateSet("EFISys", "EFISys_noprompt")]
        [string] $EFIBoot
    )

    $OSCDPath = ( get-ADKPath ) + '\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg'

    if ( -not ( test-path "$OSCDPath\oscdimg.exe" ) ) { throw "Missing OSCDIMG.exe" }

    if ( $EFIBoot )
    {
        $BootData = """-bootdata:2#p0,e,b$OSCDPath\etfsboot.com#pEF,e,b$OSCDPath\$($EFIBOOT).bin"""
    }

    write-verbose  "$OSCDPath\oscdimg.exe -u2 -udfver102 -m -o -h -w4 '$BootData' $SourcePath $ISOTarget"
    &               $OSCDPath\oscdimg.exe -u2 -udfver102 -m -o -h -w4 "$BootData" $SourcePath $ISOTarget  | Out-String | write-verbose

    write-verbose "Grant Permissions for file (for Hyper-V, just in case)."
    & icacls.exe $ISOTarget /grant Everyone:F    | Out-String | write-verbose

}
