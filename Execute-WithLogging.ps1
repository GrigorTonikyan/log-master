# Wrapper script for executing commands with logging
param(
    [Parameter(Mandatory = $true)]
    [string]$Command,
    
    [Parameter(Mandatory = $false)]
    [string[]]$Arguments = @(),
    
    [Parameter(Mandatory = $false)]
    [string]$WorkingDirectory = (Get-Location),
    
    [Parameter(Mandatory = $false)]
    [switch]$PassThru
)

# Import logging module
$loggerPath = Join-Path $PSScriptRoot "logger.ps1"
. $loggerPath

# Initialize logging if not already initialized
if (-not $script:LogConfig.CurrentSession) {
    Initialize-LogSession
}

try {
    # Log command execution
    $cmdId = Write-CommandLog -Command $Command -Arguments $Arguments -WorkingDirectory $WorkingDirectory
    
    # Execute command and capture output
    $output = $null
    $error = $null
    $exitCode = 0
    
    try {
        if ($Arguments.Count -gt 0) {
            $output = & $Command $Arguments 2>&1
        }
        else {
            $output = & $Command 2>&1
        }
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq $null) { $exitCode = 0 }
    }
    catch {
        $error = $_.Exception.Message
        $exitCode = 1
    }
    
    # Log command output
    Write-CommandOutput -CommandId $cmdId -StdOut $output -StdErr $error -ExitCode $exitCode
    
    # Return output if requested
    if ($PassThru) {
        return @{
            CommandId = $cmdId
            Output    = $output
            Error     = $error
            ExitCode  = $exitCode
        }
    }
}
catch {
    Write-Log "Error executing command: $_" "ERROR"
    throw
}
