
function Get-ADKPath
{

    $Paths = 'HKLM:\SOftware\microsoft\windows kits\installed roots','HKLM:\SOftware\Wow6432Node\microsoft\windows kits\installed roots'
    Get-ItemPropertyValue -path $Paths -Name 'KitsRoot10' | Select-Object -first 1 | Write-Output

}
