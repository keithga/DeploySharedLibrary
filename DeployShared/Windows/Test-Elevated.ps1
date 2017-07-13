
Function Test-Elevated {

    # Tests to see if current process is elevated

    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $prp.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}
