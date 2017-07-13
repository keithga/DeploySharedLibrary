Function Invoke-AsSystem {
<#
.SYNOPSIS 

    Will run a scriptblock with in the context of NT Authority\SYSTEM.

.DESCRIPTION

    The function installs a service and runs it under the NT Authority\SYSTEM credentials. 

.PARAMETER Process

    The PROCESS script block to invoked as a service.

.PARAMETER Begin

    The BEGIN script block to invoked as a service.

.PARAMETER End

    The END script block to invoked as a service.

.PARAMETER Depth

    Objects passed on the pipeline to the function will be serialized temporarily to disk with the Export-CliXml cmdlet.
    The parameter specifies how many levels of objects passed in on the pipeline are included in the XML representation. 
    The default value is 3.    

.LINKS
    https://raw.githubusercontent.com/CosmosKey/InvokeAs

.EXAMPLE 

    Invoke-AsSystem -Process {whoami /all} 

    This gives us the whoami /all result from the execution context as NT Authority\SYSTEM

.EXAMPLE 

    "C:\System Volume Information" | Invoke-AsSystem {Get-ChildItem $_ -Force -Recurse}

    Pass a path into Invoke-AsSyetm through the pipeline.


.NOTES

Future enhancements: have the service auto shutdown when powershell is done. 
Send a semaphore to the parent powershell process,
encode the script in a base64 blob and pass as -encodedcommand

#>

    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Process={},
        [scriptblock]$Begin={},
        [scriptblock]$End={},
        [parameter(ValueFromPipeline=$true)]
        [object]$InputObject=$null,
        [int]$Depth = 3
    )
    begin {

    $code = @"
using System;
using System.ServiceProcess;
namespace GetRandom.Powershell.InvokeAsSystemSvc
{
    class TempPowershellService : ServiceBase
    {
        static void Main()
        {
            ServiceBase.Run(new ServiceBase[] { new TempPowershellService() });
        }
        protected override void OnStart(string[] args)
        {
            string[] clArgs = Environment.GetCommandLineArgs();
            try
            {
                string argString = String.Format(
                    "-command .{{import-clixml '{0}' | .'{1}' | export-clixml -Path '{2}' -Depth {3}}}",
                    clArgs[1],
                    clArgs[2],
                    clArgs[3],
                    clArgs[5]);
                System.Diagnostics.Process.Start("powershell", argString).WaitForExit();
                System.IO.File.AppendAllText(clArgs[4], "success");
            }
            catch (Exception e)
            {
                System.IO.File.AppendAllText(clArgs[4], "fail\r\n" + e.Message);
            }
            base.OnStart(args);
        }
        protected override void OnStop()
        {
            base.OnStop();
        }
    }
}
"@
        if( -not (Test-Elevated)) {
            throw "Process is not running as an eleveated process. Please run as elevated."
        }
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.ServiceProcess")   
        $serviceName  = "MyTempPowershellSvc-{0}" -f (get-date -Format yyyyMMdd-HHmmss)
        $servicePath  = Join-Path $env:temp ("{0}.exe" -f $serviceName)
        $outPath      = Join-Path $env:temp ("{0}.out" -f $serviceName)
        $inPath       = Join-Path $env:temp ("{0}.in"  -f $serviceName)
        $scrPath      = Join-Path $env:temp ("{0}.ps1" -f $serviceName)
        $completePath = Join-Path $env:temp ("{0}.end" -f $serviceName)

        $serviceImagePath = "`"{0}`" `"{1}`" `"{2}`" `"{3}`" `"{4}`" {5}" -f $servicePath,$inPath,$scrPath,$outPath,$completePath,$depth
        Add-Type $code -ReferencedAssemblies "System.ServiceProcess" -OutputAssembly $servicePath -OutputType WindowsApplication | Out-Null
        $objectsFromPipeline = new-object Collections.ArrayList
        $script = "BEGIN {{{0}}}`nPROCESS {{{1}}}`nEND {{{2}}}" -f $Begin.ToString(),$Process.ToString(),$End.ToString()
        $script.ToString() | Out-File -FilePath $scrPath -Force    
    }
 
    process {
        [void]$objectsFromPipeline.Add($InputObject)
    }
 
    end {
        
        $objectsFromPipeline | Export-Clixml -Path $inPath -Depth $Depth
        
        New-Service -Name $serviceName -BinaryPathName $serviceImagePath -DisplayName $serviceName -Description $serviceName -StartupType Manual | out-null
        $service = Get-Service $serviceName
        $service | Start-Service 
        while ( -not (test-path $completePath)) {
            Write-Progress -Activity "Executing"
            start-sleep -Milliseconds 100
        }
        $service | Stop-Service -Force 
        do {
            Write-Progress -Activity "Stopping temporary service $serviceName"
            $service = Get-Service $serviceName
        } while($service.Status -ne "Stopped")
        (Get-WmiObject win32_service -Filter "name='$serviceName'").delete() | Out-Null

        Import-Clixml -Path $outPath | Write-Output
        
        Remove-Item $servicePath,$inPath,$outPath,$scrPath,$completePath -Force -ErrorAction Continue
    }
}