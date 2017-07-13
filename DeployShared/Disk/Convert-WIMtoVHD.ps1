
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
        [string[]] $Packages,
        [switch] $DotNet3,
        [string[]] $Features,
        [switch] $Turbo = $true,
        [scriptblock] $AdditionalContent,
        $Aux,
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

    $LogArgs = Get-NewDismArgs
    write-verbose "Get WIM image information for $ImagePath"
    get-windowsimage -ImagePath $ImagePath | out-string | write-verbose
    Get-WindowsImage -ImagePath $ImagePath | %{ Get-WindowsImage -ImagePath $ImagePath -index $_.ImageIndex } | write-verbose
        
    $LogArgs = Get-NewDismArgs
    write-verbose "Expand-WindowsImage Path [$ApplyPath]"
    if ( $Turbo )
    {
        write-Verbose "Apply Windows Image /ImageFile:$ImagePath /ApplyDir:$ApplyPath"

        $Command = "/Apply-Image ""/ImageFile:$ImagePath"" ""/ApplyDir:$ApplyPath"""
        if ( $Name ) { $Command = $Command + " ""/Name:$Name""" } else { $Command = $Command + " /Index:$Index" }
        invoke-dism @LogArgs -ArgumentList $Command

    }
    else
    {
        Expand-WindowsImage -ApplyPath "$ApplyPath\" @StdArgs @LogArgs | Out-String | Write-Verbose
    }

    ########################################################

    $OSSrcPath = split-path (split-path $ImagePath)
    $OSSrcPath | out-string | write-verbose

    ########################################################

    foreach ( $Package in $Packages ) {
        $LogArgs = Get-NewDismArgs
        write-verbose "Add PAckages $Package"

        if ( $Turbo ) {
            $Command = " /image:$ApplyPath\ /Add-Package ""/PackagePath:$Package"""
            invoke-dism @LogArgs -ArgumentList $Command
        }
        else {
            Add-WindowsPackage -PackagePath $Package -Path "$ApplyPath\" @LogArgs -NoRestart | Out-String | Write-Verbose
        }
    }

    ########################################################

    if ( $cleanup )  {
        $LogArgs = Get-NewDismArgs
        write-verbose "Cleanup Image"
        invoke-dism @LogArgs -ArgumentList "/Cleanup-image /image:$ApplyPath\ /analyzecomponentstore"
        invoke-dism @LogArgs -ArgumentList "/Cleanup-Image /image:$ApplyPath\ /StartComponentCleanup /ResetBase"
        invoke-dism @LogArgs -ArgumentList "/Cleanup-image /image:$ApplyPath\ /analyzecomponentstore"
    }

    ########################################################

    if ( $DotNet3 ) {
        write-verbose "Install .net Framework 3"

        foreach ( $Package in "$OSSrcPath\sources\sxs\microsoft-windows-netfx3-ondemand-package.cab" ) {
            $LogArgs = Get-NewDismArgs
            if ( $Turbo ) {
                $Command = " /image:$ApplyPath\ /Add-Package ""/PackagePath:$Package"""
                invoke-dism @LogArgs -ArgumentList $Command
            }
            else {
                Add-WindowsPackage -PackagePath $Package -Path "$ApplyPath\" @LogArgs -NoRestart | Out-String | Write-Verbose
            }
        }

    }

    ########################################################

    foreach ( $Feature in $Features ) {
        $LogArgs = Get-NewDismArgs
        write-verbose "Add Feature $Feature"

        if ( $Turbo ) {
            $Command = " /image:$ApplyPath\ /Enable-Feature /All ""/FeatureName:$Feature"" ""/Source:$OSSrcPath"""
            invoke-dism @LogArgs -ArgumentList $Command
        }
        else {
            Enable-WindowsOptionalFeature -FeatureName $Feature -all -LimitAccess -path $ApplyPath -Source $OSSrcPath @DISMArgs
        }
    }

    ########################################################

    if ( $AdditionalContent )
    {
        write-verbose "Additional Content here!   param( $ApplyPath, $srcOSPath, $Aux ) "
        Invoke-Command -ScriptBlock $AdditionalContent -ArgumentList $ApplyPath, (split-path (split-path $ImagePath)), $aux
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
    Copy-Item $ApplyPath\Windows\System32\bcdboot.exe $env:temp\BCDBoot.exe

    start-CommandHidden -FilePath $env:temp\BCDBoot.exe -ArgumentList $BCDBootArgs | write-verbose

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
    Format-NewDiskFinalize @ReadyDisk

    write-verbose "Convert-WIMtoVHD FInished"

    Dismount-VHD -Path $VhdFile

}

