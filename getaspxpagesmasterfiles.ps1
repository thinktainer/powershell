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

Function Get-UniqueMasterPages($objects){
	$uniqueObjects = $objects | Group-Object -Property MasterPage | %{$_.Group[0]}
	AddMasterPageHasCsrfTokenProperty($uniqueObjects)
}

Function AddMasterPageHasCsrfTokenProperty($objects){
	foreach ($item in $objects){
		if($item.MasterPage -ne 'none')
		{
			Write-Debug "$item"
			$masterFilePath = $(Get-MasterPagePath($item)).FullName
			$item | Add-Member -Name "TokenPresent" -MemberType NoteProperty -Force -Value $(Find-CsrfTokenInFile($masterFilePath)) -PassThru
		}
	}
}

Function Get-MasterPagesWithoutTokens([string] $path){
	$pages = Get-AspxPages($path)
	$uniqueMasterPages = Get-UniqueMasterPages($pages)
	$uniqueMasterPages | Where-Object {$_.TokenPresent -eq $false}
}
