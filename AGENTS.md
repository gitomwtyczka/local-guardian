# Local Guardian — Workspace Rules

## Stack
- PowerShell 5.1+ / 7.x
- Windows Event Log, WMI/CIM, PnP
- Środowisko: local-pc (Antigravity IDE — `run_command`)

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
Elevation przez Antigravity IDE — patrz GEMINI.md §UAC.

*Zaktualizowano: 2026-06-15 [sup-worker-01] — usunięto referencję do stellar-relay/bridge; środowisko = run_command*

## SSH z PowerShell — jeden wzorzec, zawsze ten sam

Tryb A (prosta, 1 linia): `ssh -i C:\Users\tomas2\.ssh\oracle-crimson.key -o StrictHostKeyChecking=no ubuntu@147.224.162.100 "komenda"`

Tryb B (złożona, domyślny): `write_to_file` → `scp pełna ścieżka` → `ssh bash /tmp/skrypt.sh`

Zasada kciuka: >1 cudzysłów lub $zmienna = Tryb B.
Dlaczego: PowerShell interpoluje zmienne i mangluje cudzysłowy zanim dotrą do SSH. Plik omija escapowanie.
