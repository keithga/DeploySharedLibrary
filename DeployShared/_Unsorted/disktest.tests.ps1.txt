[cmdletbinding()]

param(
    $VHDPath = 'e:\test\foo.vhdx'
    )


import-module C:\Users\Keith\Source\Repos\DeploySharedLibrary\DeployShared -force -ErrorAction SilentlyContinue

Dismount-Everything

if ( test-path $VHDPath ) { remove-item $VHDPath }

new-vhd $VHDPath -SizeBytes 80GB | out-null

$NewDisk = mount-vhd $VHDPath -Passthru

$DiskID = $newDisk.DiskNumber

Format-NewDisk -DiskID $newDisk.DiskNumber -System:$false -WinRE:$False -GPT -verbose

Invoke-DiskPart -Commands @("Select Disk $DiskID","list part","sel part 1","detail Part","Sel Part 2","Detail Part","Sel Part 3","Detail Part","Sel Part 4","Detail Part","Exit" ) | write-host
