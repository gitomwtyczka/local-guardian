# DISPATCH — [local-worker 01] Bootstrap repo + skrypty maintenance

## ⚡ KROK 0 — ZANIM cokolwiek zrobisz

**0. Wczytaj blok systemowy:**
`view_file → C:\Users\tomas2\.gemini\antigravity\playground\sonic-void\.agents\protocols\dispatch-system-block.md`

---

## Tożsamość agenta

- **Callsign:** `[local-worker 01]`
- **Workspace:** `local-guardian`
- **Model:** Claude Sonnet (thinking)
- **Deliverable:** Działające repo GitHub + 3 moduły skryptów + AGENTS.md + README.md

---

## Heartbeat (PIERWSZY krok)

```json
// write_to_file → C:\Users\tomas2\.gemini\antigravity\playground\local-guardian\.agents\heartbeat.json
{
  "callsign": "[local-worker 01]",
  "status": "working",
  "current_task": "Bootstrap local-guardian repo + maintenance scripts",
  "timestamp": "<ISO teraz>"
}
```

---

## ETAP 1 — Utwórz repo na GitHub

Użyj browser_subagent żeby utworzyć repo `local-guardian` na GitHub:
1. Otwórz `https://github.com/new`
2. Zaloguj się (jeśli trzeba — user gitomwtyczka)
3. Nazwa: `local-guardian`, Public, bez README (pusty)
4. Utwórz

Następnie przez FILE BRIDGE (target: local-pc) zainicjalizuj i pushuj:
```
cd C:\Users\tomas2\.gemini\antigravity\playground\local-guardian
git init
git remote add origin https://github.com/gitomwtyczka/local-guardian.git
git add -A
git commit -m "init: local-guardian workspace bootstrap [local-worker 01]"
git branch -M master
git push -u origin master
```

> ⚠️ Komendy git na local-pc: `powershell -Command "cd 'C:\Users\tomas2\.gemini\antigravity\playground\local-guardian'; git init; ..."`
> Podziel na osobne requesty jeśli timeout.

---

## ETAP 2 — Utwórz pliki strukturalne

### 2a. AGENTS.md (w katalogu workspace local-guardian)

Zapisz przez `write_to_file`:
```markdown
# Local Guardian — Workspace Rules

## Stack
- PowerShell 5.1+ / 7.x
- Windows Event Log, WMI/CIM, PnP
- Target stellar-relay: `local-pc` (execute_command)

## Konwencje
- Nazwy skryptów: `Verb-Noun.ps1` (PowerShell standard)
- Raporty output: CSV + HTML do `reports/`
- Parametry: `-LastHours`, `-ExportCSV` jako standard
- Każdy skrypt ma `<# .SYNOPSIS #>` header

## Moduły
| Moduł | Katalog | Opis |
|-------|---------|------|
| cleanup | scripts/cleanup/ | Czyszczenie temp, logów, prefetch |
| monitoring | scripts/monitoring/ | CPU/RAM/dyski snapshot + alerty |
| errors | scripts/errors/ | Event Log błędy, crash, BSOD |
| devices | scripts/devices/ | BT, USB — odłączenia, ghost devices |
| backup | scripts/backup/ | Archiwizacja profilu użytkownika |
| updates | scripts/updates/ | Windows Update + winget status |

## UAC
Skrypty wymagające admina mają `#Requires -RunAsAdministrator` na górze.
Przez bridge: używaj UAC elevation pattern (patrz GEMINI.md §UAC).
```

### 2b. README.md

```markdown
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
```

## Moduły

| Moduł | Skrypty | Status |
|-------|---------|--------|
| devices | Watch-BluetoothEvents.ps1 | ✅ |
| cleanup | Clean-Temp.ps1, Clean-Logs.ps1 | 🔧 |
| monitoring | Get-SystemSnapshot.ps1 | 🔧 |
| errors | Get-EventErrors.ps1 | 🔧 |
| backup | Backup-UserProfile.ps1 | 📋 planned |
| updates | Get-UpdateStatus.ps1 | 📋 planned |

## Skróty na Pulpicie
- `BT-Monitor.bat` — szybki check Bluetooth
```

---

## ETAP 3 — Skrypty PowerShell (3 moduły)

### 3a. `scripts/cleanup/Clean-Temp.ps1`

Zapisz przez `write_to_file` do `C:\Users\tomas2\.gemini\antigravity\playground\local-guardian\scripts\cleanup\Clean-Temp.ps1`:

Funkcjonalność:
- Parametr `-WhatIf` (tylko raport bez usuwania)
- Czyści: `$env:TEMP`, `$env:WINDIR\Temp`, `$env:LOCALAPPDATA\Temp`
- Opcjonalnie `Prefetch` (wymaga admina — ostrzeż jeśli brak uprawnień)
- Output: ile plików usunięto, ile MB zwolniono
- Kolorowy output (Write-Host z -ForegroundColor)

### 3b. `scripts/monitoring/Get-SystemSnapshot.ps1`

Zapisz do `C:\Users\tomas2\.gemini\antigravity\playground\local-guardian\scripts\monitoring\Get-SystemSnapshot.ps1`:

Funkcjonalność:
- CPU: nazwa procesora, load % (Get-CimInstance Win32_Processor)
- RAM: total, used, free, % użycia
- Dyski: każda partycja — total, free, % użycia
- Top 5 procesów po pamięci
- Output: tabela kolorowa w konsoli
- Parametr `-ExportHTML` → raport HTML do `reports/`

### 3c. `scripts/errors/Get-EventErrors.ps1`

Zapisz do `C:\Users\tomas2\.gemini\antigravity\playground\local-guardian\scripts\errors\Get-EventErrors.ps1`:

Funkcjonalność:
- Parametr `-LastHours 24` (domyślne)
- Źródła: System, Application
- Poziomy: Critical (1), Error (2)
- Wyświetl: TimeCreated, Source, EventID, Message (skrócony)
- Kategorie specjalne: Kernel-Power (BSOD), disk errors, driver crashes
- Parametr `-ExportCSV` → eksport do `reports/`
- Podsumowanie na końcu: ile Critical, ile Error, najczęstsze źródło

---

## ETAP 4 — Przetestuj skrypty

Przez FILE BRIDGE (target: local-pc) uruchom każdy skrypt i zweryfikuj output:

```json
{
  "tool": "execute_command",
  "args": {
    "target": "local-pc",
    "command": "powershell -ExecutionPolicy Bypass -File \"C:\\Users\\tomas2\\.gemini\\antigravity\\playground\\local-guardian\\scripts\\monitoring\\Get-SystemSnapshot.ps1\"",
    "timeout": 20
  }
}
```

Powtórz dla Clean-Temp.ps1 ( z `-WhatIf`!) i Get-EventErrors.ps1.

---

## ETAP 5 — Git commit + push

Po testach:
```
cd local-guardian
git add -A
git commit -m "feat: cleanup + monitoring + errors modules [local-worker 01]"
git push origin master
```

---

## ETAP 6 — Raport

Zapisz raport:
`write_to_file → C:\Users\tomas2\.gemini\antigravity\playground\local-guardian\.agents\reports\2026-04-14_local-worker-01_bootstrap.md`

Format:
```markdown
# Raport: Local Guardian Bootstrap
**Agent:** [local-worker 01] | local-guardian | DD.MM.YYYY
**Status:** ✅/⚠️

## Repo GitHub
- URL: https://github.com/gitomwtyczka/local-guardian
- Branch: master
- Commits: [lista]

## Skrypty utworzone
| Skrypt | Test | Wynik |
|--------|------|-------|

## Następne kroki
- backup module
- updates module
- Task Scheduler integration
```

📨 RAPORT DO [Supervisor 01] — jak w poprzedniej sesji.

---

⏭️ Po zakończeniu napisz "gotowe" do Supervisora (sonic-void).
