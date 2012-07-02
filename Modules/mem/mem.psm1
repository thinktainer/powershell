$ErrorActionPreference = "Stop"

$REGEX_OPTIONS = @([Text.RegularExpressions.RegexOptions]::Compiled -bor 
		[Text.RegularExpressions.RegexOptions]::IgnoreCase -bor 
		[Text.RegularExpressions.RegexOptions]::InvariantCulture)

$MASTERFILE_REGEX = New-Object -TypeName "System.Text.RegularExpressions.Regex" -ArgumentList @('MasterPageFile.*?"(~/)?((\w+/)+)?(?<mp>.*?)"', $REGEX_OPTIONS) 

$CSRF_INPUTFIELD_REGEX = New-Object -TypeName "System.Text.RegularExpressions.Regex" -ArgumentList @('<memCapital:AntiCsrfTokenControl', $REGEX_OPTIONS)

$NO_MASTER_PAGE = 'none'
$PROJECT_PATHS = @('LMS', 'Application_Form', 'UpdateDetails', 'AccountManagement')

Function Get-WebDirectories {
	param([string] $dir=$(throw "dir required"))
	$projectPaths = $PROJECT_PATHS 
	foreach($subPath in $projectPaths){
		$dir.TrimEnd(@('/', '\')) + '\' + $subPath
	}
}
Function Get-AspxFilePaths {
	param([string] $dir=$(throw "dir required"))
	Get-ChildItem -Recurse $dir | Where-Object {$_.Name.EndsWith('aspx')} | Select -Expand PSPath
}

Function Find-MasterPagesInPages ($files){
	foreach ($file in $files) {
		Find-MasterPageMatch($file)
	}
}

Function Find-MasterPageMatch($file){
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

Function Get-MasterPagePath($object){
	if($object.MasterPage -eq $null){
		throw ("No MasterPage in object $object")
	}
	if($object.Page -eq $null){
		throw ("No page path in object $object")
	}

	if($object.MasterPage -eq $NO_MASTER_PAGE){
		throw("Certainly no master page for: $NO_MASTER_PAGE")
	}

	$pagePathRawString = [string]$object.Page
	$pagePathString = $pagePathRawString.Substring($pagePathRawString.IndexOf("::"), $pagePathRawString.Length - $pagePathRawString.IndexOf("::")).TrimStart("::")
	Write-Debug ("PagePathString: $pagePathString")
	$trimmedPath = $object.MasterPage.Trimstart(@('~', '/'))
	$(Find-MasterPageRecursivelyFromLeaf $pagePathString $trimmedPath)[0] 
}

Function Find-MasterPageRecursivelyFromLeaf ($directoryPathString, $masterPageFileName){
	Write-Debug "page path: $directoryPathString, master page: $masterPageFileName"
	$path = Get-ChildItem $directoryPathString -Recurse | ? {$_.Name -eq $masterPageFileName}
	$lastPathFragment = $directoryPathString.Substring($directoryPathString.LastIndexOf('\'), $directoryPathString.Length - $directoryPathString.LastIndexOf('\')).Trim('\')
	Write-Debug "Last Path Fragment: $lastPathFragment"
	$isRootAppPath = $PROJECT_PATHS -contains $lastPathFragment 
	if($path -eq $null -and -not $isRootAppPath) 
	{
		$directoryName = StripLastPathComponent($directoryPathString)
		Find-MasterPageRecursivelyFromLeaf $directoryName $masterPageFileName
	}
	$path
}

Function StripLastPathComponent ($path){
	Write-Debug "Path: $path"
	$path.Substring(0, $path.LastIndexOf('\'))
}

Function Find-CsrfTokenInFile{
	param([string] $path = $(throw "Path cannot be null"))
	if(!(Test-Path $path)){
		Write-Host "No file at: $path"
		return
	}
	$CSRF_INPUTFIELD_REGEX.IsMatch($(Get-Content($path)))
}

