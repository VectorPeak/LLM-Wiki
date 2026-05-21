param(
    [int]$TimeoutSeconds = 900
)

$ErrorActionPreference = "Stop"

$CodexHome = Join-Path $env:USERPROFILE ".codex"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path $CodexHome ("maintenance-backups\deferred-log-rotation-" + $Stamp)
$ReportPath = Join-Path $BackupRoot "report.txt"

New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
New-Item -ItemType File -Force -Path $ReportPath | Out-Null

function Log {
    param([string]$Message)
    $line = "$(Get-Date -Format s) $Message"
    Add-Content -LiteralPath $ReportPath -Value $line
    Write-Host $line
}

Log "Waiting for Codex/codex processes to exit. TimeoutSeconds=$TimeoutSeconds"
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    $running = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -in @("Codex", "codex") }
    if (-not $running) {
        break
    }
    Start-Sleep -Seconds 2
}

$stillRunning = Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -in @("Codex", "codex") }
if ($stillRunning) {
    Log "Timed out. Codex processes are still running; no log files moved."
    $stillRunning | Select-Object ProcessName, Id, Path | Out-String | Add-Content -LiteralPath $ReportPath
    exit 2
}

Log "Codex processes are stopped. Rotating logs_2.sqlite files."
$files = @(
    Get-Item -LiteralPath (Join-Path $CodexHome "logs_2.sqlite") -ErrorAction SilentlyContinue
    Get-Item -LiteralPath (Join-Path $CodexHome "logs_2.sqlite-wal") -ErrorAction SilentlyContinue
    Get-Item -LiteralPath (Join-Path $CodexHome "logs_2.sqlite-shm") -ErrorAction SilentlyContinue
)

foreach ($file in $files) {
    if (-not $file) { continue }
    $dest = Join-Path $BackupRoot $file.Name
    Move-Item -LiteralPath $file.FullName -Destination $dest -Force
    Log "Moved $($file.FullName) -> $dest"
}

Log "Done."
