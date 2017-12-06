
Function Complete-NewDisk {
    <# 
    Complete New Disk partitions for Windows 10

    Formatting a disk using Powershell Native commands have limitations:

    #>
    [cmdletbinding()]
    param
    (
        $SystemPartition,
        $WindowsPartition,
        $WinREPartition
    )

    ################

    Write-Warning "this function is deprecated"

}
