<#
.SYNOPSIS
    Short description of what the script does.

.DESCRIPTION
    Detailed description of the script, including its purpose and functionality.

.PARAMETER FirstArgument
    Description of the first argument.

.PARAMETER SecondArgument
    Description of the second argument.

.PARAMETER NthArgument
    Description of the n-th argument.

.EXAMPLE
    Typical example of usage of the script.
    Example: .\YourScript.ps1 -FirstArgument value1 -SecondArgument value2

.OUTPUTS
    [OutputType] Description of what the script outputs to stdout.
    [OutputType] Description of what the script outputs to stderr.

.RETURN
    Description of the return codes and what they signify.

.AUTHOR
    Francisco Güemes

.EMAIL
    francisco@franciscoguemes.com

.LINK
    https://stackoverflow.com/questions/14008125/shell-script-common-template
    https://devhints.io/powershell
    https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/powershell-scripting-best-practices?view=powershell-7.2
    https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-powershell

#>

# Enable strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Parameter declaration
param(
    [Parameter(Mandatory=$false)]
    [switch]$Debug,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

# Function documentation and definition example
function Invoke-YourFunction {
    <#
    .SYNOPSIS
        Brief description of the function
    
    .DESCRIPTION
        Detailed description of what the function does
    
    .PARAMETER InputParam1
        Description of first parameter
    
    .PARAMETER InputParam2
        Description of second parameter
    
    .OUTPUTS
        What the function returns
    
    .EXAMPLE
        Invoke-YourFunction -InputParam1 "value1" -InputParam2 "value2"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputParam1,
        
        [Parameter(Mandatory=$true)]
        [string]$InputParam2
    )
    
    try {
        # Function logic here
        Write-Verbose "Processing with parameters: $InputParam1, $InputParam2"
        return "$InputParam1 - $InputParam2"
    }
    catch {
        Write-Error "An error occurred: $_"
        throw
    }
}

# Import other PowerShell modules/scripts
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptPath\OtherScript.ps1"

# Variable examples
$Variable1 = "Your variable definition"
$Variable2 = "Another variable definition"

# Call function and handle its result
try {
    $result = Invoke-YourFunction -InputParam1 $Variable1 -InputParam2 $Variable2
    
    if ($result) {
        Write-Output "Function completed successfully with result: $result"
    }
}
catch {
    Write-Error "Function failed: $_"
    exit 1
}

# String manipulation examples
$ConcatenatedString = "$Variable1$Variable2"
$FormattedString = "${Variable1}My literal string ${Variable2}"
$CommandOutput = "The date of today is: $(Get-Date)"

# File iteration example
Get-ChildItem -Path $PWD | ForEach-Object {
    Write-Output $_.Name
    if ($_.Name -match "\d{8}_\d{6}") {
        Write-Output "Found date pattern in filename"
    }
}

# Numeric iteration example
Write-Output "Counting sheep..."
1..3 | ForEach-Object {
    Write-Output "    $_"
    Start-Sleep -Seconds $_
}

# Read input example
$Country = Read-Host -Prompt "Enter the name of a country"

# Switch statement example
Write-Host "The official language of $Country is " -NoNewline
switch -Regex ($Country) {
    "Lithuania" { 
        Write-Host "Lithuanian" -NoNewline
    }
    "Romania|Moldova" { 
        Write-Host "Romanian" -NoNewline
    }
    "Italy|San Marino|Switzerland|Vatican City" { 
        Write-Host "Italian" -NoNewline
    }
    default { 
        Write-Host "unknown" -NoNewline
    }
}

# Array and hashtable examples
$Array = @("item1", "item2", "item3")
$HashTable = @{
    Key1 = "Value1"
    Key2 = "Value2"
    Key3 = "Value3"
}

# Pipeline example
Get-Process | 
    Where-Object { $_.CPU -gt 10 } | 
    Select-Object Name, CPU, Memory | 
    Sort-Object CPU -Descending |
    Select-Object -First 5

# Error handling with try-catch-finally
try {
    # Some risky operation
    $null.ToString()
}
catch [System.NullReferenceException] {
    Write-Error "Null reference exception occurred"
}
catch {
    Write-Error "An unexpected error occurred: $_"
}
finally {
    Write-Output "This will always execute"
}