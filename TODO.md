# RadioKit Regia — TODO list completa

> Mappatura sulle 10 funzioni core del progetto iniziale + estensioni
> emerse durante lo sviluppo (testabilità, brand consistency, multi-product).

Legenda: ✅ done — 🟡 in progress — ⏳ todo — ❌ skipped

---

## 1. Funzioni core (10 originali del progetto)

| # | Funzione | Stato | Dettagli |
|---|---|---|---|
| 1 | **Switch Live/AutoDJ** | ⏳ | Bridge handler `live.start/stop` da implementare lato bridge Timer (RadioBOSS API call). VPS endpoint pronto. |
| 2 | **Controllo Play-Out** | 🟡 parziale | Bridge handler `playlist.skip` ✅ implementato, `playlist.insert_jingle` stub, `playlist.next` info da fare |
| 3 | **Monitor Stream** | 🟡 parziale | Bridge handler `monitor.status` ✅ ritorna playbackinfo grezzo. Da parsare nei campi corretti + listener count da Centova/Icecast |
| 4 | **Regia Remota (fader)** | ⏳ | RadioBOSS API non espone fader granulari. Possibile: volume master + mute mic via Diretta bridge. |
| 5 | **Notifiche Push** | ⏳ | OneSignal App ID placeholder. Setup app dedicata + integration in app Flutter |
| 6 | **Caricamento Contenuti** ⭐ | ⏳ | Tab "🎤 Audio" — registra/seleziona audio dal telefono, upload, insert in playlist. Vedi sezione dedicata sotto. |
| 7 | **Analytics Live** | ⏳ | Listener realtime + geolocation. Endpoint `/analytics_snapshot` sul VPS |
| 8 | **Multi-Stazione** | 🟡 base | DB radiokit multi-tenant, Diretta v2 multi-stanza. Da fare: switch radio nell'app dal menu account |
| 9 | **Voice Commands** | ❌ skip | ROI basso, non in scope |
| 10 | **Backup & Log** | 🟡 base | RadioBOSS Cloud auto-archive esistente. Log operazioni: pull da `rk_command_queue` per dashboard |

⭐ = prossima priorità dopo i test attuali

---

## 2. Estensione "🎤 Audio" — invio messaggi audio (priorità ALTA)

Funzionalità aggiuntiva richiesta in conversazione: il regista può registrare un audio dal telefono o sceglierne uno dalla gallery e mandarlo in onda nella playlist RadioBOSS.

### Architettura

```
[Telefono] ──upload mp3─► [VPS storage] ──cmd queue─► [Timer bridge]
                              │                            │
                              ◄─── download audio ────────┤
                                                          │
                                                          ▼ insert in RadioBOSS hot folder
                                                          ▼ playtrack via API
```

### Backend (VPS)
- ⏳ Endpoint `POST /api/regia/?action=audio_upload` (multipart, max 10MB, formati mp3/wav/m4a/ogg)
- ⏳ Storage temp `/var/www/radiokit.io/storage/regia-audio/<radio_id>/<file_id>.mp3`
- ⏳ Auto-pulizia 24h via cron
- ⏳ Endpoint `GET /api/regia/?action=audio_download&file_id=X` (Bearer auth, restituisce binary)
- ⏳ Cmd handler `playlist.insert_audio` con payload `{ file_id, title?, mode: now|endtrack|fade }`

### Frontend (app Flutter)
- ⏳ Tab "🎤 Audio" (sostituisce Library o aggiunta come 6° tab)
- ⏳ Pulsante record (`record` package) con timer + waveform
- ⏳ File picker (`file_picker`) per audio dalla gallery
- ⏳ Modalità avvio (Subito / Fine brano / Cross-fade) — stesso pattern Stream URL
- ⏳ Preview pre-invio (`audioplayers`)
- ⏳ Upload progress bar
- ⏳ Lista "ultimi audio inviati" con stato (in coda / in onda / errore)

### Bridge (Timer Python)
- ⏳ `_handle_playlist_insert_audio(cfg, payload)`:
  1. Download da VPS via `/audio_download?file_id=X` (Bearer header)
  2. Salva in cartella RadioBOSS configurabile (`cfg["radioboss_hot_folder"]`)
  3. Chiama RadioBOSS API `playtrack` con path locale + modalità
  4. ACK al VPS

---

## 3. App Flutter (UI/UX)

### Schermate da completare

| Tab | Stato | Cosa manca |
|---|---|---|
| **Activation** | ✅ tema dark broadcast | — |
| **Stream URL** | ✅ completa | — |
| **Home/Dashboard** | ⏳ stub "TODO" | Now playing, listener live KPI, status bridge, shortcut "Vai in onda da URL", recenti, push log |
| **On Air** | ⏳ stub "TODO" | Now playing card, queue, skip, insert jingle modal, toggle Live/AutoDJ |
| **Listener** | ⏳ stub "TODO" | Grafico realtime, mappa geo, retention |
| **Library** | ⏳ stub "TODO" | Lista jingles + brani + upload (vedi tab Audio sopra) |
| **Push** | ⏳ stub "TODO" | Lista notifiche inviate, pulsante "invia push manuale", template |
| **History** | ⏳ stub "TODO" | Storico brani + storico comandi inviati con stato |
| **Account** | ✅ base | Profilo + lingua live + logout |

### Polish app
- ⏳ Splash screen con logo (ora solo spinner)
- ⏳ Font Geist (Geist Regular/Medium/SemiBold/Bold + GeistMono) — scaricare da vercel.com/font, copiare in `flutter/assets/fonts/`, decommentare in pubspec
- ⏳ Animazione transizione tab
- ⏳ Pull-to-refresh su Home/Listener
- ⏳ Toast personalizzati (sostituire snackbar Material default)

---

## 4. iOS

- ⏳ **Riabilitare iOS build** (rimuovere `if: false` dal job iOS in `.github/workflows/build.yml`)
- ⏳ Apple Developer Account: certificati distribution
- ⏳ Secrets GitHub: `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APP_STORE_CONNECT_KEY_BASE64`, `ios/ExportOptions.plist`
- ⏳ TestFlight upload automatico

---

## 5. VPS API

### Endpoint esistenti ✅
- `auth` — chiave RK-/RKT-/RKR- → JWT + radio_id + services + bridges_online
- `status` — stato globale + sessione stream URL attiva
- `probe` — verifica URL stream raggiungibile + codec
- `stream_url_start` / `stream_url_status` / `stream_url_stop`
- `bridge_heartbeat` / `bridge_pull` / `bridge_ack`

### Endpoint da fare ⏳
- `audio_upload` (multipart) + `audio_download` (Bearer)
- `playlist_skip` / `playlist_insert_jingle` / `playlist_insert_audio` (queue cmd)
- `live_start` / `live_stop` (queue cmd)
- `analytics_snapshot` (now playing + listener + retention)
- `push_send` (OneSignal proxy)
- `bridges_status` (lista bridge online per dashboard admin)

### WebSocket future
- Polling ora va bene, considerare WSS solo se servirà latenza < 1s

---

## 6. Bridge Timer (`radiokit_regia_bridge.py`)

### Handler implementati ✅
- `stream_url.start` (settrackinfo + playurl)
- `stream_url.stop` (stopurl / playauto fallback)
- `playlist.skip` (next)
- `monitor.status` (playbackinfo grezzo)

### Handler da implementare ⏳
- `playlist.insert_jingle` (file picker su disco RadioBOSS)
- `playlist.insert_audio` (download da VPS + insert in RadioBOSS)
- `live.start` / `live.stop` (toggle Live/AutoDJ)
- `mic.mute` / `mic.volume` (richiede Diretta bridge)

### Polish bridge
- ⏳ Integrare con `log_msg()` del Timer GUI per vedere log nel pannello
- ⏳ Indicatore stato bridge in Timer GUI (icona verde/rossa "Regia connessa")
- ⏳ Watchdog stream URL: se sorgente cade >10s → auto-fallback ad AutoDJ
- ⏳ Modalità avvio (Subito / Fine brano / Cross-fade) implementata in RadioBOSS

---

## 7. Bridge Diretta (futuro)

Se vorremo aggiungere comandi mic.mute / mic.volume / live.start, va creato un modulo `radiokit_regia_bridge.py` analogo dentro Diretta Win/Mac.

- ⏳ File `radiokit_regia_bridge.py` in `RadioKit/diretta/` (analogo a Timer)
- ⏳ Integrazione in main Diretta (1 riga thread spawn)
- ⏳ Handler: `live.start`, `live.stop`, `mic.mute`, `mic.volume`
- ⏳ Heartbeat con `bridge_type=diretta`

---

## 8. Sito radiokit.io

### Già fatto ✅
- DB: schema multi-prodotto (wants_regia/speaker + key cols)
- `includes/rk_products.php`: registry centralizzato (DRY)
- `beta.php`: form registrazione 4 prodotti, card "Aggiungi prodotto", card chiavi tutte
- `lang_beta.php`: i18n IT/EN/FR/ES per stringhe Regia + Speaker
- Admin tab Deploy: voce Regia aggiunta
- Workflow GH Actions deploy APK su `/downloads/regia/latest/`

### Da fare ⏳
- ⏳ Card download Regia/Speaker nella dashboard beta (legge da `latest.json` manifest)
- ⏳ Email automatica al click "Attiva ora" con istruzioni download per il nuovo prodotto
- ⏳ Endpoint `/api/admin/release-published.php` — log release Regia nel DB admin
- ⏳ Refactor `admin/index.php` $DL_FILES per leggere dal registry RK_PRODUCTS (DRY anche qui)

---

## 9. Build pipeline

### Flutter Regia ✅
- GitHub Actions: build Android + auto-deploy su radiokit.io
- Artifact APK + manifest JSON

### Timer Win ⏳
- ⏳ Spostare build da PyInstaller manuale a GH Actions (windows-latest)
- ⏳ Stesso pattern di Diretta Mac (`build-mac.yml`)
- ⏳ Auto-upload su radiokit.io download

### Diretta Mac ✅ esistente

---

## 10. Test end-to-end (PRIMA cosa da fare al rientro)

- 🟡 Stream URL: app Regia → VPS → Timer bridge → RadioBOSS playurl
  - ✅ App invia comando
  - ✅ VPS accoda
  - ✅ Bridge pull
  - ✅ Bridge ack
  - 🟡 RadioBOSS riproduce davvero lo stream (da verificare in studio)

---

## 11. Cose secondarie (nice-to-have)

- ⏳ Dark/light theme switch (per ora solo dark)
- ⏳ Esportazione log come CSV (Storico brani)
- ⏳ Widget Android per status on-air rapido
- ⏳ Apple Watch companion (futuro distante)
- ⏳ Sponsor/ads tracking dentro Analytics

---

## Memoria sessioni recenti

- 02/05/2026: scaffold completo Regia + bridge Timer + API VPS + sito beta DRY refactor
  → vedi `memory/sessione-2026-05-01.md` (estesa al 02/05)

## Repos

- App Regia: https://github.com/davidegialli/radiokit-app-regia
- Timer: https://github.com/davidegialli/radiokit-timer
- Diretta: https://github.com/davidegialli/radiokit-diretta
