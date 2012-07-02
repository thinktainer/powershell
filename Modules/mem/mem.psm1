$ErrorActionPreference = "Stop"
$masterFileRegex = New-Object -TypeName "System.Text.RegularExpressions.Regex" -ArgumentList @('MasterPageFile.*?"(?<mp>.*?)"', ([Text.RegularExpressions.RegexOptions]::Compiled -bor [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::InvariantCulture))
$pathComponent
$noMasterPage = 'none'

Function Get-WebDirectories {
	param([string] $dir=$(throw "dir required"))
	$projectPaths = @('LMS', 'Application_Form', 'UpdateDetails', 'AccountManagement')
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
	$noMaster = "NoMasterPage"
	$contentLines = Get-Content $file
	$properties = @{
					'MasterPage' = $noMasterPage;
					'Page' = $file;
	}
	foreach($line in $contentLines){
		if($masterFileRegex.IsMatch($line)){
			$properties.Set_Item('MasterPage', $masterFileRegex.Match($line).Groups["mp"].Value)
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

	if($object.MasterPage -eq $noMasterPage){
		return
	}

	$pagePathRawString = [string]$object.Page
	$pagePathString = $pagePathRawString.Substring($pagePathRawString.IndexOf("::"), $pagePathRawString.Length - $pagePathRawString.IndexOf("::")).TrimStart("::")
	Write-Debug ("PagePathString: $pagePathString")
	$(Find-MasterPageRecursivelyFromLeaf $pagePathString $object.MasterPage.Trimstart(@('~', '/')))[0]
}

Function Find-MasterPageRecursivelyFromLeaf ($directoryPathString, $masterPageFileName){
	Write-Debug "page path: $directoryPathString, master page: $masterPageFileName"
	$path = Get-ChildItem $directoryPathString -Recurse | ? {$_.Name -eq $masterPageFileName}
	if($path -eq $null)
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

