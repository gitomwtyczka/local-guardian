# DISPATCH — [local-worker 01] Bluetooth Logitech Disconnect Fix

## ⚡ KROK 0 — ZANIM cokolwiek zrobisz

**0. Wczytaj blok systemowy:**
`view_file → C:\Users\tomas2\.gemini\antigravity\playground\sonic-void\.agents\protocols\dispatch-system-block.md`

---

## Tożsamość agenta

- **Callsign:** `[local-worker 01]`
- **Workspace:** `local-guardian`
- **Model:** Claude Sonnet (myślenie włączone)
- **Deliverable:** Działająca diagnoza + fix + skrypt monitorujący + raport do Supervisora

---

## Heartbeat (PIERWSZY krok)

```json
// write_to_file → C:\Users\tomas2\.gemini\antigravity\playground\local-guardian\.agents\heartbeat.json
{
  "callsign": "[local-worker 01]",
  "status": "working",
  "current_task": "Bluetooth Logitech disconnect diagnosis and fix",
  "timestamp": "<ISO teraz>"
}
```

---

## Opis problemu

Mysz i klawiatura **Logitech** podłączone przez Bluetooth (dongle USB) do komputera (Windows) odłączają się losowo — brak kontaktu z urządzeniami mimo widocznej niebieskiej diody na dongle (dongle nadal nadaje).

**Objawy:**
- Urządzenia przestają odpowiadać (klawiatura/mysz nie reagują)
- Dongle bluetooth nadal świeci błękitną migającą diodą — działa elektrycznie
- Przełączenie tych samych urządzeń na TV (BT) → działają poprawnie → HW OK
- **Fix tymczasowy:** odłączenie dongla i ponowne podłączenie → urządzenia wracają

**Hipoteza robocza:** Problem w Windows Bluetooth stack — prawdopodobnie USB selective suspend / power management wyłącza dongle na poziomie sterownika mimo aktywnej diody, lub reset adaptera bez ponownej inicjalizacji połączeń.

---

## Twoje zadania

### ETAP 1 — Diagnostyka (pobierz dane, nie zmieniaj nic)

**1a. Event Log — historia rozłączeń Bluetooth:**

Krok 1 — wyślij przez FILE BRIDGE:
```json
// req-local-worker-01.json
{
  "id": "local-worker-01",
  "agent": "local-worker 01",
  "tool": "execute_command",
  "args": {
    "target": "local-pc",
    "command": "powershell -Command \"Get-WinEvent -LogName 'Microsoft-Windows-Bluetooth-MTPEnum/Operational' -MaxEvents 50 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, Message | Out-String\"",
    "timeout": 25
  }
}
```

**1b. Logi Kernel-Power i General Bluetooth:**
```json
// req-local-worker-02.json
{
  "id": "local-worker-02",
  "agent": "local-worker 01",
  "tool": "execute_command",
  "args": {
    "target": "local-pc",
    "command": "powershell -Command \"$logs = @('System','Application'); foreach($log in $logs){ Get-WinEvent -LogName $log -MaxEvents 200 -ErrorAction SilentlyContinue | Where-Object { $_.Message -match 'Bluetooth|HID|wireless' -and $_.Level -le 3 } | Select-Object TimeCreated, Id, LogName, Message } | Sort-Object TimeCreated -Descending | Select-Object -First 30 | Out-String\"",
    "timeout": 30
  }
}
```

**1c. Status power management dongla USB:**
```json
// req-local-worker-03.json
{
  "id": "local-worker-03",
  "agent": "local-worker 01",
  "tool": "execute_command",
  "args": {
    "target": "local-pc",
    "command": "powershell -Command \"Get-PnpDevice | Where-Object { $_.FriendlyName -match 'Bluetooth|Logitech' } | Select-Object FriendlyName, Status, DeviceID | Out-String\"",
    "timeout": 20
  }
}
```

**1d. USB selective suspend — stan:**
```json
// req-local-worker-04.json
{
  "id": "local-worker-04",
  "agent": "local-worker 01",
  "tool": "execute_command",
  "args": {
    "target": "local-pc",
    "command": "powershell -Command \"powercfg /query SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 2>$null; powercfg /devicequery wake_armed | Out-String\"",
    "timeout": 20
  }
}
```

---

### ETAP 2 — Fix (po analizie danych z ETAP 1)

Na podstawie zebranych danych zastosuj **JEDEN lub WIĘCEJ** z poniższych fix'ów:

**FIX A — Wyłącz USB selective suspend dla adaptera Bluetooth:**
```json
// req-local-worker-05.json — tylko jeśli ETAP 1 potwierdzi problem z power mgmt
{
  "id": "local-worker-05",
  "agent": "local-worker 01",
  "tool": "execute_command",
  "args": {
    "target": "local-pc",
    "command": "powershell -Command \"$btAdapter = Get-PnpDevice | Where-Object { $_.FriendlyName -match 'Bluetooth' -and $_.Status -eq 'OK' } | Select-Object -First 1; if($btAdapter){ $regPath = \"HKLM:\\SYSTEM\\CurrentControlSet\\Enum\\\" + $btAdapter.DeviceID + \"\\Device Parameters\\WDF\"; New-Item -Path $regPath -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $regPath -Name 'IdleInWorkingState' -Value 0 -Type DWord -Force; 'Done: USB selective suspend disabled for BT adapter' } else { 'Bluetooth adapter not found' }\"",
    "timeout": 20
  }
}
```

**FIX B — Wyłącz power management przez devmgmt (Device Manager registry):**
```json
// req-local-worker-06.json — alternatywna droga przez global power settings
{
  "id": "local-worker-06",
  "agent": "local-worker 01",
  "tool": "execute_command",
  "args": {
    "target": "local-pc",
    "command": "powershell -Command \"# Disable USB selective suspend globally in current power scheme\\npowercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0; powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0; powercfg /apply SCHEME_CURRENT; 'USB selective suspend disabled globally'\"",
    "timeout": 20
  }
}
```

**FIX C — Bluetooth Support Service na Automatic (jeśli nie jest):**
```json
// req-local-worker-07.json
{
  "id": "local-worker-07",
  "agent": "local-worker 01",
  "tool": "execute_command",
  "args": {
    "target": "local-pc",
    "command": "powershell -Command \"$svc = Get-Service -Name 'bthserv' -ErrorAction SilentlyContinue; if($svc){ Set-Service -Name 'bthserv' -StartupType Automatic; $svc.Status + ' -> set to Automatic' } else { 'Service not found' }\"",
    "timeout": 15
  }
}
```

---

### ETAP 3 — Skrypt monitorujący (utwórz plik)

Po naprawieniu problemu utwórz skrypt monitorujący:

```json
// req-local-worker-08.json
{
  "id": "local-worker-08",
  "agent": "local-worker 01",
  "tool": "execute_command",
  "args": {
    "target": "local-pc",
    "command": "powershell -Command \"New-Item -Path 'C:\\Users\\tomas2\\local-guardian\\scripts\\devices' -ItemType Directory -Force | Out-Null; 'Directory created'\"",
    "timeout": 10
  }
}
```

Następnie napisz plik `C:\Users\tomas2\local-guardian\scripts\devices\Watch-BluetoothEvents.ps1` przez `write_to_file` (lokalne — nie GitHub MCP):

```powershell
<# 
.SYNOPSIS
    Watch-BluetoothEvents.ps1 — monitoruje rozłączenia Bluetooth w Event Log
    Workspace: local-guardian
    Author: [local-worker 01] | local-guardian
#>

param(
    [int]$LastHours = 24,
    [switch]$ExportCSV
)

Write-Host "=== Bluetooth Event Monitor ===" -ForegroundColor Cyan
Write-Host "Okres: ostatnie $LastHours godzin`n"

$since = (Get-Date).AddHours(-$LastHours)

# Logi Bluetooth
$btLogs = @(
    'Microsoft-Windows-Bluetooth-MTPEnum/Operational',
    'Microsoft-Windows-BluetoothAdapter/Operational'
)

$events = foreach ($log in $btLogs) {
    Get-WinEvent -LogName $log -ErrorAction SilentlyContinue |
        Where-Object { $_.TimeCreated -gt $since } |
        Select-Object TimeCreated, Id, LevelDisplayName, Message, LogName
}

# System log — BT/HID errors
$sysEvents = Get-WinEvent -LogName System -ErrorAction SilentlyContinue |
    Where-Object { 
        $_.TimeCreated -gt $since -and 
        $_.Level -le 3 -and 
        ($_.Message -match 'Bluetooth|HID|wireless adapter|dongle')
    } |
    Select-Object TimeCreated, Id, LevelDisplayName, Message, @{N='LogName';E={'System'}}

$all = @($events) + @($sysEvents) | Sort-Object TimeCreated -Descending

if ($all.Count -eq 0) {
    Write-Host "✅ Brak zdarzeń Bluetooth w ciągu ostatnich $LastHours godzin." -ForegroundColor Green
} else {
    Write-Host "⚠️ Znaleziono $($all.Count) zdarzeń:" -ForegroundColor Yellow
    $all | Format-Table TimeCreated, Id, LevelDisplayName, LogName -AutoSize
    $all | ForEach-Object { 
        Write-Host "[$($_.TimeCreated)] ID:$($_.Id) - $($_.Message.Substring(0, [Math]::Min(120, $_.Message.Length)))" 
    }
}

if ($ExportCSV) {
    $path = "C:\Users\tomas2\local-guardian\reports\bt-events-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
    $all | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
    Write-Host "`n📄 Wyeksportowano: $path" -ForegroundColor Cyan
}
```

---

### ETAP 4 — Raport

Zapisz raport do:
`write_to_file → C:\Users\tomas2\.gemini\antigravity\playground\local-guardian\.agents\reports\2026-04-14_local-worker-01_bluetooth-fix.md`

Format raportu:
```markdown
# Raport: Bluetooth Logitech Disconnect Fix
**Agent:** [local-worker 01] | local-guardian | 14.04.2026
**Status:** ✅ zakończono / ⚠️ częściowo / ❌ nierozwiązane

## Diagnoza
[Co znalazłeś w Event Log — błędy, Event ID, czas rozłączeń]

## Zastosowane fix-y
[Lista fix'ów A/B/C + wyniki komend]

## Stan po naprawie
[Wynik Get-PnpDevice po fix'ach]

## Skrypt monitorujący
Plik: scripts/devices/Watch-BluetoothEvents.ps1 ✅

## Rekomendacje
[Np. jeśli problem to konkretny sterownik — wersja do downgrade/update]
```

**Raport do Supervisora (sonic-void inbox)** — pomiń GitHub MCP jeśli niedostępny, zapisz tylko lokalnie i odnotuj w chacie:
```
📨 RAPORT DO [Supervisor 01]:
[local-worker 01] zakończył diagnostykę i fix Bluetooth Logitech.
Wynik: [krótki opis]. Raport: 2026-04-14_local-worker-01_bluetooth-fix.md
```

---

## Kontekst techniczny

| Element | Wartość |
|---------|---------|
| OS | Windows (tomas2) |
| Urządzenia | Logitech mysz + klawiatura BT |
| Adapter | USB Bluetooth dongle (dioda miga po rozłączeniu) |
| Fix ręczny | Odłączenie/podłączenie dongla → urządzenia wracają |
| Hipoteza | USB selective suspend / power management resettuje stos BT bez reinicjalizacji połączeń |
| Target bridge | `local-pc` |

---

⏭️ Po zakończeniu napisz "gotowe" do Supervisora (sonic-void).
