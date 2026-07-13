# DISPATCH — local-guardian | Audit dużych plików we wszystkich repo

**Data:** 2026-07-13  
**Od:** Supervisor 01  
**Do:** local-guardian (worker analityczny, read-only)  
**Workspace:** local-guardian

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

## KONTEKST

W repozytorium `video-seo-engine` wykryto że plik `dashboard-inner.tsx` ma 7865 linii (101 KB).
GitHub MCP `get_file_contents` przy takim rozmiarze zapisuje wynik do bufora, a domyślny
odczyt widzi tylko **pierwsze 800 linii bez błędu** — agent pracuje na 10% pliku nie wiedząc.

Konsekwencje: agenci dodają kod w złym miejscu, twierdzą że feature działa — a go nie ma.

Zadanie: sprawdzić czy ten problem występuje również w innych projektach ekosystemu.

---

## 🔍 ZADANIE — tylko czytanie przez GitHub MCP

### Lista repo do przeskanowania

```
gitomwtyczka/crimson-void       branch: main
gitomwtyczka/video-seo-engine   branch: main  (już zdiagnozowany)
gitomwtyczka/social-publisher   branch: master
gitomwtyczka/axial-supernova    branch: master
gitomwtyczka/shadow-perihelion  branch: main
gitomwtyczka/pressai-wp         branch: master
gitomwtyczka/feed-crawler       branch: main
gitomwtyczka/security-void      branch: master
```

### Dla każdego repo wykonaj:

**Krok 1:** Pobierz listę plików w katalogu `src/` lub `web/src/` lub głównym katalogu:
```
mcp_github_get_file_contents:
  owner: gitomwtyczka
  repo: [nazwa]
  branch: [branch]
  path: [katalog główny lub src/]
```

**Krok 2:** Znajdź pliki frontendowe (`.tsx`, `.ts`, `.jsx`, `.js`, `.vue`, `.py`) z rozmiarem `size > 30000` bytes (~800 linii).

**Krok 3:** Sprawdź czy repo ma `AGENTS.md` w katalogu głównym.

**Krok 4:** Zapisz wyniki w tabeli.

### Priorytety skanowania

Skup się na plikach z frontendem (Next.js, React, Vue) i dużych plikach backendowych (FastAPI routers, Django views). Pomijaj `node_modules`, `.next`, `dist`, `build`.

Jeśli repo nie ma frontendu — zaznacz "backend only" i idź dalej.

---

## 📨 FORMAT RAPORTU

```
local-guardian/.agents/reports/2026-07-13_local-guardian_large-files-audit.md
sonic-void/.agents/reports/inbox/2026-07-13_local-guardian_large-files-audit.md
```

```markdown
# Audit: duże pliki w ekosystemie

## Wyniki per repo

| Repo | Plik | Rozmiar | Ryzyko MCP | Ma AGENTS.md? |
|---|---|---|---|---|
| video-seo-engine | dashboard-inner.tsx | 101 KB | 🔴 WYSOKIE | ✅ (zaktualizowany) |
| [inne repo] | [plik] | [rozmiar] | 🔴/🟡/🟢 | TAK/NIE |

## Progi ryzyka
- 🔴 WYSOKIE: > 50 KB (> ~1300 linii)
- 🟡 ŚREDNIE: 30-50 KB (800-1300 linii) 
- 🟢 OK: < 30 KB

## Repo bez frontendu
[lista]

## Rekomendacje
Dla każdego repo z ryzykiem 🔴/🟡:
- Czy wymaga aktualizacji AGENTS.md?
- Czy wymaga refactoru pliku?
- Priorytet

## Priorytetowa lista akcji
1. [repo] — [plik] — [co zrobić]
...
```

---

*Supervisor 01 | sonic-void | 2026-07-13*
