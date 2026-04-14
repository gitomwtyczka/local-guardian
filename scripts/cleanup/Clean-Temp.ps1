<#
.SYNOPSIS
    Clean-Temp.ps1 — czyści pliki tymczasowe Windows
    Workspace: local-guardian
    Author: [local-worker 01] | 14.04.2026

.DESCRIPTION
    Usuwa pliki tymczasowe z katalogów:
    - $env:TEMP (user temp)
    - $env:WINDIR\Temp (system temp)
    - $env:LOCALAPPDATA\Temp
    Opcjonalnie czyści Prefetch (wymaga admina).

.PARAMETER WhatIf
    Raportuje co zostałoby usunięte, ale nic nie usuwa.

.PARAMETER IncludePrefetch
    Dołącza katalog Prefetch (wymaga uprawnień administratora).

.EXAMPLE
    .\Clean-Temp.ps1 -WhatIf
    .\Clean-Temp.ps1
    .\Clean-Temp.ps1 -IncludePrefetch
#>

param(
    [switch]$WhatIf,
    [switch]$IncludePrefetch
)

Write-Host "=== Local Guardian — Temp Cleaner ===" -ForegroundColor Cyan
Write-Host "Workspace: local-guardian | [local-worker 01]" -ForegroundColor DarkCyan

if ($WhatIf) {
    Write-Host "[TRYB PODGLĄDU] Nic nie zostanie usunięte`n" -ForegroundColor Yellow
} else {
    Write-Host "[TRYB WYKONANIA] Pliki zostaną usunięte`n" -ForegroundColor Red
}

$targets = @(
    @{ Name = "User Temp"; Path = $env:TEMP },
    @{ Name = "System Temp"; Path = "$env:WINDIR\Temp" },
    @{ Name = "LocalAppData Temp"; Path = "$env:LOCALAPPDATA\Temp" }
)

if ($IncludePrefetch) {
    $targets += @{ Name = "Prefetch"; Path = "$env:WINDIR\Prefetch" }
}

$totalFiles = 0
$totalSize = 0
$totalDeleted = 0
$totalErrors = 0

foreach ($target in $targets) {
    $name = $target.Name
    $path = $target.Path

    Write-Host "--- $name ---" -ForegroundColor Magenta
    Write-Host "    Ścieżka: $path"

    if (-not (Test-Path $path)) {
        Write-Host "    ⚠️ Katalog nie istnieje — pomijam" -ForegroundColor Yellow
        continue
    }

    $files = Get-ChildItem -Path $path -Recurse -File -Force -ErrorAction SilentlyContinue
    $dirFiles = $files.Count
    $dirSize = ($files | Measure-Object -Property Length -Sum).Sum
    $dirSizeMB = [math]::Round($dirSize / 1MB, 2)

    Write-Host "    Plików: $dirFiles | Rozmiar: $dirSizeMB MB" -ForegroundColor White

    $totalFiles += $dirFiles
    $totalSize += $dirSize

    if (-not $WhatIf) {
        $deleted = 0
        $errors = 0
        foreach ($file in $files) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                $deleted++
            } catch {
                $errors++
            }
        }

        # Usuń puste katalogi
        Get-ChildItem -Path $path -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName.Length } -Descending |
            ForEach-Object {
                try { Remove-Item -Path $_.FullName -Force -ErrorAction Stop } catch {}
            }

        $totalDeleted += $deleted
        $totalErrors += $errors
        Write-Host "    ✅ Usunięto: $deleted | Błędów: $errors" -ForegroundColor Green
    }
}

# Podsumowanie
Write-Host "`n=== PODSUMOWANIE ===" -ForegroundColor Cyan
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

if ($WhatIf) {
    Write-Host "Plików do usunięcia: $totalFiles" -ForegroundColor White
    Write-Host "Rozmiar do zwolnienia: $totalSizeMB MB" -ForegroundColor White
    Write-Host "`n💡 Uruchom bez -WhatIf aby usunąć pliki." -ForegroundColor Yellow
} else {
    Write-Host "Plików przeskanowanych: $totalFiles" -ForegroundColor White
    Write-Host "Usunięto: $totalDeleted | Błędów: $totalErrors" -ForegroundColor Green
    Write-Host "Zwolniono: ~$totalSizeMB MB" -ForegroundColor Green
}

Write-Host "`n=== Koniec ===" -ForegroundColor Cyan
