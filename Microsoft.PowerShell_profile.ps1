# environment variables
$progFilesX86 = (Get-Item "Env:ProgramFiles(x86)").Value 
$progFiles = (Get-Item "Env:ProgramFiles").Value
$env:path += ";" + $progFilesX86 + "\Git\bin"
$env:path += ";" + $progFiles + "\Vim\vim73"
$env:path += ";" + $prog
$env:path += ";" + (Get-Item "Env:Windir").Value + "\Microsoft.NET\Framework64\v4.0.30319"
$env:path += ";" + $progFiles + "\IIS Express"
function Get-Batchfile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        Set-Item -path env:$p -value $v
    }
}

# set up build environment

Get-BatchFile($progFilesX86 + "\Microsoft Visual Studio 10.0\VC\vcvarsall.bat")

# source git module
. 'C:\Users\mschinz\Documents\WindowsPowerShell\Modules\posh-git\profile.example.ps1'

# aliases
Set-Alias vim vim.exe
