[cmdletbinding()]
param( $VHDPath = 'e:\test\foo.vhdx' )

import-module $PSScriptROot\..\..\DeployShared -force -ErrorAction SilentlyContinue

describe 'Verify Environment' {

    Dismount-Everything

    $script:VHDPath = join-path (get-vmhost | % VirtualHardDiskPath) "testfile.vhdx"

    dismount-vhd $VHDPath -ErrorAction SilentlyContinue

    if ( test-path $VHDPath ) { remove-item $VHDPath }
    new-vhd $VHDPath -SizeBytes 80GB | out-null
    $script:NewDisk = mount-vhd $VHDPath -Passthru
    $newDisk.DiskNumber | should begreaterthan 0
    $newDisk.DiskNumber | should belessthan 10

}


describe 'New disk MBR' {

    write-host "Disk: $($newDisk.DiskNumber)"
    $Resultdisk = Format-NewDisk -DiskID $newDisk.DiskNumber -WinRE:$false

    $Partitions = get-disk $newDisk.DiskNumber | get-partition 
    $Partitions | fl * | out-string -width 200 | write-host 
    $Partitions | out-string -width 200 | write-host 

    $partitions.count | should be 2
    $partitions[0].Size | should be 350MB
    $partitions[0].Type | should be 'FAT32 XINT13'
    $partitions[0].DriveLetter | should not be $null
    $partitions[0].isActive | should be true

    $partitions[1].Size | should begreaterthan 79GB
    $partitions[1].Type | should be 'IFS'
    $partitions[1].DriveLetter | should not be $null

    Complete-NewDisk @resultDisk
    $Partitions = get-disk $newDisk.DiskNumber | get-partition 
    $Partitions | out-string -width 200 | write-host 

}


describe 'New disk GPT' {

    write-host "Disk: $($newDisk.DiskNumber)"
    $Resultdisk = Format-NewDisk -DiskID $newDisk.DiskNumber -GPT  -WinRE:$false

    $Partitions = get-disk $newDisk.DiskNumber | get-partition 
    $Partitions | fl * | out-string -width 200 | write-host 
    $Partitions | out-string -width 200 | write-host 

    $partitions.count | should be 3
    $partitions[0].Size | should belessthan 200MB
    $partitions[0].Type | should be 'Reserved'
    [char]::isLetter($partitions[0].DriveLetter) | should be $False

    $partitions[1].Size | should be 350MB
    $partitions[1].Type | should be 'Basic'
    [char]::isLetter($partitions[1].DriveLetter) | should be $true

    $partitions[2].Size | should begreaterthan 79GB
    $partitions[2].Type | should be 'Basic'
    [char]::isLetter($partitions[2].DriveLetter) | should be $true

    Complete-NewDisk @resultDisk
    $Partitions = get-disk $newDisk.DiskNumber | get-partition 
    $Partitions | out-string -width 200 | write-host 

}


# Format-NewDisk -DiskID $newDisk.DiskNumber -System:$false -WinRE:$False -GPT -verbose
# Invoke-DiskPart -Commands @("Select Disk $DiskID","list part","sel part 1","detail Part","Sel Part 2","Detail Part","Sel Part 3","Detail Part","Sel Part 4","Detail Part","Exit" ) | write-host

describe 'cleanup environment' {

    dismount-vhd -Path $VHDPath 
    get-disk -path $VHDPath -ErrorAction SilentlyContinue | should Throw

}
