
<#

Not a real pester test

#>

import-module $PSscriptRoot\..\..\DeployShared -force -verbose:$false

$verbosepreference = 'continue'
$erroractionpreference = 'stop'

cls 

update-ImageWithLatestUpdates -ImagePath C:\Temp\ISO_Media\17763.1.180914-1434.rs5_release_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso -index 1 -targetwim c:\temp\WindowsEval.17763.wim -Cache C:\temp\Cache -LocalMountPath 'c:\mount\windows'

update-ImageWithLatestUpdates -ImagePath C:\Temp\ISO_Media\17763.1.180914-1434.rs5_release_SERVER_EVAL_x64FRE_en-us.iso -index 2 -targetwim c:\temp\ServerEval.17763.wim -Cache C:\temp\Cache -LocalMountPath 'c:\mount\windows'
update-ImageWithLatestUpdates -ImagePath C:\Temp\ISO_Media\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO -index 2 -targetwim c:\temp\ServerEval.14393.wim -Cache C:\temp\Cache -LocalMountPath 'c:\mount\windows'
