function Dismount-Everything {

    <#

    IF you have any mounted VHDX or ISO images, this script will unmount them.

    #>

    Write-Verbose 'dismount VHD(x) files'
    foreach ( $disk in Get-Disk | Where-Object FriendlyName -eq 'Msft Virtual Disk' ) {
        $Disk | Out-String | Write-Verbose
        $Disk | foreach-object { dismount-vhd $_.Location } | out-null
        $Disk | Out-String | Write-Verbose
    }

    write-verbose 'dismount ISO files'

    Get-Volume | 
        Where-Object DriveType -eq 'CD-ROM' |
        ForEach-Object {
            Get-DiskImage -DevicePath  $_.Path.trimend('\') -ErrorAction SilentlyContinue
        } |
        Dismount-DiskImage

}
