$REGEX_OPTIONS = @([Text.RegularExpressions.RegexOptions]::Compiled -bor 
		[Text.RegularExpressions.RegexOptions]::IgnoreCase -bor 
		[Text.RegularExpressions.RegexOptions]::InvariantCulture)

$MULTILINE = @([Text.RegularExpressions.RegexOptions]::Compiled -bor 
		[Text.RegularExpressions.RegexOptions]::IgnoreCase -bor 
		[Text.RegularExpressions.RegexOptions]::InvariantCulture -bor
		[Text.RegularExpressions.RegexOptions]::Singleline)

$MASTERFILE_REGEX = New-Object -TypeName "System.Text.RegularExpressions.Regex" -ArgumentList @('MasterPageFile.*?"(~/)?((\w+/)+)?(?<mp>.*?)"', $REGEX_OPTIONS) 

$CSRF_INPUTFIELD_REGEX = New-Object -TypeName "System.Text.RegularExpressions.Regex" -ArgumentList @('<memCapital:AntiCsrfTokenControl', $REGEX_OPTIONS)

$FORM_FIELD_REGEX = New-Object -TypeName "System.Text.RegularExpressions.Regex" -ArgumentList @('<form.*/form>', $MULTILINE)


$PROJECT_PATHS = @('LMS', 'BrokerArea', 'Application_Form', 'UpdateDetails', 'AccountManagement')

Function MEMASP-GetPagesWithMasterPages([string] $solutionDir){
	$webDirs = MEMASP-GetWebDirectories($solutionDir)
	Write-Debug("$webDirs")
	$aspxPagePaths = foreach($webDir in $webDirs){
		MEMASP-GetAspxFilePaths($webDir)
	}
	Write-Debug("$aspxPagePaths")
	$pagesWithMasterPage = foreach($path in $aspxPagePaths){
		MEMASP-FindMasterPagesInPages($path)
	}
	$pagesWithMasterPage
}

Function MEMASP-GetAspxPages([string] $solutionDir){
	$webDirs = MEMASP-GetWebDirectories($solutionDir)
	Write-Debug("$webDirs")
	$aspxPagePaths = foreach($webDir in $webDirs){
		MEMASP-GetAspxFilePaths($webDir)
	}
	Write-Debug("$aspxPagePaths")
	$pagesWithMasterPage = foreach($path in $aspxPagePaths){
		MEMASP-FindMasterPagesInPages($path)
	}
	$pagesWithMasterPage
}

Function MEMASP-GetUniqueMasterPages($objects){
	$uniqueObjects = $objects | Group-Object -Property MasterPage | %{$_.Group[0]}
	MEMASP-AddMasterPageHasCsrfTokenProperty($uniqueObjects)
}

Function MEMASP-AddMasterPageHasCsrfTokenProperty($objects){
	foreach ($item in $objects){
		if($item.MasterPage -ne 'none')
		{
			Write-Debug "$item"
			$masterFilePath = $(MEMASP-GetMasterPagePath($item)).FullName
			$item | Add-Member -Name "TokenPresent" -MemberType NoteProperty -Force -Value $(MEMASP-FindCsrfTokenInFile($masterFilePath)) -PassThru
		}
	}
}
Function MEMASP-GetWebDirectories {
	param([string] $dir=$(throw "dir required"))
	$projectPaths = $PROJECT_PATHS 
	foreach($subPath in $projectPaths){
		$dir.TrimEnd(@('/', '\')) + '\' + $subPath
	}
}
Function MEMASP-GetAspxFilePaths {
	param([string] $dir=$(throw "dir required"))
	Get-ChildItem -Recurse $dir | Where-Object {$_.Name.EndsWith('aspx')} | Select -Expand PSPath
}

Function MEMASP-FindMasterPagesInPages ($files){
	foreach ($file in $files) {
		MEMASP-FindMasterPageMatch($file)
	}
}

Function MEMASP-FindMasterPageMatch($file){
	$contentLines = Get-Content $file
	$properties = @{
					'MasterPage' = $NO_MASTER_PAGE;
					'Page' = $file;
	}
	foreach($line in $contentLines){
		if($MASTERFILE_REGEX.IsMatch($line)){
			$properties.Set_Item('MasterPage', $MASTERFILE_REGEX.Match($line).Groups["mp"].Value)
			}
	}
	New-Object -TypeName PSObject -Prop $properties | Write-Output
}

Function MEMASP-GetMasterPagePath($object){
	if($object.MasterPage -eq $null){
		throw ("No MasterPage in object $object")
	}
	if($object.Page -eq $null){
		throw ("No page path in object $object")
	}

	if($object.MasterPage -eq $NO_MASTER_PAGE){
		throw("Certainly no master page for: $NO_MASTER_PAGE")
	}


	$trimmedPath = $object.MasterPage.Trimstart(@('~', '/'))
	$(MEMASP-FindMasterPageRecursivelyFromLeaf $($object.Page | Convert-Path) $trimmedPath)[0] 
}

Function MEMASP-FindMasterPageRecursivelyFromLeaf ($directoryPathString, $masterPageFileName){

	Write-Debug "page path: $directoryPathString, master page: $masterPageFileName"

	$path = Get-ChildItem $directoryPathString -Recurse | ? {$_.Name -eq $masterPageFileName}

	$lastPathFragment = $directoryPathString.Substring($directoryPathString.LastIndexOf('\'), $directoryPathString.Length - $directoryPathString.LastIndexOf('\')).Trim('\')

	Write-Debug "Last Path Fragment: $lastPathFragment"
	$isRootAppPath = $PROJECT_PATHS -contains $lastPathFragment 
	if($path -eq $null -and -not $isRootAppPath) 
	{
		$directoryName = MEMASP-StripLastPathComponent($directoryPathString)
		MEMASP-FindMasterPageRecursivelyFromLeaf $directoryName $masterPageFileName
	}
	$path
}

Function MEMASP-StripLastPathComponent ($path){
	Write-Debug "Path: $path"
	$path.Substring(0, $path.LastIndexOf('\'))
}

Function MEMASP-FindCsrfTokenInFile{
	param([string] $path = $(throw "Path cannot be null"))
	if(!(Test-Path $path)){
		Write-Host "No file at: $path"
		return
	}
	$CSRF_INPUTFIELD_REGEX.IsMatch($(Get-Content($path)))
}

Function MEMASP-FindHtmlFileFormField{
	param([string] $path = $(throw "Path cannot be null"))
	if(-not (Test-Path($path))){
		Write-Host "No file at: $path"
		return
	}
	$FORM_FIELD_REGEX.IsMatch($(Get-Content $path))
}

Function MEMASP-AddMasterPageHasCsrfTokenProperty($objects){
	foreach ($item in $objects){
		if($item.MasterPage -ne 'none')
		{
			Write-Debug "$item"
			$masterFilePath = $(MEMASP-GetMasterPagePath($item)).FullName
			$item | Add-Member -Name "TokenPresent" -MemberType NoteProperty -Force -Value $(MEMASP-FindCsrfTokenInFile($masterFilePath)) -PassThru
		}
	}
}

Function MEMASP-GetUniqueMasterPages($objects){
	$uniqueObjects = $objects | Group-Object -Property MasterPage | %{$_.Group[0]}
	MEMASP-AddMasterPageHasCsrfTokenProperty($uniqueObjects)
}

