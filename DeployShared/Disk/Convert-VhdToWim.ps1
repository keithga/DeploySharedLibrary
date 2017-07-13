
function Convert-VHDtoWIM
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory=$true)]
        [string] $ImagePath,
        [parameter(Mandatory=$true)]
        [string] $VHDFile,
        [string] $Name,
        # [string] $Description,
        [ValidateSet("Fast", "Max", "None")]
        [string] $CompressionType = 'fast',
        [switch] $Turbo = $true,
        [switch] $Force
    )

    Write-Verbose "WIM [$ImagePath]  FROM  VHD [$VHDFile]"
    Write-Verbose "SizeBytes=$SIzeBytes  Generation:$Generation Force: $Force Index: $Index"

    ####################################################

    Write-verbose "mount the VHD file"

    $NewDisk = Mount-VHD -Passthru -Path $VHDFile
    $NewDisk | Out-String | Write-Verbose
    $NewDiskNumber = Get-VHD $VhdFile | Select-Object -ExpandProperty DiskNumber

    if ( -not $NewDiskNumber )
    {
        throw "Unable to Mount VHD File"
    }

    Write-Verbose "Initialize Disk"

    $CapturePath = $NewDisk | get-partition | get-volume | where-object FileSystem -eq 'NTFS' | 
        sort -Property Size | Select-Object -last 1 | Foreach-object { $_.DriveLetter + ":" }

    if ( -not $CapturePath ) 
    {
        $newDisk | get-partition | where size -gt 32GB | select-object -first  1 | Add-PartitionAccessPath -AssignDriveLetter
        $CapturePath = $NewDisk | get-partition | where-object { $_.DriveLetter } | 
            sort -Property Size | Select-Object -last 1 | Foreach-object { $_.DriveLetter + ":" }
    }

    write-verbose "Capture Path: $CapturePath"

    if ( -not $CapturePath ) { throw "Missing Capture path for Disk $NewDisk" }

    ####################################################

    write-Verbose "Capture Windows Image /ImageFile:$ImagePath /CaptureDir:$CapturePath"
    $Command = "/capture-image ""/ImageFile:$ImagePath"" ""/CaptureDir:$CapturePath"" ""/Name:$Name"" /Compress:$CompressionType"
    if ( Test-Path "C:\Program Files\Microsoft Deployment Toolkit\Templates\Wimscript.ini") { 
        $Commmand = $Command + " ""/ConfigFile:C:\Program Files\Microsoft Deployment Toolkit\Templates\Wimscript.ini"""
    }
    invoke-dism @LogArgs -ArgumentList $Command

    ####################################################

    write-verbose "dismount-vhd $VHDfile"
    dismount-vhd $VHDFile 

}
