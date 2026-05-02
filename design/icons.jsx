// Icons — line-style 24x24 for broadcast UI
// Use as <Icon name="play" size={20} color="..." />

const ICON_PATHS = {
  play:    <path d="M8 5l11 7-11 7V5z" fill="currentColor" />,
  pause:   <g fill="currentColor"><rect x="6" y="5" width="4" height="14" rx="0.5"/><rect x="14" y="5" width="4" height="14" rx="0.5"/></g>,
  skip:    <g fill="currentColor"><path d="M5 5l9 7-9 7V5z"/><rect x="16" y="5" width="2.5" height="14" rx="0.5"/></g>,
  prev:    <g fill="currentColor"><path d="M19 5l-9 7 9 7V5z"/><rect x="5.5" y="5" width="2.5" height="14" rx="0.5"/></g>,
  jingle:  <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><path d="M5 14l3-1V6l11-3v11"/><circle cx="6.5" cy="14.5" r="2"/><circle cx="17.5" cy="14" r="2"/></g>,
  mic:     <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><rect x="9" y="3" width="6" height="11" rx="3" fill="currentColor"/><path d="M5 11a7 7 0 0014 0M12 18v3"/></g>,
  bell:    <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M5 17h14l-2-3v-4a5 5 0 00-10 0v4l-2 3z"/><path d="M10 20a2 2 0 004 0"/></g>,
  upload:  <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M12 4v12M7 9l5-5 5 5"/><path d="M4 17v2a2 2 0 002 2h12a2 2 0 002-2v-2"/></g>,
  home:    <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round"><path d="M4 11l8-7 8 7v9a1 1 0 01-1 1h-4v-6h-6v6H5a1 1 0 01-1-1v-9z"/></g>,
  users:   <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><circle cx="9" cy="8" r="3.5"/><path d="M3 20c0-3 2.7-5 6-5s6 2 6 5"/><circle cx="17" cy="9" r="2.5"/><path d="M15 20c0-2 1.5-4 4-4s2 1 2 1"/></g>,
  library: <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><rect x="3" y="4" width="14" height="16" rx="1.5"/><path d="M7 4v16M11 4v16M20 6v14"/></g>,
  account: <g fill="none" stroke="currentColor" strokeWidth="1.6"><circle cx="12" cy="8" r="3.5"/><path d="M5 20c0-4 3-6.5 7-6.5s7 2.5 7 6.5"/></g>,
  list:    <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><path d="M4 6h16M4 12h16M4 18h10"/></g>,
  more:    <g fill="currentColor"><circle cx="6" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="18" cy="12" r="1.5"/></g>,
  search:  <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><circle cx="11" cy="11" r="6"/><path d="M16 16l4 4"/></g>,
  back:    <g fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d="M15 5l-7 7 7 7"/></g>,
  close:   <g fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round"><path d="M6 6l12 12M18 6L6 18"/></g>,
  check:   <g fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12l5 5 9-10"/></g>,
  refresh: <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M20 12a8 8 0 11-2.3-5.6"/><path d="M20 4v4h-4"/></g>,
  filter:  <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M3 5h18l-7 9v6l-4-2v-4z"/></g>,
  settings:<g fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 00-.1-1.2l2-1.5-2-3.4-2.4.9a7 7 0 00-2-1.2L14 3h-4l-.5 2.6a7 7 0 00-2 1.2l-2.4-1-2 3.5 2 1.5A7 7 0 005 12c0 .4 0 .8.1 1.2l-2 1.5 2 3.4 2.4-.9a7 7 0 002 1.2L10 21h4l.5-2.6a7 7 0 002-1.2l2.4.9 2-3.4-2-1.5c.1-.4.1-.8.1-1.2z"/></g>,
  signal:  <g fill="currentColor"><rect x="3" y="14" width="3" height="6" rx="0.5"/><rect x="9" y="10" width="3" height="10" rx="0.5"/><rect x="15" y="6" width="3" height="14" rx="0.5"/></g>,
  alert:   <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M12 4l10 17H2L12 4z"/><path d="M12 10v5"/><circle cx="12" cy="18" r="0.7" fill="currentColor"/></g>,
  schedule:<g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><circle cx="12" cy="12" r="8"/><path d="M12 7v5l3 2"/></g>,
  drag:    <g fill="currentColor"><circle cx="9" cy="6" r="1.4"/><circle cx="15" cy="6" r="1.4"/><circle cx="9" cy="12" r="1.4"/><circle cx="15" cy="12" r="1.4"/><circle cx="9" cy="18" r="1.4"/><circle cx="15" cy="18" r="1.4"/></g>,
  trash:   <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M5 7h14M9 7V4h6v3M7 7l1 13h8l1-13"/></g>,
  eye:     <g fill="none" stroke="currentColor" strokeWidth="1.6"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/></g>,
  eye_off: <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><path d="M3 3l18 18"/><path d="M10.5 6.2A10.5 10.5 0 0112 6c6 0 10 6 10 6a17.6 17.6 0 01-3.3 3.9M6.5 6.5A18.5 18.5 0 002 12s4 6 10 6a10.6 10.6 0 003.5-.6"/><path d="M9.9 9.9a3 3 0 004.2 4.2"/></g>,
  music:   <g fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><path d="M9 18V6l11-2v12"/><circle cx="6" cy="18" r="3" fill="currentColor"/><circle cx="17" cy="16" r="3" fill="currentColor"/></g>,
  flame:   <path fill="currentColor" d="M12 2s4 4 4 8a4 4 0 01-1 2.7c1-.4 2-1.5 2-3.5 2 2 3 4.5 3 7a8 8 0 11-16 0c0-3 1.6-5.5 3-7 .2 1.5 1 2.5 2 3-1-2 3-7 3-10z"/>,
};

function Icon({ name, size = 22, color = 'currentColor', style }) {
  const d = ICON_PATHS[name];
  if (!d) return null;
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ color, flexShrink: 0, ...style }}>{d}</svg>
  );
}

window.Icon = Icon;
