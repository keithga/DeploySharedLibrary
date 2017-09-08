

function New-HyperVirtualMachine
{
    [cmdletbinding(DefaultParameterSetName="VHD")]
    param (
        [string] $Name,

        [parameter(Mandatory=$true, ParameterSetName="ISO")] 
        [string] $ISOFile,
        [parameter(Mandatory=$true, ParameterSetName="VHD")] 
        [string] $VHDPath,

        [switch] $Force,
        [string] $SwitchName,
        [int]   $ProcessorCount = 2,
        [System.Int64] $MemoryStartupBytes = 2GB,
        [System.Int64] $SizeBytes = 120GB,
        [int] $Generation = 2,
        [version] $Version = "5.0",
        [switch] $Startup,
        [switch] $EmptyCheckpoint,
        [string] $GUID
    )

    Write-Verbose "Create a Virutal Machine: [$Name]"

    Write-Verbose "Fix/test any parameters"
    if ( -not (Get-VMHost).VirtualHardDiskPath ) { Throw 'get-VMHost.VirtualHardDiskPath not found!'}

    if ( $ISOFile ) {
        $VHDPath = "$((get-vmHost).VirtualHardDiskPath)\$($Name).vhd"
        if ( (Test-Path $VHDPath) -and $force)
        {
            write-verbose "VHD $VHDPath already exists! Force Removal!"
            Remove-item -Force $VHDPath -ErrorAction SilentlyContinue
        }
    }

    if ( (Get-VM $Name -ErrorAction SilentlyContinue) -and $force) {
        Write-Verbose "VM $Name already exists! Force removal!"
        stop-vm -Name $Name -force -ErrorAction SilentlyContinue | Out-Null
        remove-vm -Name $Name -force -ErrorAction SilentlyContinue
    }

    if ( -not $SwitchName ) {
        if ( Get-VMSwitch -SwitchType External -ErrorAction SilentlyContinue ) {
            if ( (Get-VMSwitch -SwitchType External -ErrorAction SilentlyContinue | Measure-Object).Count -eq 1 ) {
                $SwitchName = Get-VMSwitch -SwitchType External | Select-Object -ExpandProperty Name
            }
        }
    }
    if ( -not $SwitchName ) { throw "Missing Switch!" }

    Write-Verbose "new Virutal Machine"

    if (-not ( test-path $VHDPath ) ) {
        New-VHD -Path $VHDPath -SizeBytes $SizeBytes | Out-String | Write-Verbose
    }
    $newVM = New-VM -Name $Name -SwitchName $SwitchName -VHDPath $VHDPath -Generation $Generation -Version $Version
    Set-VM -Name $newVM.Name -ProcessorCount $ProcessorCount -DynamicMemory -MemoryStartupBytes $MemoryStartupBytes -MemoryMinimumBytes $MemoryStartupBytes  | Out-String | Write-verbose

    if ( $ISOFile ) {
        if ( -not ( Test-Path $ISOFile )) { throw "Missing VHD: $VHDPath" }
        Set-VMDvdDrive -VMName $newVM.Name -Path $ISOFile | Out-String | Write-verbose
    }

    if ( $GUID ) {
        Write-Verbose "Force the GUID to $GUID"
        set-VMBiosGuid -vm $NewVM -GUID $GUID
    }

    if ( $EmptyCheckPoint ) { CheckPoint-VM -VM $NewVM -SnapShotName "Empty Virtual Machine"  | Out-String | Write-Verbose }
    if ( $Startup ) { Start-VM -VM $NewVM | Out-String | Write-Verbose }

    $NewVM | Out-Default

}