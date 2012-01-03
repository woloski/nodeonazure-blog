$pathToAppend = $args[0];

$path = Get-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -name Path
if (-not ($path.Path -like "*$pathToAppend*")) {
	$newPath = $path.Path + ";" + $pathToAppend;
	Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -name Path -Value $newPath	
}
