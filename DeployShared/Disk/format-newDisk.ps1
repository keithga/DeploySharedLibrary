function Format-NewDisk {
    <# 
    Foramt a disk for Windows 10.
    
    Some Notes:
    * Do not use "Recovery Partitions" since they are no longer used for Windows 10.
    * This function will return a hash table of the WinRE, Windows, and System partitions.
    * System and WinRE are hard coded to 350MB and 450MB respectively 
    * call Complete-NewDisk to make WinRE and System Partitions hidden.
    * Note: Set-Partition -GPTType *Not* present on 2012R2, use Diskpart (boo)

    #>

    param
    (
        [parameter(Mandatory=$true)]
        [ValidateRange(1,20)]
        [int] $DiskID,

        [switch] $GPT,

        [switch] $System = $True,
        [switch] $WinRE = $True
    )

    ################
    write-verbose "Clear the disk($DiskID)"
    Get-Disk -Number $DiskID | where-object PartitionStyle -ne 'RAW' | Clear-Disk -RemoveData -RemoveOEM -Confirm:$False

    $MSRPartition = $Null   
    if ( get-Disk -Number $DiskID | where-object PartitionStyle -eq 'RAW' ) {
        write-verbose "Initialize the disk($DiskID)"
        if ($GPT) {
            initialize-disk -Number $DiskID -PartitionStyle GPT -Confirm:$true
            # It's possible the MSR partition was created during Initialize-Disk
            $MSRPartition = get-partition -DiskNumber $DiskID -erroraction SilentlyContinue | where GPTType -eq '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'
        }
        else {
            initialize-disk -Number $DiskID -PartitionStyle MBR -Confirm:$true
        }
    }

    ################
    $WinREPartition = $null
    $SystemPartition = $null

    if ( $GPT ) {

        if ( $WinRE ) {
            write-verbose "Create Windows RE tools partition of 450MB"
            $WinREPartition = New-Partition -DiskNumber $DiskID -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' -Size 450MB
        }

        write-verbose "Create System Partition of 350MB"
        $SystemPartition = New-Partition -DiskNumber $DiskID -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -Size 350MB

        if ( -not $MSRPartition ) {
            write-Verbose "Create MSR partition of 128MB"
            New-Partition -DiskNumber $DiskID -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' -Size 128MB | Out-Null
        }

    }
    else {

        if ( $WinRE ) {
            write-verbose "Create Windows RE tools partition of 450MB"
            $WinREPartition = New-Partition -DiskNumber $DiskID -Size 450MB
        }

        if ( $System ) {
            write-verbose "Create System Partition of 350MB"
            $SystemPartition = New-Partition -DiskNumber $DiskID -Size 350MB
        }

    }

    write-verbose "Create Windows Partition (MAX)"
    $WindowsPartition = New-Partition -DiskNumber $DiskID -UseMaximumSize -AssignDriveLetter:$False |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows' -Confirm:$False |
        Get-Partition |
        Add-PartitionAccessPath -AssignDriveLetter -PassThru

    ################

    if ( $WinREPartition ) {
        write-verbose "Format Windows RE tools partition"
        $WinREPartition | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows RE Tools' -Confirm:$False | out-null
        if ( -not $GPT ) {
            # Work Arround - Windows 2012R2 does not support Set-Partition
            # Set-Partition -IsHidden:$True
            Invoke-DiskPart -Commands @("list disk","Select Disk $($WinREPartition.diskNumber)","Select Partition $($WinREPartition.PartitionNumber)","set ID=27","Detail Part","Exit" ) | write-verbose

        }
    }

    if ( $SystemPartition ) {
        write-verbose "Format System Partition"
        $SystemPartition | Format-Volume -FileSystem FAT32 -NewFileSystemLabel 'System' -Confirm:$False | 
            Get-Partition | 
            Add-PartitionAccessPath -AssignDriveLetter -PassThru | out-null

        if ( -not $GPT ) {
            # Work Arround - Windows 2012R2 does not support Set-Partition
            # Set-Partition -IsActive:$True
            Invoke-DiskPart -Commands @("list disk","Select Disk $($SystemPartition.diskNumber)","Select Partition $($SystemPartition.PartitionNumber)","active","Detail Part","Exit" ) | write-verbose

        }
    }

    ################

    if ( -not $SystemPartition ) {
        write-verbose "Let System Partition be the Windows Partition"
        $SystemPartition = $WindowsPartition
    }

    @{
        SystemPartition = $SystemPartition 
        WindowsPartition = $WindowsPartition 
        WinREPartition = $WinREPartition
    } | Write-Output

}
