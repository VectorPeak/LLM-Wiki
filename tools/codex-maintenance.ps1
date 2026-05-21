param(
    [switch]$Apply,
    [int]$LargeSessionMB = 30,
    [int]$KeepRecentDays = 14
)

$ErrorActionPreference = "Stop"

$CodexHome = Join-Path $env:USERPROFILE ".codex"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path $CodexHome ("maintenance-backups\" + $Stamp)
$ReportPath = Join-Path $BackupRoot "report.txt"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
    if ($script:ReportPath) {
        Add-Content -LiteralPath $script:ReportPath -Value ("==> " + $Message)
    }
}

function Ensure-BackupRoot {
    if (-not (Test-Path -LiteralPath $BackupRoot)) {
        New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
    }
    if (-not (Test-Path -LiteralPath $ReportPath)) {
        New-Item -ItemType File -Force -Path $ReportPath | Out-Null
    }
}

function Get-SizeMB {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.PSIsContainer) {
        $files = Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue
        return [math]::Round((($files | Measure-Object Length -Sum).Sum) / 1MB, 2)
    }
    return [math]::Round($item.Length / 1MB, 2)
}

function Assert-CodexStopped {
    $running = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -in @("Codex", "codex") }
    if ($running) {
        Write-Host "Codex is still running. Close Codex Desktop and any codex CLI sessions before using -Apply." -ForegroundColor Yellow
        $running | Select-Object ProcessName, Id, Path | Format-Table -AutoSize
        if ($Apply) {
            throw "Refusing to mutate Codex state while Codex processes are running."
        }
    }
}

Ensure-BackupRoot
Write-Step "Codex home: $CodexHome"
Write-Step "Mode: $(if ($Apply) { 'APPLY' } else { 'DRY RUN' })"
Assert-CodexStopped

$targets = @(
    "logs_2.sqlite",
    "logs_2.sqlite-wal",
    "logs_2.sqlite-shm",
    "log\codex-tui.log",
    "logs\remote-control.err.log"
)

Write-Step "Log files selected for backup/rotation"
foreach ($rel in $targets) {
    $src = Join-Path $CodexHome $rel
    if (Test-Path -LiteralPath $src) {
        $mb = Get-SizeMB $src
        Write-Host ("  {0}  {1} MB" -f $rel, $mb)
        Add-Content -LiteralPath $ReportPath -Value ("LOG_TARGET`t{0}`t{1} MB" -f $rel, $mb)
        if ($Apply) {
            $dest = Join-Path $BackupRoot $rel
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
            Move-Item -LiteralPath $src -Destination $dest -Force
        }
    }
}

Write-Step "Plugin clone temp directories"
$tmp = Join-Path $CodexHome ".tmp"
$pluginCloneDirs = @()
if (Test-Path -LiteralPath $tmp) {
    $pluginCloneDirs = Get-ChildItem -LiteralPath $tmp -Directory -Force -Filter "plugins-clone-*" -ErrorAction SilentlyContinue
}
foreach ($dir in $pluginCloneDirs) {
    $mb = Get-SizeMB $dir.FullName
    Write-Host ("  {0}  {1} MB" -f $dir.FullName, $mb)
    Add-Content -LiteralPath $ReportPath -Value ("PLUGIN_CLONE`t{0}`t{1} MB" -f $dir.FullName, $mb)
    if ($Apply) {
        Remove-Item -LiteralPath $dir.FullName -Recurse -Force
    }
}

Write-Step "Large old session files selected for external backup"
$sessionBackup = Join-Path $BackupRoot "large-sessions"
$sessionRoots = @("sessions", "archived_sessions") | ForEach-Object { Join-Path $CodexHome $_ }
$cutoff = (Get-Date).AddDays(-1 * $KeepRecentDays)
foreach ($root in $sessionRoots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    Get-ChildItem -LiteralPath $root -Recurse -File -Force -Filter "*.jsonl" -ErrorAction SilentlyContinue |
        Where-Object { ($_.Length / 1MB) -ge $LargeSessionMB -and $_.LastWriteTime -lt $cutoff } |
        Sort-Object Length -Descending |
        ForEach-Object {
            $rel = $_.FullName.Substring($CodexHome.Length).TrimStart("\")
            $mb = [math]::Round($_.Length / 1MB, 2)
            Write-Host ("  {0}  {1} MB" -f $rel, $mb)
            Add-Content -LiteralPath $ReportPath -Value ("LARGE_SESSION`t{0}`t{1} MB" -f $rel, $mb)
            if ($Apply) {
                $dest = Join-Path $sessionBackup $rel
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
                Move-Item -LiteralPath $_.FullName -Destination $dest -Force
            }
        }
}

Write-Step "Summary"
Write-Host "Report: $ReportPath"
if (-not $Apply) {
    Write-Host "Dry run only. Re-run with -Apply after fully closing Codex to move/clean files." -ForegroundColor Yellow
}
