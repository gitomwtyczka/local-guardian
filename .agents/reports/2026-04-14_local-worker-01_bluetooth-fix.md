# Raport: Bluetooth Logitech Disconnect Fix
**Agent:** [local-worker 01] | local-guardian | 14.04.2026 20:20  
**Status:** ✅ zakończono (fix główny zastosowany)

---

## Diagnoza

### Event Log — znalezione zdarzenia

| Czas | Event ID | Log | Opis |
|------|----------|-----|------|
| 14.04.2026 19:25:14 | 16 | System | Uwierzytelnianie wzajemne BT — ponowne połączenie |
| 14.04.2026 19:25:13 | 16 | System | Uwierzytelnianie wzajemne BT — ponowne połączenie |
| 14.04.2026 19:17:11 | 16 | System | Uwierzytelnianie wzajemne BT — ponowne połączenie |
| 14.04.2026 19:17:06 | 16 | System | Uwierzytelnianie wzajemne BT — ponowne połączenie |
| **14.04.2026 19:16:32** | **6** | **System** | **⚠️ "Obsługiwany jest tylko jeden aktywny adapter Bluetooth"** |
| 14.04.2026 13:34:44 | 16 | System | Uwierzytelnianie wzajemne BT — ponowne połączenie |

**Wzorzec:** Event ID 6 (konflikt adapterów) o 19:16:32 → po chwili seria Event ID 16 (urządzenia próbują wrócić). To dokładnie odzwierciedla objawy użytkownika.

### Przyczyny (2 warstwy problemu)

**🔴 PRZYCZYNA 1 — USB Selective Suspend WŁĄCZONY (główna)**
- Stan przed fixem: `Current AC Power Setting Index: 0x00000001` (Włączone)
- Windows usypiał dongle USB mimo aktywnej diody LED
- Po usypieniu stack BT resetował się bez ponownej inicjalizacji połączeń urządzeń
- Stąd fix tymczasowy (odłącz/podłącz dongle) działał — fizyczny reset wymuszał reinicjalizację

**🔴 PRZYCZYNA 2 — Multiple Ghost BT Adapters (współistniejąca)**
- W systemie zarejestrowanych jest 6+ instancji `Generic Bluetooth Radio` (USB\VID_0A12\PID_0001) ze statusem `Unknown`
- Windows wykrywa je jako potencjalne adaptery konkurujące z aktywnym
- Event ID 6 wskazuje, że Windows od czasu do czasu wyłącza jeden z wielu adapterów uznając za konflikt
- Aktywny dziś: `USB\VID_0A12\PID_0001\7&19314B93&0&2` (Status: OK)

### Stan Bluetooth Support Service
- Status: `Running` | StartType: `Manual` (nie Automatic)
- Próba automatycznej zmiany nieudana (brak uprawnień admina przez bridge)
- Serwis działa — nie jest to przyczyna rozłączeń

---

## Zastosowane fix-y

### ✅ FIX B — USB Selective Suspend wyłączony globalnie
```powershell
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
```
**Wynik weryfikacji:**
- AC Power Setting Index: `0x00000000` ✅ (Wyłączone) — było `0x00000001`
- DC Power Setting Index: `0x00000000` ✅ (Wyłączone) — było `0x00000001`

### ⚠️ FIX C — Bluetooth Support Service (brak uprawnień przez bridge)
- Serwis: `bthserv` | Status: Running | StartType: Manual
- Nie zmieniono — wymaga ręcznej interwencji (patrz Rekomendacje)

---

## Stan po naprawie (PnP Devices — aktywne)

| Urządzenie | Status | DeviceID |
|------------|--------|----------|
| Generic Bluetooth Radio | **OK** | USB\VID_0A12\PID_0001\7&19314B93&0&2 |
| Bluetooth (radio) | **OK** | SWD\RADIO\BLUETOOTH_001A7DDA7113 |
| Logitech Download Assistant | **OK** | HID\{00001812...}_DEV_V... |
| GATT HID BLE device | **OK** | BTHLEDEVICE\{00001812...} |
| Bluetooth Device (RFCOMM) | **OK** | BTH\MS_RFCOMM\8&2A569297&0&0 |
| Bluetooth Device (PAN) #6 | **OK** | BTH\MS_BTHPAN\8&2A569297&0&2 |

Ghost adapters (`Generic Bluetooth Radio` ze statusem `Unknown`): **5 instancji** w rejestrze — do czyszczenia manualnie.

---

## Skrypt monitorujący
Plik: `C:\Users\tomas2\local-guardian\scripts\devices\Watch-BluetoothEvents.ps1` ✅

Funkcje skryptu:
- Skanowanie logów BT i System Event w zadanym przedziale czasowym
- Wykrywanie Event ID 6 (konflikt adapterów) i Event ID 16 (reconnect)
- Liczenie ghost adapterów (Unknown status)
- Eksport CSV na żądanie (`-ExportCSV`)
- Kolorowy output z alarmami

Użycie:
```powershell
# Quick check ostatnich 24h
.\Watch-BluetoothEvents.ps1

# Głęboki check + eksport
.\Watch-BluetoothEvents.ps1 -LastHours 72 -ExportCSV
```

---

## Rekomendacje

### 🔧 Do wykonania ręcznie przez użytkownika

**1. Usuń ghost adaptery (PRIORYTET WYSOKI)**
- Otwórz Device Manager (`devmgmt.msc`)
- Menu → View → Show hidden devices
- Bluetooth → USB Bluetooth Radio (wiele instancji ze zgaszonym ikonem — "phantom")
- Prawym kliknikiem → Uninstall device (każdy z szarych)
- Zostaw tylko 1 aktywny adapter
- Restart komputera

**2. Bluetooth Support Service → Automatic (jako Admin)**
```powershell
# Uruchom PowerShell jako Administrator
Set-Service -Name 'bthserv' -StartupType Automatic
```

**3. Opcjonalnie — wyłącz USB suspend dla adaptera w Device Manager**
- Device Manager → Universal Serial Bus controllers → USB Root Hub
- Properties → Power Management → odznacz "Allow computer to turn off this device to save power"

### 📊 Monitoring
- Uruchamiaj `Watch-BluetoothEvents.ps1` po kilku dniach użytkowania
- Jeśli Event ID 6 przestanie pojawiać się → problem rozwiązany
- Jeśli problem wraca → podejrzewaj sterownik do aktualizacji (VID_0A12 = CSR/Qualcomm chip)

### 🔄 Jeśli problem powróci
- Wersja sterownika Generic BT Radio (VID_0A12&PID_0001): sprawdź w devmgmt.msc → może wymagać downgrade lub ręcznego sterownika Logitech Unifying
- Logitech Unifying Receiver (C52B) ma własny sterownik — rozważ Logitech Options/G HUB zamiast natywnego BT Windows

---

## Podsumowanie chronologiczne

| Krok | Akcja | Wynik |
|------|-------|-------|
| ETAP 1a | Event Log MTPEnum | Brak eventów (log nieaktywny) |
| ETAP 1b | Event Log System/Application | ✅ Znaleziono Event ID 6 i 16 — wzorzec rozłączeń |
| ETAP 1c | Get-PnpDevice | ✅ 6+ ghost adapters VID_0A12 zidentyfikowanych |
| ETAP 1d | powercfg USB suspend | ✅ Stan przed: AC=1 DC=1 (Włączone) |
| ETAP 2B | FIX B USB suspend wyłącz | ✅ AC=0 DC=0 po zmianie |
| ETAP 2C | FIX C bthserv Automatic | ⚠️ Brak uprawnień (do ręcznego) |
| ETAP 3 | Skrypt Watch-BluetoothEvents.ps1 | ✅ Utworzony |
