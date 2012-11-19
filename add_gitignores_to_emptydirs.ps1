 gci -Recurse | ?{$_.PSIsContainer -and $_.GetFileSystemInfos().Count -eq 0}  | New-Item (Join-Path $_.PSPath '.gitignore') -type file
