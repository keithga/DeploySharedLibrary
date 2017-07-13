function Get-NewDismArgs
{
    $LogPath = [System.IO.Path]::GetTempFileName()
    write-verbose "New DISM LogLevel [3]  LogPath: $LogPath"
    if ( -not ( get-module DISM ) ) { import-module DISM }
    @{ LogLevel = [Microsoft.Dism.Commands.LogLevel]::WarningsInfo ;  LogPath = $LogPath } | Write-Output
}