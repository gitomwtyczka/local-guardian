<#
.SYNOPSIS
    Get-EventErrors.ps1 — zbiera błędy Critical i Error z Event Log
    Workspace: local-guardian
    Author: [local-worker 01] | 14.04.2026

.DESCRIPTION
    Skanuje logi System i Application w poszukiwaniu zdarzeń
    o poziomie Critical (1) i Error (2). Wyróżnia kategorie:
    - Kernel-Power (nieoczekiwane restarty, BSOD)
    - Disk errors (ntfs, disk, volmgr)
    - Driver crashes (display, ndis, ks)

.PARAMETER LastHours
    Liczba godzin wstecz (domyślnie 24)

.PARAMETER ExportCSV
    Eksportuje wyniki do pliku CSV w reports/

.EXAMPLE
    .\Get-EventErrors.ps1
    .\Get-EventErrors.ps1 -LastHours 72 -ExportCSV
#>

param(
    [int]$LastHours = 24,
    [switch]$ExportCSV
)

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$since = (Get-Date).AddHours(-$LastHours)

Write-Host "=== Local Guardian — Event Log Errors ===" -ForegroundColor Cyan
Write-Host "Okres: ostatnie $LastHours godzin (od $($since.ToString('yyyy-MM-dd HH:mm')))" -ForegroundColor DarkCyan
Write-Host "Czas raportu: $timestamp`n"

# Zbierz eventy z System i Application
$logs = @('System', 'Application')
$allEvents = @()

foreach ($log in $logs) {
    Write-Host "Skanowanie: $log..." -ForegroundColor DarkGray
    $events = Get-WinEvent -LogName $log -ErrorAction SilentlyContinue |
        Where-Object {
            $_.TimeCreated -gt $since -and
            $_.Level -le 2  # 1=Critical, 2=Error
        } |
        Select-Object @{N='Time';E={$_.TimeCreated}},
                      @{N='Level';E={switch($_.Level){1{'CRITICAL'}2{'ERROR'}default{$_.Level}}}},
                      @{N='Source';E={$_.ProviderName}},
                      @{N='EventID';E={$_.Id}},
                      @{N='LogName';E={$log}},
                      @{N='Message';E={
                          if ($_.Message) {
                              $_.Message.Substring(0, [Math]::Min(150, $_.Message.Length))
                          } else { "(brak)" }
                      }},
                      @{N='Category';E={
                          $src = $_.ProviderName.ToLower()
                          if ($src -match 'kernel-power|bugcheck') { 'KERNEL/BSOD' }
                          elseif ($src -match 'ntfs|disk|volmgr|storahci') { 'DISK' }
                          elseif ($src -match 'display|ndis|ks\.|wudf') { 'DRIVER' }
                          elseif ($src -match 'application error|.net runtime|faulting') { 'APP_CRASH' }
                          elseif ($src -match 'service control|scm') { 'SERVICE' }
                          else { 'OTHER' }
                      }}

    $allEvents += $events
}

$allEvents = $allEvents | Sort-Object Time -Descending

# Podsumowanie
$critical = ($allEvents | Where-Object { $_.Level -eq 'CRITICAL' }).Count
$errors = ($allEvents | Where-Object { $_.Level -eq 'ERROR' }).Count
$total = $allEvents.Count

Write-Host "`n=== PODSUMOWANIE ===" -ForegroundColor Cyan

if ($total -eq 0) {
    Write-Host "✅ Brak błędów Critical/Error w ciągu ostatnich $LastHours godzin!" -ForegroundColor Green
} else {
    if ($critical -gt 0) {
        Write-Host "🔴 CRITICAL: $critical" -ForegroundColor Red
    }
    Write-Host "🟠 ERROR:    $errors" -ForegroundColor Yellow
    Write-Host "   Łącznie:  $total zdarzeń`n" -ForegroundColor White

    # Grupowanie po kategorii
    Write-Host "--- Kategorie ---" -ForegroundColor Magenta
    $allEvents | Group-Object Category | Sort-Object Count -Descending | ForEach-Object {
        $catColor = switch ($_.Name) {
            'KERNEL/BSOD' { 'Red' }
            'DISK'        { 'Red' }
            'DRIVER'      { 'Yellow' }
            'APP_CRASH'   { 'Yellow' }
            'SERVICE'     { 'DarkYellow' }
            default       { 'White' }
        }
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor $catColor
    }

    # Najczęstsze źródła
    Write-Host "`n--- Top 5 źródeł ---" -ForegroundColor Magenta
    $allEvents | Group-Object Source | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count) zdarzeń" -ForegroundColor White
    }

    # Tabela zdarzeń
    Write-Host "`n--- Zdarzenia ---" -ForegroundColor Magenta
    $allEvents | Select-Object -First 30 | ForEach-Object {
        $lvlColor = if ($_.Level -eq 'CRITICAL') { 'Red' } else { 'Yellow' }
        $msgPreview = if ($_.Message.Length -gt 80) { $_.Message.Substring(0,80) + "..." } else { $_.Message }
        Write-Host "[$($_.Time.ToString('yyyy-MM-dd HH:mm:ss'))] " -NoNewline -ForegroundColor DarkGray
        Write-Host "[$($_.Level)] " -NoNewline -ForegroundColor $lvlColor
        Write-Host "[$($_.Category)] " -NoNewline -ForegroundColor Magenta
        Write-Host "$($_.Source) (ID:$($_.EventID)) — $msgPreview" -ForegroundColor White
    }

    if ($total -gt 30) {
        Write-Host "`n  ... i $($total - 30) więcej zdarzeń" -ForegroundColor DarkGray
    }

    # Alerty specjalne
    $bsod = $allEvents | Where-Object { $_.Category -eq 'KERNEL/BSOD' }
    if ($bsod) {
        Write-Host "`n🔴 UWAGA: Wykryto $($bsod.Count) zdarzenie/a Kernel-Power/BSOD!" -ForegroundColor Red
        Write-Host "   Sugestia: Sprawdź logi minidump w C:\Windows\Minidump" -ForegroundColor Red
    }

    $diskErr = $allEvents | Where-Object { $_.Category -eq 'DISK' }
    if ($diskErr) {
        Write-Host "`n🔴 UWAGA: Wykryto $($diskErr.Count) błąd/ów dyskowych!" -ForegroundColor Red
        Write-Host "   Sugestia: Uruchom chkdsk /f na dotkniętych dyskach" -ForegroundColor Red
    }
}

# Eksport CSV
if ($ExportCSV) {
    $reportDir = Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) "reports"
    if (-not (Test-Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }

    $csvPath = Join-Path $reportDir "event-errors-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
    $allEvents | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`n📄 Wyeksportowano: $csvPath" -ForegroundColor Cyan
}

Write-Host "`n=== Koniec raportu ===" -ForegroundColor Cyan
