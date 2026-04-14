<#
.SYNOPSIS
    Get-SystemSnapshot.ps1 — snapshot stanu systemu (CPU, RAM, dyski, top procesy)
    Workspace: local-guardian
    Author: [local-worker 01] | 14.04.2026

.DESCRIPTION
    Zbiera migawkę stanu systemu:
    - CPU: nazwa procesora, aktualne obciążenie %
    - RAM: total, used, free, % użycia
    - Dyski: partycje z total/free/% użycia
    - Top 5 procesów po zużyciu pamięci
    Opcjonalnie eksportuje raport HTML.

.PARAMETER ExportHTML
    Generuje raport HTML do katalogu reports/

.EXAMPLE
    .\Get-SystemSnapshot.ps1
    .\Get-SystemSnapshot.ps1 -ExportHTML
#>

param(
    [switch]$ExportHTML
)

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "=== Local Guardian — System Snapshot ===" -ForegroundColor Cyan
Write-Host "Czas: $timestamp`n" -ForegroundColor DarkCyan

# --- CPU ---
Write-Host "--- CPU ---" -ForegroundColor Magenta
$cpu = Get-CimInstance Win32_Processor
$cpuName = $cpu.Name
$cpuLoad = $cpu.LoadPercentage
$cpuCores = $cpu.NumberOfCores
$cpuLogical = $cpu.NumberOfLogicalProcessors

Write-Host "  Procesor:   $cpuName" -ForegroundColor White
Write-Host "  Rdzenie:    $cpuCores fizycznych / $cpuLogical logicznych" -ForegroundColor White

$loadColor = if ($cpuLoad -gt 80) { "Red" } elseif ($cpuLoad -gt 50) { "Yellow" } else { "Green" }
Write-Host "  Obciążenie: $cpuLoad %" -ForegroundColor $loadColor

# --- RAM ---
Write-Host "`n--- RAM ---" -ForegroundColor Magenta
$os = Get-CimInstance Win32_OperatingSystem
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRAM = [math]::Round($totalRAM - $freeRAM, 2)
$ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)

$ramColor = if ($ramPercent -gt 85) { "Red" } elseif ($ramPercent -gt 65) { "Yellow" } else { "Green" }

Write-Host "  Total:   $totalRAM GB" -ForegroundColor White
Write-Host "  Used:    $usedRAM GB" -ForegroundColor White
Write-Host "  Free:    $freeRAM GB" -ForegroundColor White
Write-Host "  Użycie:  $ramPercent %" -ForegroundColor $ramColor

# --- DYSKI ---
Write-Host "`n--- DYSKI ---" -ForegroundColor Magenta
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

$diskData = foreach ($disk in $disks) {
    $totalGB = [math]::Round($disk.Size / 1GB, 2)
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $usedGB = [math]::Round($totalGB - $freeGB, 2)
    $percent = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 1) } else { 0 }

    [PSCustomObject]@{
        Drive   = $disk.DeviceID
        Total   = "$totalGB GB"
        Used    = "$usedGB GB"
        Free    = "$freeGB GB"
        Percent = "$percent %"
    }
}

$diskData | Format-Table -AutoSize

foreach ($d in $diskData) {
    $pct = [double]($d.Percent -replace ' %', '')
    $diskColor = if ($pct -gt 90) { "Red" } elseif ($pct -gt 75) { "Yellow" } else { "Green" }
    Write-Host "  $($d.Drive) → $($d.Percent) użycia" -ForegroundColor $diskColor
}

# --- TOP PROCESY ---
Write-Host "`n--- TOP 5 PROCESÓW (RAM) ---" -ForegroundColor Magenta
$topProcs = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 |
    Select-Object @{N='Nazwa';E={$_.ProcessName}},
                  @{N='PID';E={$_.Id}},
                  @{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB,1)}},
                  @{N='CPU_s';E={[math]::Round($_.CPU,1)}}

$topProcs | Format-Table -AutoSize

# --- UPTIME ---
Write-Host "--- UPTIME ---" -ForegroundColor Magenta
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $bootTime
Write-Host "  Ostatni restart: $($bootTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "  Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor White

# --- EKSPORT HTML ---
if ($ExportHTML) {
    $reportDir = Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) "reports"
    if (-not (Test-Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }

    $htmlPath = Join-Path $reportDir "system-snapshot-$(Get-Date -Format 'yyyyMMdd-HHmm').html"

    $html = @"
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>System Snapshot — $timestamp</title>
<style>body{font-family:'Segoe UI',sans-serif;background:#1a1a2e;color:#e0e0e0;padding:20px}
h1{color:#00d4ff}h2{color:#ff6b9d;border-bottom:1px solid #333;padding-bottom:5px}
table{border-collapse:collapse;width:100%;margin:10px 0}th,td{padding:8px 12px;text-align:left;border:1px solid #333}
th{background:#16213e;color:#00d4ff}tr:nth-child(even){background:#0f3460}
.ok{color:#4ade80}.warn{color:#fbbf24}.crit{color:#f87171}
.header{background:linear-gradient(135deg,#0f3460,#16213e);padding:20px;border-radius:8px;margin-bottom:20px}
</style></head><body>
<div class="header"><h1>🛡️ Local Guardian — System Snapshot</h1><p>$timestamp</p></div>
<h2>CPU</h2><p>$cpuName | Cores: $cpuCores/$cpuLogical | Load: <span class="$(if($cpuLoad -gt 80){'crit'}elseif($cpuLoad -gt 50){'warn'}else{'ok'})">$cpuLoad%</span></p>
<h2>RAM</h2><p>Total: ${totalRAM}GB | Used: ${usedRAM}GB | Free: ${freeRAM}GB | <span class="$(if($ramPercent -gt 85){'crit'}elseif($ramPercent -gt 65){'warn'}else{'ok'})">$ramPercent%</span></p>
<h2>Dyski</h2><table><tr><th>Dysk</th><th>Total</th><th>Used</th><th>Free</th><th>%</th></tr>
$($diskData | ForEach-Object { "<tr><td>$($_.Drive)</td><td>$($_.Total)</td><td>$($_.Used)</td><td>$($_.Free)</td><td>$($_.Percent)</td></tr>" })
</table>
<h2>Top 5 Procesów (RAM)</h2><table><tr><th>Nazwa</th><th>PID</th><th>RAM MB</th><th>CPU s</th></tr>
$($topProcs | ForEach-Object { "<tr><td>$($_.Nazwa)</td><td>$($_.PID)</td><td>$($_.RAM_MB)</td><td>$($_.CPU_s)</td></tr>" })
</table>
<h2>Uptime</h2><p>Boot: $($bootTime.ToString('yyyy-MM-dd HH:mm:ss')) | Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m</p>
</body></html>
"@

    $html | Out-File -FilePath $htmlPath -Encoding UTF8
    Write-Host "`n📄 Raport HTML: $htmlPath" -ForegroundColor Cyan
}

Write-Host "`n=== Koniec snapshotu ===" -ForegroundColor Cyan
