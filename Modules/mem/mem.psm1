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
	$pageMatches = @{}
	$noMaster = "noMasterPage"
	$pageMatches.Add($noMaster, @())
	foreach ($file in $files) {
		$contentLines = Get-Content $file
		[bool] $found = $FALSE;
		foreach($line in $contentLines){
			if($masterFileRegex.IsMatch($line)){
				$currentMatch = $masterFileRegex.Match($line).Groups["mp"].Value
				$pages = @();
				if($pageMatches.ContainsKey($currentMatch)){
					$pageMatches[$currentMatch] += $file
				} else {
					$pageMatches.Add($currentMatch, @($file))
				}
				$found = $TRUE;
				break
			}
		}
		if(!$found){
			$pageMatches[$noMaster] += $file
			Write-Host "No match in $file"
		} else {
			Write-Host "File matches $file"
		}
	}
	return $pageMatches;
}
