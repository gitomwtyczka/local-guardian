<#
.SYNOPSIS
    Watch-BluetoothEvents.ps1 — monitoruje rozłączenia Bluetooth w Event Log
    Workspace: local-guardian
    Author: [local-worker 01] | local-guardian | 14.04.2026

.DESCRIPTION
    Skanuje Event Log w poszukiwaniu zdarzeń Bluetooth (rozłączenia, błędy HID,
    konflikty adapterów). Obsługuje eksport CSV i personalizację okresu czasu.

.PARAMETER LastHours
    Liczba godzin wstecz do przeszukania (domyślnie: 24)

.PARAMETER ExportCSV
    Jeśli podany, eksportuje wyniki do pliku CSV w katalogu reports/

.EXAMPLE
    .\Watch-BluetoothEvents.ps1
    .\Watch-BluetoothEvents.ps1 -LastHours 48 -ExportCSV
#>

param(
    [int]$LastHours = 24,
    [switch]$ExportCSV
)

Write-Host "=== Bluetooth Event Monitor ===" -ForegroundColor Cyan
Write-Host "Workspace: local-guardian | [local-worker 01]" -ForegroundColor DarkCyan
Write-Host "Okres: ostatnie $LastHours godzin`n"

$since = (Get-Date).AddHours(-$LastHours)

# Logi Bluetooth specyficzne
$btLogs = @(
    'Microsoft-Windows-Bluetooth-MTPEnum/Operational',
    'Microsoft-Windows-BluetoothAdapter/Operational'
)

$events = @()
foreach ($log in $btLogs) {
    $r = Get-WinEvent -LogName $log -ErrorAction SilentlyContinue |
        Where-Object { $_.TimeCreated -gt $since } |
        Select-Object TimeCreated, Id, LevelDisplayName, Message, @{N='LogName';E={$log}}
    if ($r) { $events += $r }
}

# System log — BT/HID errors i konflikty adapterów
$sysEvents = Get-WinEvent -LogName System -ErrorAction SilentlyContinue |
    Where-Object {
        $_.TimeCreated -gt $since -and
        $_.Level -le 3 -and
        ($_.Message -match 'Bluetooth|HID|wireless adapter|dongle')
    } |
    Select-Object TimeCreated, Id, LevelDisplayName, Message, @{N='LogName';E={'System'}}

$all = @($events) + @($sysEvents) | Sort-Object TimeCreated -Descending

# Podsumowanie statusu adaptera
Write-Host "--- Stan adaptera BT ---" -ForegroundColor Magenta
Get-PnpDevice |
    Where-Object { $_.FriendlyName -match 'Generic Bluetooth Radio|Bluetooth Radio' -and $_.Status -eq 'OK' } |
    Select-Object FriendlyName, Status, DeviceID |
    Format-Table -AutoSize

Write-Host "--- Konflikty adapterów (Status=Unknown) ---" -ForegroundColor Yellow
$ghostCount = (Get-PnpDevice | Where-Object {
    $_.FriendlyName -match 'Generic Bluetooth Radio' -and $_.Status -eq 'Unknown'
}).Count
Write-Host "Ghost adapters (Unknown): $ghostCount`n"

if ($all.Count -eq 0) {
    Write-Host "✅ Brak zdarzeń Bluetooth w ciągu ostatnich $LastHours godzin." -ForegroundColor Green
} else {
    Write-Host "⚠️ Znaleziono $($all.Count) zdarzeń:" -ForegroundColor Yellow
    $all | Format-Table TimeCreated, Id, LevelDisplayName, LogName -AutoSize
    Write-Host "`n--- Szczegóły ---" -ForegroundColor DarkYellow
    $all | ForEach-Object {
        $msgPreview = if ($_.Message) { $_.Message.Substring(0, [Math]::Min(120, $_.Message.Length)) } else { "(brak)" }
        Write-Host "[$($_.TimeCreated)] ID:$($_.Id) [$($_.LevelDisplayName)] - $msgPreview"
    }

    # Wykryj Event ID 6 — konflikt adaptorów
    $conflicts = $all | Where-Object { $_.Id -eq 6 -and $_.LogName -eq 'System' }
    if ($conflicts) {
        Write-Host "`n🔴 UWAGA: Wykryto $($conflicts.Count) konflikt(y) adapterów Bluetooth (Event ID 6)!" -ForegroundColor Red
        Write-Host "   Sugestia: Czyść duplikaty adapterów przez devmgmt.msc → Pokaż ukryte urządzenia"
    }
}

if ($ExportCSV) {
    $reportDir = Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) "reports"
    if (-not (Test-Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }

    $path = Join-Path $reportDir "bt-events-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
    $all | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
    Write-Host "`n📄 Wyeksportowano: $path" -ForegroundColor Cyan
}

Write-Host "`n=== Koniec raportu ===" -ForegroundColor Cyan
