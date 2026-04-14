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
