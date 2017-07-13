function Convert-ISOtoVHD
{
<#
.SYNOPSIS
Convert an Windows Installation ISO to VHD
.DESCRIPTION
Will mount the ISO image (if not already mounted)
.NOTES
Copyright Keith Garner, Deployment Live.
#>
    param
    (
        [parameter(Mandatory=$true)]
        [string] $ISOFile,
        [parameter(Mandatory=$true)]
        [string] $VHDFile,
        [parameter(Mandatory=$true)]
        [int]    $Index,
        [int]    $Generation = 1,
        [uint64]  $SizeBytes = 120GB,
        [switch] $Force
    )

    if ( -not ( Test-Path $ISOFile ) ) { throw "missing ISOFile: $ISOFile" }

    $OKToDismount= $False
    $FoundVolume = get-diskimage -ImagePath $ISOFile -ErrorAction SilentlyContinue | Get-Volume
    if ( -not $FoundVolume )
    {
        Mount-DiskImage -ImagePath $ISOFile -StorageType ISO -Access ReadOnly
        start-sleep -Milliseconds 250
        $FoundVolume = get-diskimage -ImagePath $ISOFile -ErrorAction SilentlyContinue | Get-Volume
        $OKToDismount= $True
    }

    if ( -not $FoundVolume )
    {
        throw "Missing ISO: $ISOfile"
    }

    $FoundVolume | Out-String | Write-Verbose
    $DriveLetter =  $FoundVolume | %{ "$($_.DriveLetter)`:" }

    if ( -not $DriveLetter ) {throw "DriveLetter not found after mounting" }
    if ( -not ( Test-Path "$DriveLetter\Sources\Install.wim" ) ) { throw "Windows Install.wim not found" }

    $StdArgs = $PSBoundParameters | get-HashTableSubset -exclude ISOFile
    Convert-WIMtoVHD -ImagePath "$DriveLetter\Sources\Install.wim" @StdArgs | Out-Default

    if ( $OKToDismount )
    {
        Dismount-DiskImage -ImagePath $ISOFile | out-string
    }

}
