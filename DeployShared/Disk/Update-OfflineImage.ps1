
function Update-OfflineImage {
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
        $DotNet3Pkg += get-childitem "$OSSrcPath\sources\sxs\*netfx3*" | % FullName
    }

    ########################################################

    foreach ( $Package in $DotNet3Pkg + $Packages ) {
        write-verbose "Add PAckages $Package"

        if ( $Turbo ) {
            $Command = " /image:$ApplyPath\ /Add-Package ""/PackagePath:$Package"""
            invoke-dism -description 'Dism-AddPackage' -ArgumentList $Command
        }
        else {
            Add-WindowsPackage -PackagePath $Package -Path "$ApplyPath\" @LogArgs -NoRestart | Out-String | Write-Verbose
        }
    }

    ########################################################

    if ( $cleanup )  {
        write-verbose "Cleanup Image"
        invoke-dism -description 'Cleanup-image' -argumentList "/Cleanup-image /image:$ApplyPath\ /analyzecomponentstore"
        #dism.exe /Cleanup-image "/image:$ApplyPath\" /analyzecomponentstore
        if ( Test-Path "$ApplyPath\Windows\System32\pending.xml" ) {
            invoke-dism -description 'Dism-CleanupBase' -ArgumentList "/Cleanup-Image /image:$ApplyPath\ /StartComponentCleanup"
        }
        else {
            invoke-dism -description 'Dism-CleanupBase' -ArgumentList "/Cleanup-Image /image:$ApplyPath\ /StartComponentCleanup /ResetBase"
            if ( ! $? ) {
                invoke-dism -description 'Dism-CleanupBase' -ArgumentList "/Cleanup-Image /image:$ApplyPath\ /StartComponentCleanup"
            }
        }
        invoke-dism -description 'Cleanup-image' -argumentList "/Cleanup-image /image:$ApplyPath\ /analyzecomponentstore"
        # dism.exe /Cleanup-image "/image:$ApplyPath\" /analyzecomponentstore
    }

    ########################################################

    foreach ( $Feature in $Features ) {
        $LogArgs = Get-NewDismArgs
        write-verbose "Add Feature $Feature"

        if ( $Turbo ) {
            $Command = " /image:$ApplyPath\ /Enable-Feature /All ""/FeatureName:$Feature"" ""/Source:$OSSrcPath"" /LimitAccess"
            invoke-dism -description 'Dism-AddFeature-$Feature' -ArgumentList $Command
        }
        else {
            Enable-WindowsOptionalFeature -FeatureName $Feature -all -LimitAccess -path $ApplyPath -Source $OSSrcPath @DISMArgs
        }
    }

    ########################################################

    if ( $AdditionalContent )
    {
        write-verbose "Additional Content here!   param( $ApplyPath, $OSSrcpath, $AdditionalContentArgs ) "
        Invoke-Command -ScriptBlock $AdditionalContent -ArgumentList $ApplyPath, $OSSrcPath, $AdditionalContentArgs
    }

}
