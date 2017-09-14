
function Update-OfflineImgage {
    [cmdletbinding()]
    param(
        [string] $ApplyPath,
        [string] $OSSrcPath,

        [string[]] $Packages,
        [switch] $DotNet3,
        [switch] $cleanup,
        [string[]] $Features,

        [scriptblock] $AdditionalContent,
        $AdditionalContentArgs,

        [switch] $Turbo = $true

    )

    $DotNet3Pkg = $null
    if ( $DotNet3 ) {
        write-verbose "Install .net Framework 3"
        $DotNet3Pkg = "$OSSrcPath\sources\sxs\microsoft-windows-netfx3-ondemand-package.cab"
    }

    ########################################################

    foreach ( $Package in $DotNet3Pkg,$Packages ) {
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
        write-verbose "Additional Content here!   param( $ApplyPath, $srcOSPath, $AdditionalContentArgs ) "
        Invoke-Command -ScriptBlock $AdditionalContent -ArgumentList $ApplyPath, (split-path (split-path $ImagePath)), $AdditionalContentArgs
    }

}
