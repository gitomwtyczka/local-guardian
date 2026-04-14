# 🛡️ Local Guardian

Workspace do automatycznej konserwacji, monitoringu i diagnostyki lokalnego komputera Windows.

## Szybki start

```powershell
# Bluetooth monitor (ostatnie 72h)
.\scripts\devices\Watch-BluetoothEvents.ps1 -LastHours 72

# System snapshot
.\scripts\monitoring\Get-SystemSnapshot.ps1

# Czyszczenie temp
.\scripts\cleanup\Clean-Temp.ps1 -WhatIf   # podgląd
.\scripts\cleanup\Clean-Temp.ps1            # wykonanie

# Event Log errors
.\scripts\errors\Get-EventErrors.ps1 -LastHours 48 -ExportCSV
```

## Moduły

| Moduł | Skrypty | Status |
|-------|---------|--------|
| devices | Watch-BluetoothEvents.ps1 | ✅ |
| cleanup | Clean-Temp.ps1 | ✅ |
| monitoring | Get-SystemSnapshot.ps1 | ✅ |
| errors | Get-EventErrors.ps1 | ✅ |
| backup | Backup-UserProfile.ps1 | 📋 planned |
| updates | Get-UpdateStatus.ps1 | 📋 planned |

## Architektura

```
local-guardian/
├── AGENTS.md               # Reguły workspace
├── README.md               # Ten plik
├── scripts/
│   ├── cleanup/            # Czyszczenie temp, logów
│   ├── devices/            # BT, USB diagnostyka
│   ├── errors/             # Event Log errors, BSOD
│   └── monitoring/         # CPU/RAM/dyski snapshot
├── reports/                # Wygenerowane raporty CSV/HTML
└── .agents/                # Heartbeat, raporty agentów, taski
```

## Dostęp zdalny (stellar-relay)

Skrypty mogą być uruchamiane zdalnie przez FILE BRIDGE (`target: local-pc`).
Operacje admin wymagają UAC elevation pattern — popup na ekranie użytkownika.

---

*Workspace: local-guardian | Antigravity ecosystem*
