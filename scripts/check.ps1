# Unified Flutter check: runs static analysis, then tests.
# Stops at the first failure and exits with that command's non-zero code.

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot

try {
    $steps = @(
        @{ Name = 'flutter analyze'; Args = @('analyze') },
        @{ Name = 'flutter test';    Args = @('test') }
    )

    foreach ($step in $steps) {
        Write-Host "==> Running $($step.Name)" -ForegroundColor Cyan
        & flutter @($step.Args)
        $code = $LASTEXITCODE
        if ($code -ne 0) {
            Write-Host "FAILED: $($step.Name) exited with code $code" -ForegroundColor Red
            exit $code
        }
    }

    Write-Host 'All checks passed: flutter analyze and flutter test succeeded.' -ForegroundColor Green
    exit 0
}
finally {
    Pop-Location
}
