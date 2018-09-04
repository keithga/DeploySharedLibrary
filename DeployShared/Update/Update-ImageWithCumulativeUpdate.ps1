function Update-ImageWithCumulativeUpdate {

    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        [string] $path,
        [parameter(Mandatory=$true)]
        [string] $Cache,
        [parameter(Mandatory=$true)]
        [string] $Target,
        [switch] $Force
    )

    #region Support Routines

    function Get-Architecture ( $Arch ) { if ( $arch -eq 9 ) { 'x64' } else { 'x86' } } 

    Function Update-DownloadLink {
        [cmdletbinding()]
        param( 
            [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
            [string] $Source,
            [string] $Cache 
        ) 

        if ( -not ( test-path $Cache ) ) { new-item -Path $cache -ItemType directory -force | out-null }

        $LocalFile = join-path $Cache (split-path -leaf $Source)
        $isNew = $True
        if ( ( test-path $LocalFile ) ) {
            write-verbose "No change, $LocalFIle already exists!"
            $isNew = $False
        }
        else {

            write-verbose "download $URI to $LocalFile"
            Receive-URL -url $Source -localFile $LocalFile 

            if ( -not ( test-path $LocalFile ) ) { throw "LocalFile not downloaded $LocalFIle" }

            Write-verbose "Clean Cache"
            Get-ChildItem -path $Cache -File | 
                where-object LastWriteTime -lt ((get-Date).AddDays(-50)) |
                Remove-item -Force

        }

        [pscustomobject] @{ New = $IsNew; Path = $LocalFile } | write-output
    }

    #endregion 

    foreach ( $Config in Import-Clixml -Path $path ) {

        $config | out-string -width 200 | write-verbose 
        $Build = $Config.Version -as [version]
        $LocalCache = @( $Config.EditionID,(Get-Architecture $Config.Architecture),$Config.Version) -join '.'
        $PackageCache = @()
        $LocalCache | write-verbose

        #region Get latest CU
        #############################################
        write-verbose "Get the latest Cumulative Update for $($Config.ISO)"

        $PackageCache += Find-LatestCumulativeUpdate -BUild $BUild.Build | 
            ForEach-Object { "KB$($_.ArticleID) " + (Get-Architecture $Config.Architecture) } | 
            Find-MicrosoftCatalogItem -Exclude 'delta' |
            Select-Object -unique -first 1 | 
            Update-DownloadLink -Cache "$Cache\$LocalCache\CU"

        #endregion

        #region Get latest Adobe Patch
        #############################################
        write-verbose "Get the latest Adobe Update for $($Config.ISO)"

        if ( $Config.ProductType -eq 'WinNT' ) {

            $PackageCache += @("adobe windows 10",(Get-Architecture $Config.Architecture),(Convert-BuildToVersion $Build.Build)) -join ' ' |
                Find-MicrosoftCatalogItem |
                Select-Object -unique -first 1 |
                Update-DownloadLink -Cache "$Cache\$LocalCache\Adobe"

        }

        #endregion

        #region Rebuild if dirty 
        #############################################
        write-verbose "Get the status of the update and patch the WIM"

        $TargetName = @( $Config.EditionID,(Get-Architecture $Config.Architecture),$Config.Version,(Get-Date -f 'yyMM')) -join '.'

        if ( ( -not ( 'true' -in $PackageCache.New ) ) -and ( $Config.EditionId -notin $Force ) -and ( test-path ( join-path $Target "$($TargetName).wim" ) ) ) { 
            write-verbose "no changes to $($Config.ISO)"; continue
        }

        $ConvertVHDArgs = @{
            ImagePath = $COnfig.ISO
            Index = $config.ImageIndex
            VHDFile = join-path (get-vmhost).VirtualHardDiskPath "$($TargetName).vhd"
            AdditionalContentArgs = $PackageCache.path
            AdditionalContent = {
                param( $ApplyPath, $OSSrcPath, $Update )
                update-offlineimage -ApplyPath $ApplyPath -OSSrcPath $OSSrcPath -dotnet3 -cleanup -packages $Update
            }
        }

        Convert-ISOtoVHD @ConvertVHDArgs

        write-verbose "Convert VHD back to WIM"

        new-item -path $target -ItemType directory -ErrorAction SilentlyContinue | out-null
        $ConvertWIMArgs = @{
            ImagePath = join-path $Target "$($TargetName).wim"
            VHDFile = join-path (get-vmhost).VirtualHardDiskPath "$($TargetName).vhd"
            Name = $Config.EditionId
            CompressionType = 'MAX'
            Force = $True
        }

        Convert-VHDtoWIM @ConvertWIMArgs

        #endregion

    }


}