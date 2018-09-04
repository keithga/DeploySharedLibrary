
<#
.Synopsis
   Wait for a service to enter State
.DESCRIPTION
   Blocking routine for Windows Service State.
.EXAMPLE
   get-service 'ccmexec','Tanium Client' | Wait-forService Stopped
.NOTES
   Copyright Deployment Live, KeithGa@DeploymentLive.com

#>
function Wait-ForService
{
    [OutputType([System.ServiceProcess.ServiceController])]
    Param (
        # Param1 help description
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [System.ServiceProcess.ServiceController[]] $Services,

        [Parameter(Mandatory=$true, Position=1)]
        [System.ServiceProcess.ServiceControllerStatus] $Status,

        [int] $MaxTimeout = 60

    )

    Begin {
        $StopTime = [datetime]::now.AddSeconds($MaxTimeout)
        Start-Sleep -Milliseconds 100 # Flush out some actions
    }
    Process {
        
        Foreach ( $Service in $Services ) {

            Write-Verbose "Check Service $($Service.Name)"

            $Service.Refresh() 
            while ($Service.Status -ne $Status -and [datetime]::now -lt $StopTime ) {
                $Progress = 100 - ( $StopTime - [DateTime]::now | % TotalSeconds ) / $MaxTimeout * 100 
                Write-Progress -Activity "Waiting for [$($Service.ServiceName)] to be $Status" -PercentComplete $Progress
                Start-Sleep 1
                $Service.Refresh()
            }

            Write-Verbose "Check Service $($Service.Status)"
            if ( $Service.Status -ne $Status ) { 
                Write-Warning "Timeout Reached, Service [$($Service.ServiceName)] Still Not $Status"
            }

        }

    }
    End {
        write-progress -Activity 'Wait for Services' -Completed
    }
}


# stop-service WinRM -PassThru | Wait-ForService -status stopped
# start-service WinRM -PassThru | Wait-ForService -status Running 
# stop-service WinRM -PassThru | Wait-ForService -status stopped
