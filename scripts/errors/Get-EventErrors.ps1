<#
.SYNOPSIS
    Get-EventErrors.ps1 - zbiera bledy Critical i Error z Event Log
    Workspace: local-guardian
.PARAMETER LastHours
    Liczba godzin wstecz (domyslnie 24)
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

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$since = (Get-Date).AddHours(-$LastHours)
$sinceStr = $since.ToString('yyyy-MM-dd HH:mm')

Write-Host '=== Local Guardian - Event Log Errors ===' -ForegroundColor Cyan
Write-Host "Okres: ostatnie $LastHours godzin, od: $sinceStr" -ForegroundColor DarkCyan
Write-Host "Czas raportu: $timestamp"
Write-Host ''

# Zbierz eventy z System i Application
$logs = @('System', 'Application')
$allEvents = @()

foreach ($log in $logs) {
    Write-Host "Skanowanie: $log..." -ForegroundColor DarkGray
    $events = Get-WinEvent -LogName $log -MaxEvents 500 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.TimeCreated -gt $since -and $_.Level -le 2
        }

    foreach ($ev in $events) {
        $src = $ev.ProviderName.ToLower()
        $cat = 'OTHER'
        if ($src -match 'kernel-power|bugcheck') { $cat = 'KERNEL/BSOD' }
        elseif ($src -match 'ntfs|disk|volmgr|storahci') { $cat = 'DISK' }
        elseif ($src -match 'display|ndis|wudf') { $cat = 'DRIVER' }
        elseif ($src -match 'application error|faulting') { $cat = 'APP_CRASH' }
        elseif ($src -match 'service control|scm') { $cat = 'SERVICE' }

        $lvl = 'ERROR'
        if ($ev.Level -eq 1) { $lvl = 'CRITICAL' }

        $msg = '(brak)'
        if ($ev.Message) {
            $maxLen = [Math]::Min(150, $ev.Message.Length)
            $msg = $ev.Message.Substring(0, $maxLen)
        }

        $allEvents += [PSCustomObject]@{
            Time     = $ev.TimeCreated
            Level    = $lvl
            Source   = $ev.ProviderName
            EventID  = $ev.Id
            LogName  = $log
            Message  = $msg
            Category = $cat
        }
    }
}

$allEvents = $allEvents | Sort-Object Time -Descending

# Podsumowanie
$critical = @($allEvents | Where-Object { $_.Level -eq 'CRITICAL' }).Count
$errors = @($allEvents | Where-Object { $_.Level -eq 'ERROR' }).Count
$total = $allEvents.Count

Write-Host ''
Write-Host '=== PODSUMOWANIE ===' -ForegroundColor Cyan

if ($total -eq 0) {
    Write-Host "[OK] Brak bledow Critical/Error w ciagu ostatnich $LastHours godzin!" -ForegroundColor Green
}
else {
    if ($critical -gt 0) {
        Write-Host "[!!!] CRITICAL: $critical" -ForegroundColor Red
    }
    Write-Host "[!] ERROR: $errors" -ForegroundColor Yellow
    Write-Host "    Lacznie: $total zdarzen" -ForegroundColor White

    # Grupowanie po kategorii
    Write-Host ''
    Write-Host '--- Kategorie ---' -ForegroundColor Magenta
    $allEvents | Group-Object Category | Sort-Object Count -Descending | ForEach-Object {
        $catColor = 'White'
        if ($_.Name -eq 'KERNEL/BSOD' -or $_.Name -eq 'DISK') { $catColor = 'Red' }
        elseif ($_.Name -eq 'DRIVER' -or $_.Name -eq 'APP_CRASH') { $catColor = 'Yellow' }
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor $catColor
    }

    # Najczestsze zrodla
    Write-Host ''
    Write-Host '--- Top 5 zrodel ---' -ForegroundColor Magenta
    $allEvents | Group-Object Source | Sort-Object Count -Descending |
        Select-Object -First 5 | ForEach-Object {
            Write-Host "  $($_.Name): $($_.Count) zdarzen" -ForegroundColor White
        }

    # Tabela zdarzen
    Write-Host ''
    Write-Host '--- Zdarzenia ---' -ForegroundColor Magenta
    $shown = $allEvents | Select-Object -First 30
    foreach ($item in $shown) {
        $lvlColor = 'Yellow'
        if ($item.Level -eq 'CRITICAL') { $lvlColor = 'Red' }
        $preview = $item.Message
        if ($preview.Length -gt 80) { $preview = $preview.Substring(0, 80) + '...' }
        $timeStr = $item.Time.ToString('yyyy-MM-dd HH:mm:ss')
        Write-Host "[$timeStr] " -NoNewline -ForegroundColor DarkGray
        Write-Host "[$($item.Level)] " -NoNewline -ForegroundColor $lvlColor
        Write-Host "[$($item.Category)] " -NoNewline -ForegroundColor Magenta
        Write-Host "$($item.Source) ID:$($item.EventID) - $preview" -ForegroundColor White
    }

    if ($total -gt 30) {
        Write-Host "  ... i $($total - 30) wiecej zdarzen" -ForegroundColor DarkGray
    }

    # Alerty specjalne
    $bsod = @($allEvents | Where-Object { $_.Category -eq 'KERNEL/BSOD' })
    if ($bsod.Count -gt 0) {
        Write-Host ''
        Write-Host "[!!!] UWAGA: Wykryto $($bsod.Count) zdarzenie/a Kernel-Power/BSOD!" -ForegroundColor Red
        Write-Host '   Sugestia: Sprawdz logi minidump w C:\Windows\Minidump' -ForegroundColor Red
    }

    $diskErr = @($allEvents | Where-Object { $_.Category -eq 'DISK' })
    if ($diskErr.Count -gt 0) {
        Write-Host ''
        Write-Host "[!!!] UWAGA: Wykryto $($diskErr.Count) blad(ow) dyskowych!" -ForegroundColor Red
        Write-Host '   Sugestia: Uruchom chkdsk /f na dotknietych dyskach' -ForegroundColor Red
    }
}

# Eksport CSV
if ($ExportCSV) {
    $reportDir = Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) 'reports'
    if (-not (Test-Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }

    $csvSlug = Get-Date -Format 'yyyyMMdd-HHmm'
    $csvPath = Join-Path $reportDir "event-errors-$csvSlug.csv"
    $allEvents | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Wyeksportowano: $csvPath" -ForegroundColor Cyan
}

Write-Host ''
Write-Host '=== Koniec raportu ===' -ForegroundColor Cyan
