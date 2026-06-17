param(
    [string]$SourceRoot = "E:\LLMWiki\LLMWiki\RAW",
    [string]$TargetRoot = "E:\LLM_wiki\LLM_wiki\raw",
    [string]$ManifestRoot = "",
    [switch]$Execute
)

$ErrorActionPreference = "Stop"

$mappings = @(
    [pscustomobject]@{ Source = "00.WorkSpace";  Target = "00.WorkSpace" },
    [pscustomobject]@{ Source = "01.Inbox";      Target = "01.Inbox" },
    [pscustomobject]@{ Source = "02.Logs";       Target = "02.DailyNotes" },
    [pscustomobject]@{ Source = "03.Self-Notes"; Target = "03.SelfNotes" },
    [pscustomobject]@{ Source = "08.Interview";  Target = "04.Interview" },
    [pscustomobject]@{ Source = "09.Wechat";     Target = "05.Wechat" },
    [pscustomobject]@{ Source = "10.Zhihu";      Target = "06.Zhihu" },
    [pscustomobject]@{ Source = "06.Website";    Target = "07.Website" },
    [pscustomobject]@{ Source = "05.Research";   Target = "08.Research" },
    [pscustomobject]@{ Source = "07.BookCourse"; Target = "09.Book&Courses" },
    [pscustomobject]@{ Source = "04.GitHub";     Target = "10.GitHub" },
    [pscustomobject]@{ Source = "08.Leetcode";   Target = "11.Leetcode" }
)

function Resolve-ExistingDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Label does not exist or is not a directory: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).ProviderPath.TrimEnd("\")
}

function Join-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$ChildPath
    )

    $prefix = $BasePath.TrimEnd("\") + "\"
    if (-not $ChildPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is not under expected base. Base: $BasePath Child: $ChildPath"
    }

    return $ChildPath.Substring($prefix.Length)
}

$sourceRootPath = Resolve-ExistingDirectory -Path $SourceRoot -Label "SourceRoot"
$targetRootPath = Resolve-ExistingDirectory -Path $TargetRoot -Label "TargetRoot"

if ([string]::IsNullOrWhiteSpace($ManifestRoot)) {
    $ManifestRoot = Join-Path $targetRootPath "_migration_manifests"
}

if (-not (Test-Path -LiteralPath $ManifestRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $ManifestRoot | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$mode = if ($Execute) { "execute" } else { "dryrun" }
$csvPath = Join-Path $ManifestRoot "raw_migration_${mode}_${timestamp}.csv"
$jsonPath = Join-Path $ManifestRoot "raw_migration_${mode}_${timestamp}.json"

$rows = New-Object System.Collections.Generic.List[object]

foreach ($mapping in $mappings) {
    $sourceTopPath = Join-Path $sourceRootPath $mapping.Source
    $targetTopPath = Join-Path $targetRootPath $mapping.Target

    if (-not (Test-Path -LiteralPath $sourceTopPath -PathType Container)) {
        $rows.Add([pscustomobject]@{
            SourceTop = $mapping.Source
            TargetTop = $mapping.Target
            RelativePath = ""
            SourcePath = $sourceTopPath
            DestinationPath = $targetTopPath
            SizeBytes = 0
            SourceLastWriteTimeUtc = ""
            DestinationExists = $false
            ConflictType = "MissingSourceDirectory"
            Action = "skip"
            Copied = $false
            Error = "Source directory missing"
        })
        continue
    }

    $sourceTopResolved = (Resolve-Path -LiteralPath $sourceTopPath).ProviderPath.TrimEnd("\")
    $files = Get-ChildItem -LiteralPath $sourceTopResolved -File -Recurse -Force

    foreach ($file in $files) {
        $relativePath = Join-RelativePath -BasePath $sourceTopResolved -ChildPath $file.FullName
        $destinationPath = Join-Path $targetTopPath $relativePath
        $destinationExists = Test-Path -LiteralPath $destinationPath -PathType Leaf
        $conflictType = ""
        $action = if ($Execute) { "copy" } else { "would_copy" }
        $copied = $false
        $errorMessage = ""

        if ($destinationExists) {
            $destinationItem = Get-Item -LiteralPath $destinationPath
            if (($destinationItem.Length -eq $file.Length) -and ($destinationItem.LastWriteTimeUtc -eq $file.LastWriteTimeUtc)) {
                $conflictType = "ExistingIdenticalMetadata"
                $action = "skip_existing"
            }
            else {
                $conflictType = "ExistingDifferentMetadata"
                $action = "conflict_skip"
            }
        }

        if ($Execute -and -not $destinationExists) {
            try {
                $destinationParent = Split-Path -Path $destinationPath -Parent
                if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
                    New-Item -ItemType Directory -Path $destinationParent | Out-Null
                }

                Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -ErrorAction Stop
                $copiedItem = Get-Item -LiteralPath $destinationPath
                $copiedItem.CreationTimeUtc = $file.CreationTimeUtc
                $copiedItem.LastWriteTimeUtc = $file.LastWriteTimeUtc
                $copied = $true
            }
            catch {
                $action = "copy_failed"
                $errorMessage = $_.Exception.Message
            }
        }

        $rows.Add([pscustomobject]@{
            SourceTop = $mapping.Source
            TargetTop = $mapping.Target
            RelativePath = $relativePath
            SourcePath = $file.FullName
            DestinationPath = $destinationPath
            SizeBytes = $file.Length
            SourceLastWriteTimeUtc = $file.LastWriteTimeUtc.ToString("o")
            DestinationExists = $destinationExists
            ConflictType = $conflictType
            Action = $action
            Copied = $copied
            Error = $errorMessage
        })
    }
}

$rows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
$rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$summary = [pscustomobject]@{
    Mode = $mode
    SourceRoot = $sourceRootPath
    TargetRoot = $targetRootPath
    ManifestCsv = $csvPath
    ManifestJson = $jsonPath
    PlannedFiles = ($rows | Where-Object { $_.Action -eq "would_copy" }).Count
    CopiedFiles = ($rows | Where-Object { $_.Copied }).Count
    ExistingIdenticalMetadata = ($rows | Where-Object { $_.ConflictType -eq "ExistingIdenticalMetadata" }).Count
    ExistingDifferentMetadata = ($rows | Where-Object { $_.ConflictType -eq "ExistingDifferentMetadata" }).Count
    MissingSourceDirectories = ($rows | Where-Object { $_.ConflictType -eq "MissingSourceDirectory" }).Count
    CopyFailures = ($rows | Where-Object { $_.Action -eq "copy_failed" }).Count
    TotalManifestRows = $rows.Count
}

$summary | Format-List

if ($summary.ExistingDifferentMetadata -gt 0) {
    Write-Warning "One or more destination files already exist with different metadata. They were not copied over."
}

if ($summary.CopyFailures -gt 0) {
    throw "One or more copy operations failed. Review manifest: $csvPath"
}
