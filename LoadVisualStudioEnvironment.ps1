function Get-Batchfile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        Set-Item -path env:$p -value $v
    }
}

$progFilesX86 = (Get-Item "Env:ProgramFiles(x86)").Value 

Get-BatchFile($progFilesX86 + "\Microsoft Visual Studio 11.0\VC\vcvarsall.bat")

Write-Host -ForegroundColor Yellow -BackgroundColor Black "Visual Studio Environment Variables loaded"
