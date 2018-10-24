function Get-WIndowsImageFromISO {

<#
    Get some info from the ISO image and return.

#>
[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string] $ImagePath,
    [int]    $Index,
    [string] $Name
)

    $fullImagePath = get-item -Path $ImagePath | % FullName

    if ( -not ( Test-Path $FullImagePath ) ) { throw "missing ISOFile: $FullImagePath" }

    $OKToDismount= $False
    $FoundVolume = get-diskimage -ImagePath $FullImagePath -ErrorAction SilentlyContinue | Get-Volume
    if ( -not $FoundVolume ) {
        Mount-DiskImage -ImagePath $FullImagePath -StorageType ISO -Access ReadOnly
        start-sleep -Milliseconds 250
        $FoundVolume = get-diskimage -ImagePath $FullImagePath -ErrorAction SilentlyContinue | Get-Volume
        $OKToDismount= $True
    }

    if ( -not $FoundVolume ) { throw "Missing ISO: $FullImagePath" }

    $FoundVolume | Out-String | Write-Verbose
    $DriveLetter =  $FoundVolume | %{ "$($_.DriveLetter)`:" }

    if ( -not $DriveLetter ) {throw "DriveLetter not found after mounting" }
    if ( -not ( Test-Path "$DriveLetter\Sources\Install.wim" ) ) { throw "Windows Install.wim not found" }

    ###################

    if ( $index -or $name ) {
        $StdArgs = $PSBoundParameters | get-HashTableSubset -exclude ImagePath
        Get-WindowsImage -ImagePath "$DriveLetter\Sources\Install.wim" @stdargs
    } 
    else {
        Get-WindowsImage -ImagePath "$DriveLetter\Sources\Install.wim" |
            Select-Object -Property ImagePath,@{Name='Index';Expression={$_.ImageIndex}} |
            Get-WindowsImage
    }

    ###################
    
    if ( $OKToDismount ) {
        Dismount-DiskImage -ImagePath $FullImagePath | out-string
    }


}