function New-TemporaryDirectory {
    $tempfile = [System.IO.Path]::GetTempFileName()
    remove-item $tempfile
    new-item -type directory -path $tempfile
}