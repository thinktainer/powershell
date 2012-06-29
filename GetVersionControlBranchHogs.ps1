$loanBookBranchesDirectory = 'https://parkerfox.sourcerepo.com/parkerfox/svn/LoanBook2/branches';
$svn = 'svn';
$ls = 'ls';
$info = 'info';


function Get-SvnInfosForDirectoriesUnder ($repositoryUrl) {

	function SvnUtil-GetBranchUrls ($directoryName) {
		[string[]] $directoryPaths = @();
		$directoryNames = &$svn $ls $directoryName;
		$repositoryUrlTrimmed = $repositoryUrl.TrimEnd('/');
		foreach($directory in $directoryNames) {
			$directoryPaths += $repositoryUrl + '/' + $directory;
		}
		return $directoryPaths;
	}

	function SvnUtil-GetBranchInfoXml ($svnPath) {
		$xml = [xml](&$svn '--xml' 'info' $svnPath);

		if($xml -ne $null){
			return $xml;
		}
		return $null;
	}

	function SvnUtil-GetAuthor ($xmlSvnInfo) {
		return [string]$xmlSvnInfo.DocumentElement.SelectSingleNode("//author").InnerText;
	}

	function SvnUtil-GetSubmitDate ($xmlSvnInfo) {
		return [DateTime]$xmlSvnInfo.DocumentElement.SelectSingleNode("//date").InnerText;
	}

	function SvnUtil-GetBranchInfos ($directory) {
		return SvnUtil-GetBranchInfoXml(SvnUtil-GetBranchUrls($directory));
	}

	function New-SvnEntry (){
		param ([string]$url, [DateTime]$lastSubmitDate, [string]$author);
		$svnEntry = new-object PSObject | Select-Object Url, LastSubmit, Author;
		$svnEntry.Url = $url;
		$svnEntry.LastSubmit = $lastSubmitDate;
		$svnEntry.Author = $author;
		return $svnEntry;
	}

	$paths = SvnUtil-GetBranchUrls($repositoryUrl);
	$foundRepositories = @();
	$count = $paths.Count;
	for($i = 1; $i -le $count; $i++) {
		if($i % 10 -eq 0){
			Write-Host "$i out of $count records fetched";
		}
		$item = $paths[$i];
		Write-Host("Processing path: $item")
		$infoXml = SvnUtil-GetBranchInfoXml($paths[$i]);
		$lastSubmitDate = SvnUtil-GetSubmitDate($infoXml);
		$author = SvnUtil-GetAuthor($infoXml);
		$args = @{url=$paths[$i]; lastSubmitDate=$lastSubmitDate; author=$author}
		$entry = New-SvnEntry @args; 
		$foundRepositories = $foundRepositories + $entry;
	}
	return $foundRepositories;
}
