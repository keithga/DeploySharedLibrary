function Dismount-Everything {

    foreach ( $disk in Get-Disk | Where-Object FriendlyName -eq 'Msft Virtual Disk' ) {
        $Disk | Out-String | Write-Verbose
        $Disk | foreach-object { dismount-vhd $_.Location } | out-null
        $Disk | Out-String | Write-Verbose
    }
}