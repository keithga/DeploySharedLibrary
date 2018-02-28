function Invoke-As64Bit {
    <#
    Re-Invoke Powershell, this time as a 64-bit process.
    Warning, will only return 1 or 0 as last error code.
    Example usage:
        if ( Invoke-As64Bit -Invokation $myInvocation -arks $args ) {
            write-host "finished $lastexitcode"
            exit $lastexitcode
        }
    #>
    [cmdletbinding()]
    param( [parameter(Mandatory=$true)] $Invokation, $arks )

    #Re-Invoke 
    if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
        if ($Invokation.Line) {
            write-verbose "RUn Line: $($Invokation.Line)"
            & "$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -noninteractive -NoProfile $Invokation.Line
        }else{
            write-verbose "RUn Name: $($Invokation.InvocationName) $arks"
            & "$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -noninteractive -NoProfile -file "$($Invokation.InvocationName)" $arks
        }
        return $true
    }
    return $false
}