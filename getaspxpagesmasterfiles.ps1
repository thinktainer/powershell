$ErrorActionPreference = "Stop"
$NO_MASTER_PAGE = 'none'

if(Get-Module Memasp) {Remove-Module Memasp}
Import-Module Memasp 

Function MEMASP-GetMasterPagesWithoutTokens([string] $path){
	$pages = MEMASP-GetAspxPages($path)
	$uniqueMasterPages = MEMASP-GetUniqueMasterPages($pages)
	$uniqueMasterPages | Where-Object {$_.TokenPresent -eq $false}
}

Function MEMASP-GetPagesWithNoMasterPage([string] $path){
	$pages = MEMASP-GetAspxPages($path)
	$pages | Where-Object {$_.MasterPage -eq $NO_MASTER_PAGE}
}

