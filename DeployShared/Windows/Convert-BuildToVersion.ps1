
$BuildTable = @(
        [pscustomobject] @{ Version = '1507'; BuildNumber = '10240' ;  CodeName = 'Threshold 1'; MarketingName = 'Release To Manufacturing'}
        [pscustomobject] @{ Version = '1511'; BuildNumber = '10586' ;  CodeName = 'Threshold 1'; MarketingName = 'November Update' }
        [pscustomobject] @{ Version = '1607'; BuildNumber = '14393' ;  CodeName = 'Redstone 1'; MarketingName = 'Anniversary Update' }
        [pscustomobject] @{ Version = '1703'; BuildNumber = '15063' ;  CodeName = 'Redstone 2'; MarketingName = 'Creators Update' }
        [pscustomobject] @{ Version = '1709'; BuildNumber = '16288' ;  CodeName = 'Redstone 3'; MarketingName = 'Fall Creators Update' }
        [pscustomobject] @{ Version = '1803'; BuildNumber = '16362' ;  CodeName = 'Redstone 4'; MarketingName = 'TBA Update' }
    )

function Convert-BuildToVersion {

[cmdletbinding()]
    
    param( 
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $Build
    ) 

    $BuildTable | Where-Object $build -match BuildNumber | % Version | Write-Output

}
