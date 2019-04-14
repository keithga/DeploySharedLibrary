
Function Complete-NewDisk {
    <# 
    Complete New Disk partitions for Windows 10

    Formatting a disk using Powershell Native commands have limitations:

    * Powershell will remove all drive letters from a disk once you hide *any* partition
    * Powershell will remove all drive letters from a disk once you mark the system partition
    * Set-Partition -GPTType is *Not* present on 2012R2, use Diskpart
    * Set-partition -isHidden can affect other partitions not just the one selected!?!?

    #>
    [cmdletbinding()]
    param
    (
        $SystemPartition,
        $WindowsPartition,
        $WinREPartition
    )

    ################

    if ($WinREPartition) {
        $WinREPartition | 
            where-object MBRType -eq 7 |
            ForEach-Object { 
                Invoke-DiskPart -Commands @("list disk","Select Disk $($_.diskNumber)","Select Partition $($_.PartitionNumber)","set ID=27","Detail Part","Exit" ) | write-verbose
            }
            # Set-Partition -IsHidden:$True
    }

    if ( $SystemPartition ) {
        $SystemPartition | 
            where-object GPTType -eq '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' |
            ForEach-Object { 
                Invoke-DiskPart -Commands @("list disk","Select Disk $($_.diskNumber)","Select Partition $($_.PartitionNumber)","set ID=c12a7328-f81f-11d2-ba4b-00a0c93ec93b","Detail Part","Exit" ) | write-verbose
            }
    }

}
