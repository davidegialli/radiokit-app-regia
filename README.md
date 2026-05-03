# RadioKit Regia — App Mobile

App mobile (Flutter, Android + iOS) per controllo regia radio web/digitale da remoto.
Pensata per titolari/direttori/speaker che vogliono gestire la diretta senza essere in studio.

---

## Stack tecnologico previsto

- **Framework**: Flutter (allineato a RadioKit Speaker mobile)
- **State management**: GetX
- **Storage**: GetStorage (preferenze locali)
- **Backend**: VPS RadioKit (`187.77.166.39`) — endpoint REST in `/api/`
- **Audio (eventuale live mic)**: protocollo Diretta v2 (porta 7410-7412)
- **Push**: OneSignal (App ID dedicata RadioKit Regia)
- **Auth**: sistema chiavi zero-config (stesso flow di RadioKit Diretta/Speaker) — l'utente attiva l'app con una chiave legata al suo account e ai servizi abilitati, nessuna configurazione di rete richiesta

---

## Attivazione & connettività (zero-config)

L'app **non richiede IP pubblico, port forwarding o VPN lato cliente**.
Stessa logica delle altre app RadioKit (Diretta Win/Mac, Speaker mobile):

### Sistema chiavi
- L'utente acquista/riceve una **licenza** legata al suo account radiokit
- L'admin genera una **chiave** (formato `RKR-XXXX-XXXX-XXXX` per "RadioKit Regia")
- Al primo avvio l'app chiede la chiave → la valida sul VPS → ottiene token JWT + lista servizi abilitati
- La chiave è legata a: `user_id`, `radio_id`, ruolo, scadenza, set di funzioni sbloccate

### VPS come bridge
Il VPS RadioKit (`187.77.166.39`) fa da intermediario per **tutte** le comunicazioni:
- App ↔ VPS (HTTPS/WSS, sempre raggiungibile)
- VPS ↔ RadioBOSS Cloud (API server-to-server)
- VPS ↔ DB radio cliente
- VPS ↔ stream encoder cliente (per il lancio diretta da URL)

→ Il cliente **non deve aprire porte**, **non deve avere IP statico**, **non deve configurare DNS**.
Funziona da qualsiasi rete (4G, hotel wifi, casa) come Diretta v2.

### Servizi abilitati per chiave
Esempi di "service flags" che la chiave può attivare:
- `regia.playout` — controllo playlist + skip
- `regia.live.relay` — diretta da mic via relay v2
- `regia.live.stream_url` — lancio diretta da URL stream esterno
- `regia.upload` — upload contenuti
- `regia.analytics` — analytics avanzate
- `regia.multi_station` — multi-stazione

L'app mostra/nasconde le tab in base ai flag ricevuti dal VPS al login.

---

## Funzioni — mappa di copertura

Riferimento: 10 funzioni essenziali per app regia radio.

### Core (priorità alta)

| # | Funzione | Backend disponibile | Note implementazione |
|---|---|---|---|
| 1 | Switch Live/AutoDJ | RadioBOSS Cloud API + Diretta v2 | Toggle: ferma AutoDJ → avvia relay mic. Fade già in SDL scheduler. |
| 2 | Controllo Play-Out | RadioBOSS API (`getplaylist`, `nexttrack`, `playtrack`, `inserttrack`) | Lista corrente + skip + insert jingle/spot. |
| 3 | Monitor Stream | DB `radiokit` listeners + RadioBOSS `/api/?action=info` + scheduler Python | Listener realtime, bitrate, status encoder, alert interruzioni. |
| 4 | Regia Remota (fader) | ⚠️ parziale — RadioBOSS Cloud non espone fader granulari | Volume master, mute mic, ducking on/off. Mixing fine solo via Diretta v2. |
| 4b | **Lancio diretta da stream esterno** | RadioBOSS API (`playurl`) + DB radiokit (palinsesto live) | Inserisce un URL di streaming (icecast/shoutcast/HLS) come sorgente live, con titolo programma + conduttore. Override AutoDJ finché attivo. |

### Avanzate (priorità media)

| # | Funzione | Backend disponibile | Note implementazione |
|---|---|---|---|
| 5 | Notifiche Push | OneSignal (`3e87897b-47fb-4389-9efe-9b99ecc6949d`) + scheduler Python | Hook su errori stream, picchi listener, fine playlist. |
| 6 | Caricamento Contenuti | Upload VPS (già in admin) + FTP/API RadioBOSS Cloud | Drag&drop jingle/promo, preview, schedulazione SDL. |
| 7 | Analytics Live | Grafici admin (esistenti) + da aggiungere geolocalizzazione | Listener, retention, geo (IP→country). Revenue ads fuori scope. |
| 8 | Multi-Stazione | DB `radiokit` multi-tenant + Diretta v2 multi-stanza + ruoli admin | Switch tra radio, gruppi, permessi (superadmin/direttore/speaker). |

### Extra (nice-to-have)

| # | Funzione | Stato | Note |
|---|---|---|---|
| 9 | Voice Commands | ❌ Skip | ROI basso, no base esistente. |
| 10 | Backup & Log | ✅ Esistente | RadioBOSS Cloud auto-archive + log admin radiokit. Esposizione via API. |

**Copertura totale: 9/11 funzioni implementabili con backend esistente.**

---

## Lancio diretta da stream URL (dettaglio)

Caso d'uso: il conduttore è in esterna (evento, locale, casa) e trasmette via un encoder verso uno stream icecast/shoutcast personale, oppure si vuole rilanciare un altro stream (radio partner, evento live).
L'app permette di puntare la regia a quell'URL con un click + impostare titolo del programma.

### Flow

1. Utente apre tab **Diretta** → **"Stream esterno"**
2. Inserisce:
   - **URL stream** (icecast/shoutcast/HLS) — es. `https://mio-encoder.com:8000/live`
   - **Titolo programma** — es. `"Live Show"`
   - **Conduttore** (opzionale, auto da profilo)
   - **Durata stimata** (slider 15min → 4h, o "fino a stop manuale")
3. Tap **"Vai in onda"**
4. Backend:
   - Verifica URL raggiungibile (HEAD request, controllo `Content-Type` audio)
   - Chiama RadioBOSS API: `playurl` con URL + metadata override
   - Aggiorna DB `radiokit` (palinsesto live + RDS)
   - Notifica push a tutti gli admin: "Diretta avviata: {titolo}"
   - Aggiorna metadata stream in tempo reale (titolo + artista=conduttore)
5. App mostra schermata ON-AIR con:
   - Timer trascorso
   - Listener live
   - Pulsante grosso **STOP** (rosso)
   - Indicatore qualità stream sorgente (ok/buffering/down)

### Backend tecnico

- **RadioBOSS Cloud**: comando `playurl` accetta URL stream esterno come sorgente
- **Override metadata**: API RDS già esistente — basta endpoint per override titolo+artista
- **Watchdog**: scheduler Python monitora che lo stream sorgente sia vivo; se cade per >10s, fallback ad AutoDJ + push alert
- **Auto-stop**: se durata stimata scade → torno ad AutoDJ con fade

### Endpoint API dedicati

- `POST /api/regia/live/stream-url` — body: `{url, titolo, conduttore, durata_min}`
- `GET  /api/regia/live/stream-url/status` — stato live in corso
- `POST /api/regia/live/stream-url/stop` — chiusura manuale

### Validazioni & sicurezza

- URL solo `https://` o `http://` con porta nota (8000-9999, 80, 443)
- Whitelist opzionale di domini sorgente (per evitare URL random)
- Rate limit: max 1 lancio ogni 30s (no spam on/off)
- Log su DB ogni avvio/stop con user_id + timestamp + URL

---

## Architettura proposta

```
[App Flutter Regia]
        │
        ├─── REST API ──────► VPS RadioKit (/api/regia/*)
        │                          │
        │                          ├─► RadioBOSS Cloud API (playlist, info)
        │                          ├─► DB radiokit (listener, log, ruoli)
        │                          └─► Scheduler Python (eventi SDL, monitoring)
        │
        ├─── WebSocket ─────► VPS (status realtime, listener live)
        │
        ├─── UDP/TCP ───────► Relay Diretta v2 (audio mic in live)
        │
        └─── Push ───────────► OneSignal (alert)
```

---

## Endpoint API da creare lato VPS

Da aggiungere sotto `/api/regia/` (richiedono token JWT con ruolo direttore+):

- `POST /api/regia/auth` — login con credenziali admin radiokit
- `GET  /api/regia/status` — stato globale (live/autodj, listener, bitrate)
- `POST /api/regia/live/start` — avvia diretta (kill autodj + apri relay)
- `POST /api/regia/live/stop` — chiudi diretta + ripristina autodj
- `POST /api/regia/live/stream-url` — avvia diretta da URL stream esterno con titolo
- `GET  /api/regia/live/stream-url/status` — stato stream esterno in corso
- `POST /api/regia/live/stream-url/stop` — stop diretta da URL
- `GET  /api/regia/playlist` — playlist corrente
- `POST /api/regia/playlist/skip` — skip brano
- `POST /api/regia/playlist/insert` — insert jingle/spot urgente
- `GET  /api/regia/monitor` — bitrate + encoder status
- `GET  /api/regia/listeners/live` — listener realtime + geo
- `POST /api/regia/upload` — upload contenuto (jingle/promo)
- `GET  /api/regia/log` — operazioni recenti
- `WS   /api/regia/stream` — websocket per push realtime

---

## Roadmap minima MVP

**Fase 1 — Sola lettura (1-2 settimane)**
- Auth + token
- Dashboard: now playing, listener count, status stream
- Notifiche push base (errori stream)

**Fase 2 — Controlli base (2-3 settimane)**
- Skip brano, insert jingle
- Toggle Live/AutoDJ
- Monitor bitrate

**Fase 3 — Regia avanzata (3-4 settimane)**
- Upload contenuti
- Multi-stazione
- Analytics realtime con grafici
- Mute mic + volume master

**Fase 4 — Live audio (opzionale, complessità alta)**
- Integrazione Diretta v2 → mic in diretta dall'app
- Richiede gestione codec, latenza, AEC mobile

---

## Note di design (da definire)

- Layout dark-first (sala regia)
- Tab bottom: **Diretta** | **Playlist** | **Monitor** | **Impostazioni**
- Pulsante "panic" per stop live in evidenza
- Indicatore ON-AIR rosso lampeggiante quando in diretta
- Tema RadioKit: accent rosso broadcast, dark-first

---

## File da generare

- `radiokit-app-regia/design/` — mockup, wireframe, asset (in arrivo)
- `radiokit-app-regia/api-spec.md` — spec endpoint dettagliata
- `radiokit-app-regia/flutter/` — codice app (futuro)
