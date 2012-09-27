$progFilesX86 = (Get-Item "Env:ProgramFiles(x86)").Value 
$progFiles = (Get-Item "Env:ProgramFiles").Value
$env:path += ";" + $progFilesX86 + "\Git\bin"
$env:path += ";" + $progFiles + "\Vim\vim73"
$env:path += ";" + $prog
$env:path += ";" + (Get-Item "Env:Windir").Value + "\Microsoft.NET\Framework64\v4.0.30319"
$env:path += ";" + $progFiles + "\IIS Express"

