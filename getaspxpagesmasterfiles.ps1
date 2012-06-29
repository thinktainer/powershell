$ErrorActionPreference = "Stop"
Import-Module mem -Force

Function Get-AspxPages([string] $solutionDir){
	$webDirs = Get-WebDirectories($solutionDir)
	Write-Debug("$webDirs")
	$aspxPagePaths = foreach($webDir in $webDirs){
		Get-AspxFilePaths($webDir)
	}
	Write-Debug("$aspxPagePaths")
	$pagesWithMasterPage = foreach($path in $aspxPagePaths){
		Find-MasterPagesInPages($path)
	}
	$pagesWithMasterPage
}
