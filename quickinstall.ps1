[cmdletbinding()]
param()

$env:psmodulepath -split ';' | select -first 1 | % { robocopy.exe /e /ndl /njs /njh $PSScriptRoot\DeployShared $_\DeployShared }

