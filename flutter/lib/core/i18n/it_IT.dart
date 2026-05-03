// Italiano — lingua di default
const Map<String, String> itIT = {
  // Generali
  'app.name': 'RadioKit Regia',
  'common.cancel': 'Annulla',
  'common.confirm': 'Conferma',
  'common.save': 'Salva',
  'common.close': 'Chiudi',
  'common.back': 'Indietro',
  'common.retry': 'Riprova',
  'common.loading': 'Caricamento…',
  'common.ok': 'OK',
  'common.error': 'Errore',
  'common.optional': 'Opzionale',

  // Tab bar
  'tab.home': 'Home',
  'tab.onAir': 'On Air',
  'tab.stream': 'Stream',
  'tab.listeners': 'Listener',
  'tab.library': 'Libreria',
  'tab.push': 'Push',
  'tab.history': 'Storico',
  'tab.account': 'Account',

  // Header eyebrow
  'header.regia': 'REGIA',
  'header.live': 'LIVE',
  'header.autodj': 'AUTODJ',

  // Activation
  'activation.title': 'Attiva RadioKit Regia',
  'activation.subtitle': 'Inserisci la chiave ricevuta via email',
  'activation.keyLabel': 'Chiave licenza',
  'activation.keyHint': 'Formato RKR-XXXX-XXXX-XXXX',
  'activation.activate': 'Attiva',
  'activation.invalidKey': 'Chiave non valida',
  'activation.noBridge': 'Nessun bridge attivo. Avvia Timer o Diretta sul PC studio.',
  'activation.bridgeFound': 'Bridge rilevato',

  // Home / Dashboard
  'home.statusOnAir': 'IN ONDA',
  'home.statusAutoDj': 'AUTODJ',
  'home.listenersNow': 'Listener ora',
  'home.bridgeStatus': 'Bridge studio',

  // On Air
  'onair.skip': 'Skip',
  'onair.insertJingle': 'Inserisci jingle',
  'onair.queue': 'Coda',
  'onair.nowPlaying': 'In riproduzione',

  // Lingua (selettore in attivazione)
  'language.title': 'Lingua',
  'language.choose': 'Scegli la lingua',

  // Stream URL — stati app (single source of truth)
  'stream.state.unknown':   'Connessione…',
  'stream.state.offline':   'Studio non connesso',
  'stream.state.idle':      'Pronto per andare in onda',
  'stream.state.requested': 'Richiesta inviata…',
  'stream.state.scheduled': 'In attesa fine brano',
  'stream.state.live':      'In onda',
  'stream.state.error':     'Errore sorgente',
  'stream.state.offlineHint':   'Avvia Timer o Diretta sul PC studio',
  'stream.state.idleHint':      'Compila i campi e tap "Vai in onda"',
  'stream.state.requestedHint': 'Studio sta ricevendo il comando',
  'stream.state.scheduledHint': 'Lo stream parte appena finisce il brano corrente',
  'stream.state.liveHint':      'Stream esterno in onda — metadata sostituiti',

  'stream.now.title':   'In onda ORA',
  'stream.now.empty':   'Nessuna traccia',
  'stream.now.bridgeAge': 'aggiornato @sec s fa',
  'stream.now.listeners': '@n ascoltatori',
  'stream.now.relayOn':  '· relay attivo',

  'stream.toast.live':   'Diretta avviata: @title',
  'stream.toast.stopped':'Diretta terminata',
  'stream.toast.failed': 'Impossibile avviare la diretta',

  'stream.title': 'Lancio diretta da URL',
  'stream.subtitle': 'Punta la regia a uno stream esterno (icecast/shoutcast/HLS) e imposta il titolo del programma.',
  'stream.urlLabel': 'URL stream',
  'stream.urlHint': 'https:// o http:// — icecast, shoutcast, HLS',
  'stream.titleLabel': 'Titolo programma',
  'stream.titleHint': 'Mostrato come metadata in onda',
  'stream.hostLabel': 'Conduttore',
  'stream.hostHint': 'Opzionale — appare come artista RDS',
  'stream.startMode': 'Modalità avvio',
  'stream.startModeNow': 'Subito',
  'stream.startModeNowHint': 'Taglia il brano corrente · stacco netto',
  'stream.startModeEnd': 'Fine brano',
  'stream.startModeEndHint': 'Aspetta la fine del brano corrente',
  'stream.startModeFade': 'Cross-fade',
  'stream.startModeFadeHint': 'Cross-fade graduale 4s sul brano corrente',
  'stream.duration': 'Durata stimata',
  'stream.durationManual': 'Manuale · stop tu',
  'stream.durationAuto': 'Auto-stop dopo @min minuti',
  'stream.fallback': 'Fallback automatico',
  'stream.fallbackHint': 'Se sorgente cade >10s → ritorno ad AutoDJ + push alert',
  'stream.cta.go': 'Vai in onda',
  'stream.cta.probing': 'Verifica sorgente…',
  'stream.cta.stop': 'Stop diretta',
  'stream.status.ready': 'PRONTO · NON IN ONDA',
  'stream.status.live': 'IN ONDA · STREAM ESTERNO',
  'stream.health.ok': 'OK',
  'stream.health.buffering': 'BUF',
  'stream.health.down': 'DOWN',
  'stream.telem.title': 'Telemetria live',
  'stream.telem.source': 'Sorgente',
  'stream.telem.bitrate': 'Bitrate',
  'stream.telem.received': 'Ricevuto',
  'stream.telem.duration': 'Durata pianificata',
  'stream.routing.title': 'Routing in RadioBOSS',
  'stream.routing.urlSource': 'URL sorgente',
  'stream.routing.vps': 'VPS RadioKit',
  'stream.routing.vpsSub': 'Watchdog · auto-fallback se cade',
  'stream.routing.radioboss': 'RadioBOSS',
  'stream.routing.radiobossSub': 'playurl · titolo: "@title"',
  'stream.routing.note': '◆ I metadata in onda vengono sostituiti con titolo + conduttore',
  'stream.recent': 'Lanci recenti',

  // Listeners
  'listeners.title': 'Listener live',

  // Library
  'library.title': 'Libreria',

  // Push
  'push.title': 'Notifiche push',
  'push.send': 'Invia',
  'push.sent': 'Inviata a @count device',

  // Account
  'account.title': 'Account',
  'account.language': 'Lingua',
  'account.license': 'Licenza',
  'account.logout': 'Esci',

  // Errors
  'error.network': 'Connessione non disponibile',
  'error.invalidUrl': 'URL non valido',
  'error.titleRequired': 'Titolo programma obbligatorio',
};
