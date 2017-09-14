function set-VMBiosGuid {

    [cmdletbinding()]
    param ( 
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $VM, 
        [parameter(Mandatory=$true)]
        [string] $GUID 
    )

    if ( $vm -is [Microsoft.HyperV.PowerShell.VirtualMachine] ) {
        $newVM = $vm
    }
    else {
        $newVM = get-vm $vm
    }

    if ( $NewVM -isnot [Microsoft.HyperV.PowerShell.VirtualMachine] ) { throw "Virtual Machine not found!" }

    $VSGSD = get-wmiobject -Namespace "Root\virtualization\v2" -class Msvm_VirtualSystemSettingData 
    $VSGSD.BIOSGUID = "{" + $guid + "}"

    $arguments = @($NewVM , $VSGSD.psbase.GetText([System.Management.TextFormat]::WmiDtd20),$null,$null)
    $VSMgtSvc = (Get-WmiObject -NameSpace  "root\virtualization" -Class "MsVM_virtualSystemManagementService")
    $VSMgtSvc.psbase.InvokeMethod("ModifyVirtualSystem", $arguments)

}

