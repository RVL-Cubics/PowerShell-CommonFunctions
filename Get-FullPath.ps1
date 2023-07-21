[CmdletBinding()]
[OutputType([string[]])]
param (
	# Input Paths
	[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
	[string[]] $Paths,
	# Directory to base relative paths. Default is current directory.
	[Parameter(Mandatory = $false, Position = 2)]
	[string] $BaseDirectory = (Get-Location).ProviderPath
)
process {
	foreach ($Path in $Paths) {
		[string] $AbsolutePath = $Path
		if (![System.IO.Path]::IsPathRooted($AbsolutePath)) {
			$AbsolutePath = (Join-Path $BaseDirectory $AbsolutePath)
		}
		[string] $AbsolutePath = [System.IO.Path]::GetFullPath($AbsolutePath)
		Write-Output $AbsolutePath
	}
}
