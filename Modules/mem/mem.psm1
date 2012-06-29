$ErrorActionPreference = "Stop"
$masterFileRegex = New-Object -TypeName "System.Text.RegularExpressions.Regex" -ArgumentList @('MasterPageFile.*?"(?<mp>.*?)"', ([Text.RegularExpressions.RegexOptions]::Compiled -bor [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::InvariantCulture))


Function Get-WebDirectories {
	param([string] $dir=$(throw "dir required"))
	$projectPaths = @('LMS', 'Application_Form', 'UpdateDetails', 'AccountManagement')
	foreach($subPath in $projectPaths){
		$dir.TrimEnd(@('/', '\')) + '\' + $subPath
	}
}
Function Get-AspxFiles {
	param([string] $dir=$(throw "dir required"))
	Get-ChildItem -Recurse $dir | Where-Object {$_.Name.EndsWith('aspx')}
}

Function Find-PagesWithAndWithoutMasterFiles ($files){
	foreach ($file in $files) {
		Find-MasterPageMatch($file)
	}
}

Function Find-MasterPageMatch($file){
	$noMaster = "NoMasterPage"
	$contentLines = Get-Content $file
	$properties = @{
					'MasterPage' = 'none';
					'Page' = $file;
	}
	foreach($line in $contentLines){
		if($masterFileRegex.IsMatch($line)){
			$properties.Set_Item('MasterPage', $masterFileRegex.Match($line).Groups["mp"].Value;)
			}
	}
	New-Object -TypeName PSObject -Prop $properties
}
