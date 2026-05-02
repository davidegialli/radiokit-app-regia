# RadioKit Regia — Flutter App

App mobile (Android + iOS) per controllo regia radio web/digitale da remoto.
Servizio aggiuntivo a pagamento, attivato con chiave `RKR-XXXX-XXXX-XXXX`.
Richiede almeno un bridge Timer o Diretta installato sul PC studio.

## Stack

- Flutter 3.22+ / Dart 3.4+
- **GetX** state management + DI + routing
- **GetStorage** preferenze locali (chiave, JWT, lingua)
- **Dio** REST + **web_socket_channel** WSS
- **OneSignal** push
- **i18n IT/EN/FR/ES** con `Translations` di GetX

## Struttura

```
lib/
├── main.dart                       boot + theme + locale + routes
├── core/
│   ├── constants/app_constants.dart
│   ├── theme/{app_colors, app_theme}.dart
│   ├── i18n/{translations, it_IT, en_US, fr_FR, es_ES}.dart
│   ├── services/{storage, api, ws}_service.dart
│   └── routing/{app_routes, app_pages, splash_page}.dart
├── data/
│   └── models/{regia_command, stream_launch}.dart
├── modules/
│   ├── activation/                 attivazione chiave RKR-
│   ├── home/                       dashboard (TODO)
│   ├── on_air/                     playout control (TODO)
│   ├── stream_url/                 ★ lancio diretta da URL — feature completa
│   ├── listeners/                  (TODO)
│   ├── library/                    (TODO)
│   ├── push/                       (TODO)
│   ├── history/                    (TODO)
│   └── account/                    profilo + lingua + logout
└── shared/widgets/                 RkCard, RkButton, RkSegRadio, RkToggle,
                                    RkPill, RkStatusChip, RkToast, RkFieldRow,
                                    PageHeader, AppShell
```

## Servizio + bridge

L'app è SOLO il client. Tutti i comandi passano per il VPS RadioKit:

```
[App Regia] ── HTTPS/WSS ──► [VPS] ──WSS──► [Timer]   ──► RadioBOSS desktop API
                                  └─WSS──► [Diretta] ──► RadioBOSS desktop API
```

Schema comandi condiviso: `lib/data/models/regia_command.dart` — quando estendiamo
Timer e Diretta per ricevere comandi dalla Regia, devono parsare lo stesso JSON shape.

Comandi definiti:
- `playlist.skip` / `playlist.next` / `playlist.insert_jingle` → **Timer**
- `live.start` / `live.stop` → **Diretta** o **Timer**
- `mic.mute` / `mic.volume` → **Diretta**
- `stream_url.start` / `stream_url.stop` / `stream_url.status` → **Timer**
- `monitor.status` → **Timer**
- `push.send` / `analytics.snapshot` → **VPS direct**

## i18n

Le traduzioni vivono in `lib/core/i18n/{lang}.dart` come `const Map<String, String>`.
Cambio lingua: `Get.updateLocale(Locale('en', 'US'))`. Persistito in GetStorage.

## Setup locale (per modifiche)

```bash
cd radiokit-app-regia/flutter
flutter pub get
flutter run
```

Nota: i font Geist non sono inclusi nel repo per licenza —
scaricarli da [vercel.com/font](https://vercel.com/font) e copiarli in `assets/fonts/`.

## Build (GitHub Actions)

La build avviene su GitHub Actions, **non in locale**.
Vedi `.github/workflows/build.yml` nella root del repo radiokit-app-regia.

Trigger:
- push su branch `main` → build Android debug + iOS test
- tag `v*.*.*` → build release Android (.aab) + iOS (.ipa) + draft release

Secrets richiesti nel repo GitHub:
- `ANDROID_KEYSTORE_BASE64` — keystore release codificato base64
- `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_PASSWORD` / `ANDROID_KEY_ALIAS`
- `APPLE_TEAM_ID` (`88FJK4AB7N`) / `APPLE_API_KEY_ID` / `APPLE_API_ISSUER_ID` / `APPLE_API_KEY_BASE64`
- `APP_STORE_CONNECT_KEY_BASE64` per upload TestFlight

## Roadmap moduli

| Modulo | Status |
|---|---|
| Activation (chiave RKR) | ✅ funzionale |
| Stream URL launch + titolo | ✅ funzionale |
| Theme dark broadcast console | ✅ |
| i18n IT/EN/FR/ES | ✅ scheletro completo |
| Home dashboard | ⏳ stub |
| On Air (skip/insert/playlist) | ⏳ stub |
| Listeners realtime | ⏳ stub |
| Library jingles | ⏳ stub |
| Push manager | ⏳ stub |
| History brani | ⏳ stub |
