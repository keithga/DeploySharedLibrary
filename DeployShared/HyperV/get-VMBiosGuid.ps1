function get-VMBiosGuid ( $VM )
{

    if ( $vm -is [Microsoft.HyperV.PowerShell.VirtualMachine] ) {
        $newVM = $vm
    }
    else {
        $newVM = get-vm $vm
    }

    if ( $NewVM -isnot [Microsoft.HyperV.PowerShell.VirtualMachine] ) { throw "Virtual Machine not found!" }

    get-wmiobject -Namespace "Root\virtualization\v2" -class Msvm_VirtualSystemSettingData | 
        Where-Object ConfigurationID -eq $NewVM.VMId.Guid | 
        ForEach-Object { $_.BIOSGUID.Trim('{}') }

}

