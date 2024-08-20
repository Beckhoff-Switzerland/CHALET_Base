function Log {
	param (
		$message
	)

	$date = Get-Date -Format "o"
	Write-Host "${date}: ${message}"
}