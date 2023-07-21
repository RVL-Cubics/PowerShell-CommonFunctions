[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param (
	# Specifies the path (optional) and file name of the program that runs in the process.
	[Parameter(Mandatory = $true, Position = 0)]
	[string] $FilePath,
	# Specifies parameters or parameter values to use when starting the process.
	[Parameter(Mandatory = $false)]
	[string[]] $ArgumentList,
	# Specifies the working directory for the process.
	[Parameter(Mandatory = $false)]
	[string] $WorkingDirectory,
	# Specifies a user account that has permission to perform this action.
	[Parameter(Mandatory = $false)]
	[pscredential] $Credential,
	# Regex pattern in cmdline to replace with '**********'
	[Parameter(Mandatory = $false)]
	[string[]] $SensitiveDataFilters
)
[hashtable] $paramStartProcess = $PSBoundParameters
foreach ($Parameter in $PSBoundParameters.Keys) {
	if ($Parameter -in 'SensitiveDataFilters') {
		$paramStartProcess.Remove($Parameter)
	}
}
[string] $cmd = '"{0}" {1}' -f $FilePath, ($ArgumentList -join ' ')
foreach ($Filter in $SensitiveDataFilters) {
	$cmd = $cmd -replace $Filter, '**********'
}
if ($PSCmdlet.ShouldProcess([System.Environment]::MachineName, $cmd)) {
	[System.Diagnostics.Process] $process = Start-Process -PassThru -Wait -NoNewWindow @paramStartProcess
	if ($process.ExitCode -ne 0) { Write-Error -Category FromStdErr -CategoryTargetName (Split-Path $FilePath -Leaf) -CategoryTargetType 'Process' -TargetObject $cmd -CategoryReason 'Exit Code not equal to 0' -Message ('Process [{0}] with Id [{1}] terminated with Exit Code [{2}]' -f $FilePath, $process.Id, $process.ExitCode) }
}
