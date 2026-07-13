# Audit: duże pliki w ekosystemie

## Wyniki per repo

| Repo | Plik | Rozmiar | Ryzyko MCP | Ma AGENTS.md? |
|---|---|---|---|---|
| video-seo-engine | dashboard-inner.tsx | 101 KB | 🔴 WYSOKIE | ✅ (zaktualizowany) |
| crimson-void | frontend/src/app/page.tsx | 243 KB | 🔴 WYSOKIE | TAK |
| crimson-void | frontend/src/components/AdminPanel.tsx | 33.8 KB | 🟡 ŚREDNIE | TAK |
| crimson-void | frontend/src/components/PublishPanel.tsx | 33.8 KB | 🟡 ŚREDNIE | TAK |
| crimson-void | frontend/src/components/TierAnalyzer.tsx | 30.3 KB | 🟡 ŚREDNIE | TAK |
| social-publisher | brak | < 10 KB | 🟢 OK | NIE |
| shadow-perihelion | brak | < 12 KB | 🟢 OK | TAK |
| pressai-wp | brak | < 24 KB | 🟢 OK | NIE |

## Repo bez frontendu
- `axial-supernova` (backend only, max plik 16.6 KB, brak AGENTS.md)
- `feed-crawler` (skrypty pythona, max plik 11.7 KB, ma AGENTS.md)
- `security-void` (puste / config only, ma AGENTS.md)

## Progi ryzyka
- 🔴 WYSOKIE: > 50 KB (> ~1300 linii)
- 🟡 ŚREDNIE: 30-50 KB (800-1300 linii) 
- 🟢 OK: < 30 KB

## Rekomendacje
Dla każdego repo z ryzykiem 🔴/🟡:
- Czy wymaga aktualizacji AGENTS.md? `crimson-void` posiada już `AGENTS.md`, ale warto dodać zasady odnośnie modyfikacji tak dużych plików.
- Czy wymaga refactoru pliku? `frontend/src/app/page.tsx` w `crimson-void` ma 243 KB i bezwzględnie wymaga refactoru oraz podziału na komponenty. Pozostałe 3 pliki po ~30 KB zbliżają się do progu i również kwalifikują się do podziału.
- Priorytet: Wysoki (krytyczny dla `page.tsx`).

## Priorytetowa lista akcji
1. crimson-void — frontend/src/app/page.tsx — Natychmiastowy refactor, plik jest zbyt duży do obsługi przez agentów przez GitHub MCP.
2. crimson-void — AGENTS.md — Dodać notatkę o omijaniu bezpośredniej edycji `page.tsx` przez `create_or_update_file` bez uprzedniego podziału.
3. social-publisher — AGENTS.md — Utworzyć plik AGENTS.md (obecnie brak w repozytorium).
4. pressai-wp — AGENTS.md — Utworzyć plik AGENTS.md (obecnie brak w repozytorium).
5. axial-supernova — AGENTS.md — Utworzyć plik AGENTS.md (obecnie brak w repozytorium).