param(
    [string]$Runtime = "win-x64"
)

$ErrorActionPreference = "Stop"

function Invoke-Checked {
    param([scriptblock]$Command)
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code $LASTEXITCODE"
    }
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$probeProject = Join-Path $root "src\OYScannerProbe\OYScannerProbe.csproj"
$analyzerProject = Join-Path $root "src\OYScanArchiveAnalyzer\OYScanArchiveAnalyzer.csproj"
$automationProject = Join-Path $root "src\OYAutomationProbe\OYAutomationProbe.csproj"
$pilotProject = Join-Path $root "src\OYAutomationPilot\OYAutomationPilot.csproj"
$dist = Join-Path $root "dist"

if (-not (Test-Path $dist)) {
    New-Item -ItemType Directory -Path $dist | Out-Null
}

$publishArgs = @(
    "-c", "Release",
    "-r", $Runtime,
    "--self-contained", "true",
    "/p:PublishSingleFile=true",
    "/p:IncludeNativeLibrariesForSelfExtract=true",
    "/p:EnableCompressionInSingleFile=true",
    "-o", $dist
)

Invoke-Checked { dotnet publish $probeProject @publishArgs }
Invoke-Checked { dotnet publish $analyzerProject @publishArgs }
Invoke-Checked { dotnet publish $automationProject @publishArgs }
Invoke-Checked { dotnet publish $pilotProject @publishArgs }

Copy-Item -LiteralPath (Join-Path $root "probe.config.json") -Destination (Join-Path $dist "probe.config.json") -Force

Write-Host "Done: $dist\OYScannerProbe.exe"
Write-Host "Done: $dist\OYScanArchiveAnalyzer.exe"
Write-Host "Done: $dist\OYAutomationProbe.exe"
Write-Host "Done: $dist\OYAutomationPilot.exe"

