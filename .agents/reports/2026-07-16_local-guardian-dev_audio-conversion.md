# Raport z konwersji audio WAV -> MP3

**Callsign:** local-guardian-dev  
**Data:** 2026-07-16  
**Workspace:** local-guardian  
**Zadanie:** Konwersja pliku audio z formatu WAV na format MP3 w celu osadzenia go na stronie WWW.

## Szczegóły operacji
- **Plik wejściowy:** `D:\Biblioteki\Kurier\!_audio\odszkodowania za opóźnienie w liniach lotniczych lukacijewska.wav`
  - Format: WAV (stereo, PCM 16-bit, 48000 Hz)
  - Bitrate: 1536 kbps
  - Czas trwania: 08:44 minuty
  - Rozmiar: ok. 96 MB
- **Plik wyjściowy:** `D:\Biblioteki\Kurier\!_audio\odszkodowania za opóźnienie w liniach lotniczych lukacijewska.mp3`
  - Format: MP3 (stereo, LAME encoder)
  - Bitrate: 128 kbps (stały, zoptymalizowany pod kątem WWW)
  - Rozmiar: 8.2 MB (~8194 KiB)
- **Czas konwersji:** ~3.33 sekundy (prędkość 157x)
- **Użyte narzędzie:** FFmpeg (wersja 8.0-essentials) za pomocą komendy:
  ```powershell
  ffmpeg -y -i "D:\Biblioteki\Kurier\!_audio\odszkodowania za opóźnienie w liniach lotniczych lukacijewska.wav" -codec:a libmp3lame -b:a 128k "D:\Biblioteki\Kurier\!_audio\odszkodowania za opóźnienie w liniach lotniczych lukacijewska.mp3"
  ```

## Status
Zadanie zostało pomyślnie zakończone. Wyjściowy plik MP3 jest gotowy do osadzenia na stronie WWW.
