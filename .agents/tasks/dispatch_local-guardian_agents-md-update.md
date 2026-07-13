# DISPATCH — local-guardian worker | AGENTS.md: ochrona dużych plików

**Data:** 2026-07-13  
**Od:** Supervisor 01  
**Do:** local-guardian (worker — tylko GitHub MCP write, zero deploy)  
**Zakres:** 4 repozytoria, tylko pliki AGENTS.md

---

## ⚡ KROK 0

```
mcp_github_get_file_contents:
  owner: gitomwtyczka
  repo: sonic-void
  branch: master
  path: .agents/protocols/dispatch-system-block.md
```
Heartbeat do `local-guardian/.agents/heartbeat.json`.

---

## ⚠️ ZNANE PUŁAPKI

1. Przed UPDATE zawsze pobierz SHA pliku przez `get_file_contents`
2. Jeśli plik nie istnieje — użyj `create_or_update_file` bez `sha`
3. Jeśli plik istnieje — pobierz SHA i przekazuj go przy update
4. Nie modyfikuj nic poza AGENTS.md w każdym repo

---

## 🎯 ZADANIE 1 — crimson-void/AGENTS.md (KRYTYCZNE)

**Repo:** `gitomwtyczka/crimson-void` | branch: `main`

Pobierz aktualny AGENTS.md:
```
mcp_github_get_file_contents:
  owner: gitomwtyczka
  repo: crimson-void
  branch: main
  path: AGENTS.md
```
Zapisz SHA. Następnie **dopisz** na końcu pliku poniższą sekcję (nie nadpisuj całego pliku):

```markdown
---

## ⚠️ PUŁAPKA CZYTANIA DUŻYCH PLIKÓW — OBOWIĄZKOWA PROCEDURA

> Dodane: 2026-07-13 [Supervisor 01] — na podstawie audytu ekosystemu

**Problem:** `frontend/src/app/page.tsx` ma 243 KB. GitHub MCP `get_file_contents`
przy tym rozmiarze zapisuje wynik do bufora, a domyślny odczyt przez `view_file`
widzi tylko **pierwsze 800 linii bez błędu**. Agent pracuje na 3% pliku nie wiedząc.
Tak samo zagrożenie dotyczy: `AdminPanel.tsx` (33.8 KB), `PublishPanel.tsx` (33.8 KB),
`TierAnalyzer.tsx` (30.3 KB).

### Obowiązkowa procedura przed edycją tych plików

**KROK 1 — Mapowanie (grep przez SSH):**
```powershell
ssh -i C:\Users\tomas2\.ssh\oracle-crimson.key -o StrictHostKeyChecking=no ubuntu@147.224.162.100 `
  "grep -n 'szukany_fragment' /home/ubuntu/crimson-void/frontend/src/app/page.tsx"
```

**KROK 2 — Czytanie bloku (sed przez SSH):**
```powershell
ssh ... "sed -n 'LINIA_START,LINIA_ENDp' /home/ubuntu/crimson-void/frontend/src/app/page.tsx"
```

**KROK 3 — Weryfikacja:** grep musi potwierdzić że fragment istnieje.
Jeśli nie znajdziesz — STOP, raport do Supervisora.

### Plan refactoru `page.tsx` (do zaplanowania)
`page.tsx` @ 243 KB wymaga podziału na komponenty.
Refactor jako osobny dispatch — nie łączyć z innymi zadaniami.
Priorytet: WYSOKI — każda edycja tego pliku bez grep+sed jest ryzykowna.

*[Supervisor 01 | sonic-void 13.07.2026] — reguła grep+sed dla dużych plików*
```

---

## 🎯 ZADANIE 2 — social-publisher/AGENTS.md (NOWY PLIK)

**Repo:** `gitomwtyczka/social-publisher` | branch: `master`

Sprawdź czy AGENTS.md istnieje:
```
mcp_github_get_file_contents:
  owner: gitomwtyczka
  repo: social-publisher
  branch: master
  path: AGENTS.md
```
Jeśli 404 — utwórz nowy plik z treścią:

```markdown
# AGENTS.md — social-publisher

> Uzupełnia `RULE[user_global]`. Nie zastępuje.
> Utwórzono: 2026-07-13 [Supervisor 01] — audit ekosystemu

---

## REPO

- **GitHub:** `gitomwtyczka/social-publisher` | branch: `master`
- **Workspace:** social-publisher

---

## DOSTEP DO VPS

SSH: `ssh -i C:\Users\tomas2\.ssh\oracle-crimson.key -o StrictHostKeyChecking=no ubuntu@147.224.162.100`

Tryb A (prosta komenda): SSH inline  
Tryb B (złożona / $zmienne): `write_to_file` → `scp pełna ścieżka` → `ssh bash`

SCP na Windows — ZAWSZE pełne ścieżki (nie `~`).

---

## PLIKI PROJEKTOWE

Zawsze przez GitHub MCP — lokalny klon może być nieaktualny.

---

## PRE-FLIGHT CHECKLIST

Każdy dispatch musi zawierać blok:
```
## ⚠️ ZNANE PUŁAPKI
1. GitHub MCP: po create_or_update_file zweryfikuj SHA
2. SSH: NIE buduj złożonych komend inline — write_to_file → scp → ssh
3. SCP na Windows — NIGDY ~ w lokalnej ścieżce
```

---

*[Supervisor 01 | sonic-void 13.07.2026] — audit ekosystemu, v1.0*
```

---

## 🎯 ZADANIE 3 — pressai-wp/AGENTS.md (NOWY PLIK)

**Repo:** `gitomwtyczka/pressai-wp` | branch: `master`

Sprawdź czy istnieje, jeśli nie — utwórz z identyczną treścią jak w Zadaniu 2
(zmień tylko `# AGENTS.md — social-publisher` na `# AGENTS.md — pressai-wp`
i `repo: social-publisher` na `repo: pressai-wp`).

---

## 🎯 ZADANIE 4 — axial-supernova/AGENTS.md (NOWY PLIK)

**Repo:** `gitomwtyczka/axial-supernova` | branch: `master`

Sprawdź czy istnieje, jeśli nie — utwórz z identyczną treścią jak w Zadaniu 2
(zmień nazwę repo odpowiednio).

---

## ✅ DEFINITION OF DONE

- [ ] crimson-void/AGENTS.md — sekcja grep+sed dopisana
- [ ] social-publisher/AGENTS.md — nowy plik stworzony
- [ ] pressai-wp/AGENTS.md — nowy plik stworzony
- [ ] axial-supernova/AGENTS.md — nowy plik stworzony
- [ ] Każdy commit zweryfikowany przez `get_file_contents`

---

## 📨 RAPORT

```
local-guardian/.agents/reports/2026-07-13_local-guardian_agents-md-update.md
sonic-void/.agents/reports/inbox/2026-07-13_local-guardian_agents-md-update.md
```

Zawartość: SHA commitów dla każdego repo, co stworzono/zaktualizowano.

---

*Supervisor 01 | sonic-void | 2026-07-13*
