function Get-PathInfo {
    [CmdletBinding()]
    param (
        # Input Paths
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1)]
        [AllowEmptyString()]
        [string[]] $Paths,
        # Specifies the type of output path when the path does not exist. By default, it will guess path type. If path exists, this parameter is ignored.
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet("Directory", "File")]
        [string] $InputPathType,
        # Root directory to base relative paths. Default is current directory.
        [Parameter(Mandatory = $false, Position = 3)]
        [string] $DefaultDirectory = (Get-Location).ProviderPath,
        # Filename to append to path if no filename is present.
        [Parameter(Mandatory = $false, Position = 4)]
        [string] $DefaultFilename,
        #
        [Parameter(Mandatory = $false)]
        [switch] $SkipEmptyPaths
    )

    process {
        foreach ($Path in $Paths) {

            if (!$SkipEmptyPaths -and !$Path) { $Path = $DefaultDirectory }
            $OutputPath = $null

            if ($Path) {
                ## Look for existing path
                try {
                    $ResolvePath = Resolve-FullPath $Path -BaseDirectory $DefaultDirectory -ErrorAction Ignore
                    if ($ResolvePath) {
                        $OutputPath = Get-Item $ResolvePath -ErrorAction Ignore
                    }
                }
                catch { }
                if ($OutputPath -is [array]) {
                    $paramGetPathInfo = Select-PsBoundParameters $PSBoundParameters -CommandName Get-PathInfo -ExcludeParameters Paths
                    Get-PathInfo $OutputPath @paramGetPathInfo
                    return
                }

                [string] $AbsolutePath = $null
                ## If path could not be found and there are no wildcards, then create a FileSystemInfo object for the path.
                if (!$OutputPath -and $Path -notmatch '[*?]') {
                    ## Get Absolute Path
                    [string] $AbsolutePath = Get-FullPath $Path -BaseDirectory $DefaultDirectory
                    ## Guess if path is File or Directory
                    if ($InputPathType -eq "File" -or (!$InputPathType -and $AbsolutePath -match '[\\/](?!.*[\\/]).+\.(?!\.*$).*[^\\/]$')) {
                        $OutputPath = New-Object System.IO.FileInfo -ArgumentList $AbsolutePath
                    }
                    else {
                        $OutputPath = New-Object System.IO.DirectoryInfo -ArgumentList $AbsolutePath
                    }
                }
                ## If a DefaultFilename was provided and no filename was present in path, then add the default.
                if ($DefaultFilename -and $OutputPath -is [System.IO.DirectoryInfo]) {
                    [string] $AbsolutePath = (Join-Path $OutputPath.FullName $DefaultFileName)
                    $OutputPath = $null
                    try {
                        $ResolvePath = Resolve-FullPath $AbsolutePath -BaseDirectory $DefaultDirectory -ErrorAction Ignore
                        if ($ResolvePath) {
                            $OutputPath = Get-Item $ResolvePath -ErrorAction Ignore
                        }
                    }
                    catch { }
                    if (!$OutputPath -and $AbsolutePath -notmatch '[*?]') {
                        $OutputPath = New-Object System.IO.FileInfo -ArgumentList $AbsolutePath
                    }
                }

                if (!$OutputPath -or !$OutputPath.Exists) {
                    if ($OutputPath) { Write-Error -Exception (New-Object System.Management.Automation.ItemNotFoundException -ArgumentList ('Cannot find path ''{0}'' because it does not exist.' -f $OutputPath.FullName)) -TargetObject $OutputPath.FullName -ErrorId 'PathNotFound' -Category ObjectNotFound -ErrorAction $ErrorActionPreference }
                    elseif ($AbsolutePath) { Write-Error -Exception (New-Object System.Management.Automation.ItemNotFoundException -ArgumentList ('Cannot find path ''{0}'' because it does not exist.' -f $AbsolutePath)) -TargetObject $AbsolutePath -ErrorId 'PathNotFound' -Category ObjectNotFound -ErrorAction $ErrorActionPreference }
                    else { Write-Error -Exception (New-Object System.Management.Automation.ItemNotFoundException -ArgumentList ('Cannot find path ''{0}'' because it does not exist.' -f $Path)) -TargetObject $Path -ErrorId 'PathNotFound' -Category ObjectNotFound -ErrorAction $ErrorActionPreference }
                }
            }

            ## Return Path Info
            Write-Output $OutputPath
        }
    }
}