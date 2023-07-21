<#
.SYNOPSIS
    Convert Byte Array or Plain Text String to Base64 String.
.DESCRIPTION

.EXAMPLE
    PS C:\>ConvertTo-Base64String "A string with base64 encoding"
    Convert String with Default Encoding to Base64 String.
.EXAMPLE
    PS C:\>"ASCII string with base64url encoding" | ConvertTo-Base64String -Base64Url -Encoding Ascii
    Convert String with Ascii Encoding to Base64Url String.
.EXAMPLE
    PS C:\>ConvertTo-Base64String ([guid]::NewGuid())
    Convert GUID to Base64 String.
.INPUTS
    System.Object
#>
function ConvertTo-Base64String {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # Value to convert
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object] $InputObject,
        # Use base64url variant
        [Parameter (Mandatory = $false)]
        [switch] $Base64Url,
        # Output encoding to use for text strings
        [Parameter (Mandatory = $false)]
        [ValidateSet("Ascii", "UTF32", "UTF7", "UTF8", "BigEndianUnicode", "Unicode")]
        [string] $Encoding = "Default"
    )

    process {
        [byte[]] $inputBytes = $null
        if ($InputObject -is [byte[]] -or $InputObject -is [byte]) {
            $inputBytes = $InputObject
        }
        elseif ($InputObject -is [string]) {
            $inputBytes = [Text.Encoding]::$Encoding.GetBytes($InputObject)
        }
        elseif ($InputObject -is [bool] -or $InputObject -is [char] -or $InputObject -is [single] -or $InputObject -is [double] -or $InputObject -is [int16] -or $InputObject -is [int32] -or $InputObject -is [int64] -or $InputObject -is [uint16] -or $InputObject -is [uint32] -or $InputObject -is [uint64]) {
            $inputBytes = [System.BitConverter]::GetBytes($InputObject)
        }
        elseif ($InputObject -is [guid]) {
            $inputBytes = $InputObject.ToByteArray()
        }
        elseif ($InputObject -is [System.IO.FileSystemInfo]) {
            $inputBytes = Get-Content $InputObject.FullName -Raw -Encoding Byte
        }
        else {
            # Otherwise, write a non-terminating error message indicating that input object type is not supported.
            $errorMessage = "Cannot convert input of type {0} to Base64 string." -f $InputObject.GetType()
            Write-Error -Message $errorMessage -Category ([System.Management.Automation.ErrorCategory]::ParserError) -ErrorId "ConvertBase64StringFailureTypeNotSupported"
        }

        if ($inputBytes) {
            [string] $outBase64String = [System.Convert]::ToBase64String($inputBytes)
            if ($Base64Url) { $outBase64String = $outBase64String.Replace('+', '-').Replace('/', '_').Replace('=', '') }
            return $outBase64String
        }
    }
}