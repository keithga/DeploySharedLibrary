function Format-NewDisk {
    <# 
    Foramt a disk for Windows 10.
    
    Some Notes:
    * Do not use "Recovery Partitions" since they are no longer used for Windows 10.
    * This function will return a hash table of the WinRE, Windows, and System partitions.
    * System and WinRE are hard coded to 350MB
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

    if ( get-Disk -Number $DiskID | where-object PartitionStyle -eq 'RAW' ) {
        write-verbose "Initialize the disk($DiskID)"
        if ($GPT) {
            initialize-disk -Number $DiskID -PartitionStyle GPT -Confirm:$true
        }
        else {
            initialize-disk -Number $DiskID -PartitionStyle MBR -Confirm:$true
        }
    }

    ################
    $WinREPartition = $null
    if ( $WinRE ) {
        write-verbose "Create Windows RE tools partition of 350MB"
        $WinREPartition = New-Partition -DiskNumber $DiskID -Size 350MB -AssignDriveLetter:$False | 
            Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows RE Tools' -Confirm:$False |
            Get-Partition 
        if ( $GPT ) {
            Invoke-DiskPart -Commands @("list disk","Select Disk $($WinREPartition.diskNumber)","Select Partition $($WinREPartition.PartitionNumber)","set ID=de94bba4-06d1-4d40-a16a-bfd50179d6ac","Detail Part","Exit" ) | write-verbose
            # $WinREPartition | Set-Partition -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' -ErrorAction SilentlyContinue
        }
    }

    ################
    $SystemPartition = $null
    if ( $GPT -or $System ) {
        write-verbose "Create System Partition of 350MB"
        $SystemPartition = New-Partition -DiskNumber $DiskID -Size 350MB -AssignDriveLetter:$false | 
            Format-Volume -FileSystem FAT32 -NewFileSystemLabel 'System' -Confirm:$False | 
            Get-Partition | 
            Add-PartitionAccessPath -AssignDriveLetter -PassThru
    }

    ################
    if ( $GPT ) {
        write-Verbose "Create MSR partition of 128MB"
        New-Partition -DiskNumber $DiskID -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' -Size 128MB | Out-Null
    }

    ################
    write-verbose "Create Windows Partition (MAX)"
    $WindowsPartition = New-Partition -DiskNumber $DiskID -UseMaximumSize -AssignDriveLetter:$False |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows' -Confirm:$False |
        Get-Partition |
        Add-PartitionAccessPath -AssignDriveLetter -PassThru

    ################
    if ( -not $SystemPartition ) {
        write-verbose "Let System Partition be the Windows Partition"
        $SystemPartition = $WindowsPartition
    }
    if ( -not $GPT ) {
        write-verbose "Set the System partition active"
        $SystemPartition | Set-Partition -IsActive:$true
    }

    @{
        SystemPartition = $SystemPartition 
        WindowsPartition = $WindowsPartition 
        WinREPartition = $WinREPartition
    } | Write-Output

}
