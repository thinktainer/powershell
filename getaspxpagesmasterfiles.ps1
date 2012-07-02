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
	$objects | Group-Object -Property MasterPage | %{$_.Group[0]}
	AddMasterPageHasCsrfTokenProperty($objects)
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
