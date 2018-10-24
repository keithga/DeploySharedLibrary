function Format-NewDisk {
    <# 
    Foramt a disk for Windows 10.

    I have tried, and tried, and TRIED. 
    But, no matter what, I have been unable to generate a powershell native reference design 
    to format a disk WITHOUT using DiskPart.exe. It just can't be done. 
    
    Some Notes:
    * Do not use "Recovery Partitions" since they are no longer used for Windows 10.
    * This function will return a hash table of the WinRE, Windows, and System partitions.
    * System and WinRE are hard coded to 350MB and 450MB respectively 

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

    $restoreShellHWDetection = $False
    if ( get-service 'ShellHWDetection' | ? Status -eq 'Running' ) {
        Write-Verbose "temporarily pause the ShellHWDetection Service so we don't get the pesky popups"
        Stop-Service 'ShellHWDetection' | wait-ForService -status Stopped
        $restoreShellHWDetection = $True
    }

    ################
    $WinREPartition = $null
    if ( $WinRE ) {
        write-verbose "Create Windows RE tools partition of 350MB"
        $WinREPartition = New-Partition -DiskNumber $DiskID -Size 350MB -AssignDriveLetter:$False |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows RE Tools' -Confirm:$False |
            Get-Partition
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
    if ( $GPT -and -not $MSRPartition ) {
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

    if ( $WinREPartition ) {
        write-verbose "Format Windows RE tools partition"
        $WinREPartition | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows RE Tools' -Confirm:$False | out-null
        if ( -not $GPT ) {
            Write-Warning "might cause problems!?!?!"
            Invoke-DiskPart -Commands @("list disk","Select Disk $($WinREPartition.diskNumber)","Select Partition $($WinREPartition.PartitionNumber)","set ID=27","Detail Part","Exit" ) | write-verbose
        }
        else {
            Invoke-DiskPart -Commands @("list disk","Select Disk $($WinREPartition.diskNumber)","Select Partition $($WinREPartition.PartitionNumber)","set ID=de94bba4-06d1-4d40-a16a-bfd50179d6ac","Detail Part","Exit" ) | write-verbose
        }
    }

    if  ( -not $SystemPartition ) {
        write-verbose "Let System Partition be the Windows Partition"
        $SystemPartition = $WindowsPartition
    }

    if ( -not $GPT ) {
        write-verbose "Set the System partition active"
        $SystemPartition | Set-Partition -IsActive:$true
        # Invoke-DiskPart -Commands @("list disk","Select Disk $($SystemPartition.diskNumber)","Select Partition $($SystemPartition.PartitionNumber)","active","Detail Part","Exit" ) | write-verbose
    }

    ################

    if ( $restoreShellHWDetection -and (get-service 'ShellHWDetection' | ? Status -ne 'Running' ) ) {
        Write-Verbose "Restore the ShellHWDetection Service"
        start-Service 'ShellHWDetection'
    }


    @{
        SystemPartition = $SystemPartition 
        WindowsPartition = $WindowsPartition 
        WinREPartition = $WinREPartition
    } | Write-Output

}
