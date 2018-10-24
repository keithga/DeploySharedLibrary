

function Update-ImageWithLatestUpdates {
    <#

    Given an image file (Either *.iso or *.wim), this script will update the image to the latest cumuliative update and output a Target WIM file. 

    #>

    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        [string] $ImagePath,
        [parameter(Mandatory=$true)]
        [int] $Index,
        [parameter(Mandatory=$true)]
        [string] $TargetWim,

        [string] $LocalTmpWim,  # Optional location for temp worker WIM
        [string[]] $ForcedUpdates,  # Optional list of URIs

        [string] $Cache = $env:temp,
        [string] $LocalMountPath = 'c:\mount\windows'
    )

    $finalUpdateListURI = @()

    #region Extract data about ISO Image

    $OKToDismount= $False
    if ( $ImagePath.tolower().EndsWith('.wim') ) {
        $WimImage = get-item $ImagePath | % FullName
    }
    elseif ( $ImagePath.tolower().EndsWith('.iso') ) {
        $FoundVolume = get-diskimage -ImagePath $ImagePath -ErrorAction SilentlyContinue | Get-Volume
        if ( -not $FoundVolume ) {
            write-verbose "mount $ImagePath"
            Mount-DiskImage -ImagePath $ImagePath -StorageType ISO -Access ReadOnly
            $FoundVolume = get-diskimage -ImagePath $ImagePath -ErrorAction SilentlyContinue | Get-Volume
            $OKToDismount= $True
        }
        $FoundVolume | Out-String | Write-verbose

        if ( -not [char]::IsLetter($FoundVolume.DriveLetter) ) { throw "Bad Volume $FoundVolume" }

        $WimImage = $FoundVolume.DriveLetter + ':\Sources\Install.wim'
    }
    else {
        throw "Unknown Image Type: $ImagePath"
    }

    while ( -not ( test-path $WimImage ) ) { start-sleep 1 ; Write-Verbose "waiting for $ImagePath" }

    if ( -not ( test-path $WimImage ) ) { throw "missing WIMIMage: $WimImage" }
    $WimMetaData = Get-WindowsImage -ImagePath $WimImage -index $Index 
    $WimMetaData | out-string -Width 200 | write-verbose

    $Build = ([version]$WimMetaData.Version).Build
    $Architecture = if ( $WimMetaData.Architecture -eq 9 ) { 'x64' } else { 'x86' }

    #endregion

    #region SSU Updates

    if ( -not $ForcedUpdates ) {
    
        if ( $Build -eq 17134 ) { 
            $FinalUpdateListURI += Find-MicrosoftCatalogItem -SearchTerm "KB4456655 $Architecture"  |
                % Source | Select-object -first 1

        } 
        elseif ( $Build -eq 16299 ) { 
            $FinalUpdateListURI += Find-MicrosoftCatalogItem -SearchTerm "KB4339420 $Architecture"  |
                % Source | Select-object -first 1

        } 
        elseif ( $Build -eq 14393 ) { 
            $FinalUpdateListURI += Find-MicrosoftCatalogItem -SearchTerm "KB4132216 $Architecture"  |
                % Source | Select-object -first 1

        }
        else {
            write-verbose "no SSU updates for build $Build"

        }

    }

    #endregion

    #region Get Latest Updates from Microsoft

    $FoundUpdate = $null
    if ( -not $ForcedUpdates ) {
        $FoundUpdate = Find-LatestCumulativeUpdate -Build $BUild
        $FoundUpdate | out-string | write-verbose

        $FinalUpdateListURI += Find-MicrosoftCatalogItem -SearchTerm "$($FoundUpdate.Kb) $Architecture"  |
            % Source | Select-object -first 1
    }

    if ( test-path $TargetWim -ErrorAction SilentlyContinue ) { 

        write-verbose "check $TargetWim to see if it's newer or older than the found update"
        $TargetMetaData = Get-WindowsImage -imagepath (get-item $TargetWim).FullName -index 1

        if ( ( $TargetMetaData.SpLevel -ge $FoundUpdate.Build.Revision ) -or ( $TargetMetaData.SPBuild -ge $FoundUpdate.Build.Revision ) ) {
            write-warning "OK to exit: [$($TargetMetaData.Version) -ge $($FoundUpdate.Build)]"
            if ( $OKToDismount ) {
                write-verbose "dismount $ImagePath"
                Dismount-DiskImage -ImagePath $ImagePath | out-string
            }
            return
        }

    }

    #endregion

    #region Download and Cache any updates

    $LocalUpdates = @()
    foreach ( $Update in $finalUpdateListURI + $ForcedUpdates ) { 
        if ( -not [string]::IsNullOrEmpty($UPdate) ) {
            write-verbose "Check for $Update"
            $LocalPath = join-path $Cache ( split-path -Leaf $Update ) 
            if ( -not ( test-path $LocalPath ) ) { 
                Receive-URL -url $Update -localFile $LocalPath
            }

            $LocalUpdates += $LocalPath 
        }
    }

    #endregion

    #region Update - Traditional

    if ( $LocalUpdates ) { 

        $LocalUpdates | write-verbose

        if ( -not $LocalTmpWim ) { $LocalTmpWim = "$($TargetWim).tmp.wim" }

        write-verbose "Cleanup..."
        if ( test-path "$LocalMountPath\*" )  { 
            write-verbose "dismount clean $LocalMOuntPath"
            Dismount-WindowsImage -Discard -Path $LocalMountPath | out-string | write-verbose
        }

        remove-item -Path $TargetWim,$LocalTmpWim -force -ErrorAction SilentlyContinue

        write-verbose ('#' * 80)
        $startTIme = [datetime]::now

        $LogArgs = Get-NewDismArgs
        Invoke-DISM -ArgumentList "/export-image ""/sourceImageFile:$WimImage"" /SourceIndex:$Index ""/DestinationImageFile:$LocalTmpWim"" ""/DestinationName:$($WimMetaData.ImageName)""" @LogArgs

        new-item $LocalMountPath -ItemType Directory -Force -ErrorAction SilentlyContinue | out-null

        $LogArgs = Get-NewDismArgs
        write-verbose "mount-WIndowsImage $LocalTmpWim -Index 1 -Path $LocalMountPath $logArgs"
        Mount-WindowsImage -ImagePath $LocalTmpWim -Index 1 -Path $LocalMountPath @logArgs | out-string | write-verbose

        write-verbose "Update-Offline Image"
        update-offlineimage -ApplyPath $LocalMountPath -OSSrcPath (split-path (split-path $WimImage)) -cleanup -packages $LocalUpdates 

        $logArgs = Get-NewDismArgs
        write-verbose "Dismount-WIndowsImage $LocalTmpWim -Index 1 -Path $LocalMountPath $logArgs"
        Dismount-WindowsImage -Save -Path $LocalMountPath | out-string | write-verbose

        write-Verbose "Total Time to add CU: $(([datetime]::now - $starttime).TotalMinutes) MInutes"

        Invoke-DISM -ArgumentList "/export-image ""/sourceImageFile:$LocalTmpWim"" /SourceIndex:1 ""/DestinationImageFile:$TargetWim"" ""/DestinationName:$($WimMetaData.ImageName)""" @LogArgs

        remove-item -Path $LocalTmpWim -force -ErrorAction SilentlyContinue

        Get-WindowsImage -ImagePath $TargetWim -Index 1 | out-string | write-verbose

    }

    #endregion

    #region Update - Wim to Vhd to Wim

    #Future: Try my old method which was to use WimtoVHD then VHDtoWIM.

    #endregion
  
    #region Close out ISO Image

    if ( $OKToDismount ) {
        write-verbose "dismount $ImagePath"
        Dismount-DiskImage -ImagePath $ImagePath | out-string
    }

    #endregion

}

