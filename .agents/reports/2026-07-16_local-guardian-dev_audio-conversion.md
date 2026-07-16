# Raport z konwersji audio WAV -> MP3 oraz wygenerowania szablonów reklamacji

**Callsign:** local-guardian-dev  
**Data:** 2026-07-16  
**Workspace:** local-guardian  
**Zadania:**
1. Konwersja pliku audio z formatu WAV na format MP3 w celu osadzenia go na stronie WWW.
2. Opracowanie wszystkich wzorów wniosków o odszkodowania (reklamacji) ze strony ECK i wygenerowanie ich w formacie DOCX jako szablony do uzupełnienia.

## 1. Konwersja audio
- **Plik wejściowy:** `D:\Biblioteki\Kurier\!_audio\odszkodowania za opóźnienie w liniach lotniczych lukacijewska.wav` (WAV stereo, PCM 16-bit, 48000 Hz, 1536 kbps, ~96 MB)
- **Plik wyjściowy:** `D:\Biblioteki\Kurier\!_audio\odszkodowania za opóźnienie w liniach lotniczych lukacijewska.mp3` (MP3 stereo, 128 kbps, 8.2 MB)
- **Użyte narzędzie:** FFmpeg (wersja 8.0-essentials)

## 2. Generowanie szablonów reklamacji DOCX
- **Źródło wzorów:** [Europejskie Centrum Konsumenckie](https://konsument.gov.pl/wzory-reklamacji-do-linii-lotniczych/)
- **Lokalizacja wyjściowa:** `D:\Biblioteki\Kurier\linie odszkodowania`
- **Wygenerowane szablony (łącznie 12 plików DOCX):**
  1. `1. Reklamacja na opóźniony bagaż.docx`
  2. `2. Reklamacja na zagubiony bagaż (nieodnaleziony przez 21 dni).docx`
  3. `3. Reklamacja - uszkodzony bagaż.docx`
  4. `4. Reklamacja - opóźniony lot.docx`
  5. `5. Reklamacja - odwołany lot (przebukowanie).docx`
  6. `6. Reklamacja - odwołany lot (rezygnacja).docx`
  7. `7. Complaint on delayed luggage (Reklamacja na opóźniony bagaż).docx`
  8. `8. Complaint on lost luggage (Reklamacja na zagubiony bagaż).docx`
  9. `9. Complaint on damaged luggage (Reklamacja - uszkodzony bagaż).docx`
  10. `10. Complaint on delayed flight (Reklamacja - opóźniony lot).docx`
  11. `11. Complaint on cancelled flight - rebooking (Reklamacja - odwołany lot - przebukowanie).docx`
  12. `12. Complaint on cancelled flight - resignation (Reklamacja - odwołany lot - rezygnacja).docx`
- **Format szablonów:** Pliki DOCX przygotowane w profesjonalnym układzie pism urzędowych, z marginesami 2,5 cm, czcionką Calibri 11pt, z wyraźnie oznaczonymi polami do uzupełnienia (np. `[Imię i nazwisko]`, `[data]`, `[kwota]`).
- **Narzędzie generujące:** Dedykowany skrypt Python wykorzystujący bibliotekę `python-docx`.

## Status
Oba zadania zostały pomyślnie ukończone. Pliki DOCX oraz plik MP3 znajdują się w wyznaczonych lokalizacjach na komputerze lokalnym użytkownika.
