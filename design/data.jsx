// Mock data for the regia app

const MOCK_TRACKS = [
  { id: 't1', title: 'Notte Senza Fine',     artist: 'Marlena Vox',         album: 'Aurora Negra',     dur: '3:52', cover: 0 },
  { id: 't2', title: 'Vetro & Marmo',        artist: 'Atelier 22',          album: 'Singolo',          dur: '4:18', cover: 1 },
  { id: 't3', title: 'Riviera Drive',        artist: 'Sole Negativo',       album: 'Capo Sud',         dur: '3:36', cover: 2 },
  { id: 't4', title: 'Monsone',              artist: 'Lina Costa',          album: 'Onde lunghe',      dur: '4:02', cover: 3 },
  { id: 't5', title: 'Codice Postale RK',    artist: 'Stereotipo',          album: 'Demo',             dur: '2:58', cover: 0 },
  { id: 't6', title: 'Antenna 2.7',          artist: 'Ferro Quattro',       album: 'Altoparlanti',     dur: '3:21', cover: 1 },
  { id: 't7', title: 'Notturno',             artist: 'Aria di Mezzo',       album: 'Giorni Bianchi',   dur: '5:11', cover: 2 },
  { id: 't8', title: 'Stato di Grazia',      artist: 'Il Pomeriggio',       album: 'Mano Aperta',      dur: '3:44', cover: 3 },
];

const MOCK_JINGLES = [
  { id: 'j1', name: 'Stinger RadioKit (corto)', dur: '0:04', tag: 'STING', uses: 142 },
  { id: 'j2', name: 'ID News Top of Hour',       dur: '0:08', tag: 'ID',    uses: 86  },
  { id: 'j3', name: 'Promo Concorso Estate',     dur: '0:22', tag: 'PROMO', uses: 23  },
  { id: 'j4', name: 'Bumper Caffè di Notte',     dur: '0:06', tag: 'BUMPER',uses: 51  },
  { id: 'j5', name: 'Sweeper Drive Time',        dur: '0:10', tag: 'SWEEP', uses: 38  },
  { id: 'j6', name: 'Sigla Meteo',               dur: '0:12', tag: 'METEO', uses: 0   },
];

const MOCK_PUSH = [
  { id: 'p1', title: 'Marlena Vox in diretta', body: 'Live ospite alle 23:00 — Notti su RadioKit', t: '22:32', sent: 1247, opens: 312, kind: 'live' },
  { id: 'p2', title: 'Concorso “Antenna d\'oro”', body: 'Iscrizioni aperte fino a venerdì', t: '18:15', sent: 4218, opens: 1108, kind: 'promo' },
  { id: 'p3', title: 'Allerta meteo',          body: 'Vento forte sulla costa — aggiornamento alle 19', t: '16:02', sent: 4200, opens: 2890, kind: 'alert' },
  { id: 'p4', title: 'Drive Time inizia ora',  body: 'Con Federico Ranieri', t: '17:00', sent: 3890, opens: 412, kind: 'live' },
];

const MOCK_SCHEDULE = [
  { time: '06:00', show: 'Sveglia RadioKit',     host: 'Lia Marconi',     live: false },
  { time: '09:00', show: 'Mattino Aperto',       host: 'Federico Ranieri',live: false },
  { time: '12:00', show: 'Pranzo & Musica',      host: 'AutoDJ',           live: false },
  { time: '15:00', show: 'Pomeriggio RK',        host: 'Sara Bonetti',    live: true,  current: true },
  { time: '18:00', show: 'Drive Time',           host: 'Federico Ranieri',live: false },
  { time: '21:00', show: 'Notti di RadioKit',   host: 'Marco D\'Amico',   live: false },
  { time: '00:00', show: 'AutoDJ Notte',         host: 'AutoDJ',           live: false },
];

const MOCK_HISTORY = [
  { time: '22:43', title: 'Vetro & Marmo',     artist: 'Atelier 22',     dur: '4:18' },
  { time: '22:39', title: 'Stinger RadioKit', artist: '— jingle —',     dur: '0:04', jingle: true },
  { time: '22:35', title: 'Riviera Drive',     artist: 'Sole Negativo',  dur: '3:36' },
  { time: '22:31', title: 'Monsone',           artist: 'Lina Costa',     dur: '4:02' },
  { time: '22:27', title: 'ID News Top',       artist: '— jingle —',     dur: '0:08', jingle: true },
  { time: '22:24', title: 'Codice Postale RK', artist: 'Stereotipo',     dur: '2:58' },
  { time: '22:21', title: 'Antenna 2.7',       artist: 'Ferro Quattro',  dur: '3:21' },
  { time: '22:18', title: 'Notturno',          artist: 'Aria di Mezzo',  dur: '5:11' },
];

// Listener line — 24 points, last 2 hours, slight uptrend with live event spike
const MOCK_LISTENERS = [
  812, 798, 805, 822, 841, 868, 902, 940,
  988, 1024, 1058, 1077, 1096, 1118, 1147, 1182,
  1205, 1219, 1228, 1234, 1238, 1244, 1247, 1247,
];

const MOCK_ALERTS = [
  { id: 'a1', t: '22:31', kind: 'spike',   text: 'Picco listener +12% in 4 minuti', sev: 'info' },
  { id: 'a2', t: '21:58', kind: 'drop',    text: 'Drop stream HQ — riprovato in 8s', sev: 'warn' },
  { id: 'a3', t: '20:14', kind: 'silence', text: 'Silenzio rilevato 3.2s', sev: 'error' },
];

window.MOCK = {
  TRACKS: MOCK_TRACKS,
  JINGLES: MOCK_JINGLES,
  PUSH: MOCK_PUSH,
  SCHEDULE: MOCK_SCHEDULE,
  HISTORY: MOCK_HISTORY,
  LISTENERS: MOCK_LISTENERS,
  ALERTS: MOCK_ALERTS,
};
