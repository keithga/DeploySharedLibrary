function Find-InternetFacingVMSwitch {
    <#
        Given a VMswitch (from Get-vmswitch), test for internet connectivity.
    #>

    param (
        [Microsoft.HyperV.PowerShell.VMSwitch] $VMSwitch
    )

    $VMAdapter = Get-VMNetworkAdapter -ManagementOS -SwitchName $VMSwitch.Name
    if ( $VmAdapter )
    {
        Get-NetAdapter | Where-Object { $_.DeviceID -eq $VMAdapter.DeviceId } | 
            % { Find-NetRoute -RemoteIPAddress "208.84.0.53" -interfaceindex $_.ifIndex }
    }

}