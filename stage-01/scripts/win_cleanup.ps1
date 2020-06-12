$tempFiles = Test-Path -Path C:\\windows\\temp
if ($tempFiles) {
    Remove-Item -Path C:\\Windows\\temp\\*.ps1 -Recurse -Force
}