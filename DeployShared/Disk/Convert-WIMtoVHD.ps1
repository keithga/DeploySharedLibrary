
function Convert-WIMtoVHD
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory=$true)]
        [string] $ImagePath,
        [parameter(Mandatory=$true)]
        [string] $VHDFile,
        [parameter(Mandatory=$true,ParameterSetName="Index")]
        [int]    $Index,
        [parameter(Mandatory=$true,ParameterSetName="Name")]
        [string] $Name,
        [int]    $Generation = 1,
        [uint64]  $SizeBytes = 120GB,

        [switch] $Persistent,
        [scriptblock] $AdditionalContent,
        $AdditionalContentArgs,

        [switch] $Turbo = $true,
        [switch] $Force
    )

    Write-Verbose "WIM [$ImagePath]  to VHD [$VHDFile]"
    Write-Verbose "SizeBytes=$SIzeBytes  Generation:$Generation Force: $Force Index: $Index"

    if ( ( Test-Path $VHDFile) -and $Force )
    {
        dismount-vhd $VHDFile -ErrorAction SilentlyContinue | out-null
        remove-item -Force -Path $VHDFile | out-null
    }

    New-VHD -Path $VHDFile -SizeBytes $SizeBytes | Out-String | write-verbose

    $NewDisk = Mount-VHD -Passthru -Path $VHDFile
    $NewDisk | Out-String | Write-Verbose
    $NewDiskNumber = Get-VHD $VhdFile | Select-Object -ExpandProperty DiskNumber

    if ( -not  $NewDiskNumber )
    {
        throw "Unable to Mount VHD File"
    }

    Write-Verbose "Initialize Disk"

    $ReadyDisk = Format-NewDisk -DiskID $NEwDiskNumber -GPT:($Generation -eq 2)
    $ApplyPath = $ReadyDisk.WindowsPartition | get-Volume | Foreach-object { $_.DriveLetter + ":" }
    $ApplySys = $ReadyDisk.SystemPartition | Get-Volume | Foreach-object { $_.DriveLetter + ":" }

    write-verbose "Expand-WindowsImage Path [$ApplyPath] and System: [$ApplySys]"

    ########################################################

    $StdArgs = $PSBoundParameters | get-HashTableSubset -include ImagePath,Index,Name
    $StdArgs | Out-String | Write-verbose

    write-verbose "Get WIM image information for $ImagePath"
    get-windowsimage -ImagePath $ImagePath | out-string | write-verbose
    Get-WindowsImage -ImagePath $ImagePath | %{ Get-WindowsImage -ImagePath $ImagePath -index $_.ImageIndex } | write-verbose
        
    write-verbose "Expand-WindowsImage Path [$ApplyPath]"
    if ( $Turbo )
    {
        write-Verbose "Apply Windows Image /ImageFile:$ImagePath /ApplyDir:$ApplyPath"

        $Command = "/Apply-Image ""/ImageFile:$ImagePath"" ""/ApplyDir:$ApplyPath"""
        if ( $Name ) { $Command = $Command + " ""/Name:$Name""" } else { $Command = $Command + " /Index:$Index" }
        invoke-dism -description 'Dism-ApplyIMage' -ArgumentList $Command

    }
    else
    {
        $LogArgs = Get-NewDismArgs
        Expand-WindowsImage -ApplyPath "$ApplyPath\" @StdArgs @LogArgs | Out-String | Write-Verbose
    }

    ########################################################

    $OSSrcPath = split-path (split-path $ImagePath)
    $OSSrcPath | out-string | write-verbose

    ########################################################

    if ( $AdditionalContent )
    {
        write-verbose "Additional Content here!   param( $ApplyPath, $OSSrcPath, $AdditionalContentArgs ) "
        Invoke-Command -ScriptBlock $AdditionalContent -ArgumentList $ApplyPath, $OSSrcPath, $AdditionalContentArgs
    }

    ########################################################

    Write-Verbose "$ApplyPath\Windows\System32\bcdboot.exe $ApplyPath\Windows /s $ApplySys /v"

    if ( $Generation -eq 1)
    {
        $BCDBootArgs = "$ApplyPath\Windows","/s","$ApplySys","/v","/F","BIOS"
    }
    else
    {
        $BCDBootArgs = "$ApplyPath\Windows","/s","$ApplySys","/v","/F","UEFI"
    }

    # http://www.codeease.com/create-a-windows-to-go-usb-drive-without-running-windows-8.html
    cmd.exe /c "copy $ApplyPath\Windows\System32\bcdboot.exe $env:temp" | Out-String | write-verbose
    start-CommandHidden -FilePath "$env:temp\BCDBoot.exe" -ArgumentList $BCDBootArgs | write-verbose

    start-sleep 5
    if ( $Generation -eq 1)
    {
        if ( -not ( test-path "$ApplySys\boot\memtest.exe" ) ) { write-warning "missing $ApplySys\boot\memtest.exe" }
    }
    else
    {
        if ( -not ( test-path "$ApplySys\EFI\Microsoft\Boot\memtest.efi" ) ) { write-warning "missing $ApplySys\EFI\Microsoft\Boot\memtest.efi" }
    }

    Write-Verbose "Finalize Disk" 
    Complete-NewDisk @ReadyDisk 

    if ( -not $Persistent ) {
        write-verbose "Convert-WIMtoVHD FInished"
        Dismount-VHD -Path $VhdFile

    }

}

