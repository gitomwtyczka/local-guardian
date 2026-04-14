<#
.SYNOPSIS
    Get-SystemSnapshot.ps1 - snapshot stanu systemu
    Workspace: local-guardian
.PARAMETER ExportHTML
    Generuje raport HTML do katalogu reports/
.EXAMPLE
    .\Get-SystemSnapshot.ps1
    .\Get-SystemSnapshot.ps1 -ExportHTML
#>
param(
    [switch]$ExportHTML
)

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

Write-Host '=== Local Guardian - System Snapshot ===' -ForegroundColor Cyan
Write-Host "Czas: $timestamp" -ForegroundColor DarkCyan
Write-Host ''

# --- CPU ---
Write-Host '--- CPU ---' -ForegroundColor Magenta
$cpu = Get-CimInstance Win32_Processor
$cpuName = $cpu.Name
$cpuLoad = $cpu.LoadPercentage
$cpuCores = $cpu.NumberOfCores
$cpuLogical = $cpu.NumberOfLogicalProcessors

Write-Host "  Procesor:   $cpuName" -ForegroundColor White
Write-Host "  Rdzenie:    $cpuCores fizycznych / $cpuLogical logicznych" -ForegroundColor White

$loadColor = 'Green'
if ($cpuLoad -gt 80) { $loadColor = 'Red' }
elseif ($cpuLoad -gt 50) { $loadColor = 'Yellow' }
Write-Host "  Obciazenie: $cpuLoad %" -ForegroundColor $loadColor

# --- RAM ---
Write-Host ''
Write-Host '--- RAM ---' -ForegroundColor Magenta
$os = Get-CimInstance Win32_OperatingSystem
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRAM = [math]::Round($totalRAM - $freeRAM, 2)
$ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)

$ramColor = 'Green'
if ($ramPercent -gt 85) { $ramColor = 'Red' }
elseif ($ramPercent -gt 65) { $ramColor = 'Yellow' }

Write-Host "  Total:   $totalRAM GB" -ForegroundColor White
Write-Host "  Used:    $usedRAM GB" -ForegroundColor White
Write-Host "  Free:    $freeRAM GB" -ForegroundColor White
Write-Host "  Uzycie:  $ramPercent %" -ForegroundColor $ramColor

# --- DYSKI ---
Write-Host ''
Write-Host '--- DYSKI ---' -ForegroundColor Magenta
$disks = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3'

$diskData = foreach ($disk in $disks) {
    $totalGB = [math]::Round($disk.Size / 1GB, 2)
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $usedGB = [math]::Round($totalGB - $freeGB, 2)
    $pct = 0
    if ($totalGB -gt 0) { $pct = [math]::Round(($usedGB / $totalGB) * 100, 1) }

    [PSCustomObject]@{
        Drive   = $disk.DeviceID
        Total   = "$totalGB GB"
        Used    = "$usedGB GB"
        Free    = "$freeGB GB"
        Percent = "$pct %"
    }
}

$diskData | Format-Table -AutoSize

foreach ($d in $diskData) {
    $pctVal = [double]($d.Percent -replace ' %', '')
    $diskColor = 'Green'
    if ($pctVal -gt 90) { $diskColor = 'Red' }
    elseif ($pctVal -gt 75) { $diskColor = 'Yellow' }
    Write-Host "  $($d.Drive) - $($d.Percent) uzycia" -ForegroundColor $diskColor
}

# --- TOP PROCESY ---
Write-Host ''
Write-Host '--- TOP 5 PROCESOW (RAM) ---' -ForegroundColor Magenta
$topProcs = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 |
    Select-Object @{N='Nazwa';E={$_.ProcessName}},
                  @{N='PID';E={$_.Id}},
                  @{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB,1)}},
                  @{N='CPU_s';E={[math]::Round($_.CPU,1)}}

$topProcs | Format-Table -AutoSize

# --- UPTIME ---
Write-Host '--- UPTIME ---' -ForegroundColor Magenta
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $bootTime
$bootStr = $bootTime.ToString('yyyy-MM-dd HH:mm:ss')
Write-Host "  Ostatni restart: $bootStr" -ForegroundColor White
Write-Host "  Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor White

# --- EKSPORT HTML ---
if ($ExportHTML) {
    $reportDir = Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) 'reports'
    if (-not (Test-Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }

    $dateSlug = Get-Date -Format 'yyyyMMdd-HHmm'
    $htmlPath = Join-Path $reportDir "system-snapshot-$dateSlug.html"

    # Build HTML as array of lines
    $lines = @()
    $lines += '<!DOCTYPE html>'
    $lines += '<html><head><meta charset="utf-8">'
    $lines += "<title>System Snapshot - $timestamp</title>"
    $lines += '<style>'
    $lines += 'body{font-family:Segoe UI,sans-serif;background:#1a1a2e;color:#e0e0e0;padding:20px}'
    $lines += 'h1{color:#00d4ff}h2{color:#ff6b9d;border-bottom:1px solid #333;padding-bottom:5px}'
    $lines += 'table{border-collapse:collapse;width:100%;margin:10px 0}'
    $lines += 'th,td{padding:8px 12px;text-align:left;border:1px solid #333}'
    $lines += 'th{background:#16213e;color:#00d4ff}tr:nth-child(even){background:#0f3460}'
    $lines += '.ok{color:#4ade80}.warn{color:#fbbf24}.crit{color:#f87171}'
    $lines += '</style></head><body>'
    $lines += "<h1>Local Guardian - System Snapshot</h1><p>$timestamp</p>"

    $cpuClass = 'ok'
    if ($cpuLoad -gt 80) { $cpuClass = 'crit' }
    elseif ($cpuLoad -gt 50) { $cpuClass = 'warn' }
    $lines += "<h2>CPU</h2><p>$cpuName | Cores: $cpuCores/$cpuLogical | Load: <span class=`"$cpuClass`">$cpuLoad%</span></p>"

    $ramClass = 'ok'
    if ($ramPercent -gt 85) { $ramClass = 'crit' }
    elseif ($ramPercent -gt 65) { $ramClass = 'warn' }
    $lines += "<h2>RAM</h2><p>Total: ${totalRAM}GB | Used: ${usedRAM}GB | Free: ${freeRAM}GB | <span class=`"$ramClass`">$ramPercent%</span></p>"

    $lines += '<h2>Dyski</h2><table><tr><th>Dysk</th><th>Total</th><th>Used</th><th>Free</th><th>%</th></tr>'
    foreach ($dd in $diskData) {
        $lines += "<tr><td>$($dd.Drive)</td><td>$($dd.Total)</td><td>$($dd.Used)</td><td>$($dd.Free)</td><td>$($dd.Percent)</td></tr>"
    }
    $lines += '</table>'

    $lines += '<h2>Top 5 Procesow</h2><table><tr><th>Nazwa</th><th>PID</th><th>RAM MB</th><th>CPU s</th></tr>'
    foreach ($pp in $topProcs) {
        $lines += "<tr><td>$($pp.Nazwa)</td><td>$($pp.PID)</td><td>$($pp.RAM_MB)</td><td>$($pp.CPU_s)</td></tr>"
    }
    $lines += '</table>'

    $uptimeStr = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
    $lines += "<h2>Uptime</h2><p>Boot: $bootStr | Uptime: $uptimeStr</p>"
    $lines += '</body></html>'

    $lines -join "`n" | Out-File -FilePath $htmlPath -Encoding UTF8
    Write-Host "Raport HTML: $htmlPath" -ForegroundColor Cyan
}

Write-Host ''
Write-Host '=== Koniec snapshotu ===' -ForegroundColor Cyan
