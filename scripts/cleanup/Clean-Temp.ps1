<#
.SYNOPSIS
    Clean-Temp.ps1 - czysci pliki tymczasowe Windows
    Workspace: local-guardian
.PARAMETER WhatIf
    Raportuje co zostaloby usuniete, ale nic nie usuwa.
.PARAMETER IncludePrefetch
    Dolacza katalog Prefetch (wymaga uprawnien administratora).
.EXAMPLE
    .\Clean-Temp.ps1 -WhatIf
    .\Clean-Temp.ps1
#>
param(
    [switch]$WhatIf,
    [switch]$IncludePrefetch
)

Write-Host '=== Local Guardian - Temp Cleaner ===' -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host '[TRYB PODGLADU] Nic nie zostanie usuniete' -ForegroundColor Yellow
}
else {
    Write-Host '[TRYB WYKONANIA] Pliki zostana usuniete' -ForegroundColor Red
}

$targets = @(
    @{ Name = 'User Temp'; Path = $env:TEMP },
    @{ Name = 'System Temp'; Path = Join-Path $env:WINDIR 'Temp' },
    @{ Name = 'LocalAppData Temp'; Path = Join-Path $env:LOCALAPPDATA 'Temp' }
)

if ($IncludePrefetch) {
    $targets += @{ Name = 'Prefetch'; Path = Join-Path $env:WINDIR 'Prefetch' }
}

$totalFiles = 0
$totalSize = 0
$totalDeleted = 0
$totalErrors = 0

foreach ($target in $targets) {
    $name = $target.Name
    $tpath = $target.Path

    Write-Host "--- $name ---" -ForegroundColor Magenta
    Write-Host "    Path: $tpath"

    if (-not (Test-Path $tpath)) {
        Write-Host '    [!] Katalog nie istnieje - pomijam' -ForegroundColor Yellow
        continue
    }

    $files = Get-ChildItem -Path $tpath -Recurse -File -Force -ErrorAction SilentlyContinue
    $dirFiles = @($files).Count
    $dirSize = ($files | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if (-not $dirSize) { $dirSize = 0 }
    $dirSizeMB = [math]::Round($dirSize / 1MB, 2)

    Write-Host "    Plikow: $dirFiles | Rozmiar: $dirSizeMB MB" -ForegroundColor White

    $totalFiles += $dirFiles
    $totalSize += $dirSize

    if (-not $WhatIf) {
        $deleted = 0
        $errors = 0
        foreach ($file in $files) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                $deleted++
            }
            catch {
                $errors++
            }
        }

        # Usun puste katalogi
        Get-ChildItem -Path $tpath -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName.Length } -Descending |
            ForEach-Object {
                try { Remove-Item -Path $_.FullName -Force -ErrorAction Stop } catch { }
            }

        $totalDeleted += $deleted
        $totalErrors += $errors
        Write-Host "    [OK] Usunieto: $deleted | Bledow: $errors" -ForegroundColor Green
    }
}

# Podsumowanie
Write-Host ''
Write-Host '=== PODSUMOWANIE ===' -ForegroundColor Cyan
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

if ($WhatIf) {
    Write-Host "Plikow do usuniecia: $totalFiles" -ForegroundColor White
    Write-Host "Rozmiar do zwolnienia: $totalSizeMB MB" -ForegroundColor White
    Write-Host 'Uruchom bez -WhatIf aby usunac pliki.' -ForegroundColor Yellow
}
else {
    Write-Host "Plikow przeskanowanych: $totalFiles" -ForegroundColor White
    Write-Host "Usunieto: $totalDeleted | Bledow: $totalErrors" -ForegroundColor Green
    Write-Host "Zwolniono: ~$totalSizeMB MB" -ForegroundColor Green
}

Write-Host '=== Koniec ===' -ForegroundColor Cyan
