// Android device frame — dark broadcast variant
// Custom version for RadioKit Regia console.

function AndroidStatusBarDark({ accent = 'oklch(0.66 0.22 25)', onAir = false }) {
  return (
    <div style={{
      height: 32, display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', padding: '0 18px 0 22px',
      position: 'relative',
      fontFamily: "'Geist Mono', ui-monospace, monospace",
      color: '#fff',
      fontSize: 13,
      fontWeight: 500,
      letterSpacing: 0.2,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <span>22:47</span>
        {onAir && (
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 5,
            color: accent, fontSize: 10, letterSpacing: 0.15,
            fontWeight: 600,
          }}>
            <span style={{
              width: 6, height: 6, borderRadius: '50%', background: accent,
              animation: 'dot-pulse 1.4s ease-in-out infinite',
            }} />
            ON AIR
          </span>
        )}
      </div>
      <div style={{
        position: 'absolute', left: '50%', top: 6, transform: 'translateX(-50%)',
        width: 18, height: 18, borderRadius: 100, background: '#000',
      }} />
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <svg width="14" height="10" viewBox="0 0 16 12" fill="none">
          <path d="M8 11.5c-3-2.5-6-3.8-8-3.8L8 0l8 7.7c-2 0-5 1.3-8 3.8z" fill="#fff"/>
        </svg>
        <svg width="14" height="14" viewBox="0 0 16 16" fill="#fff">
          <rect x="2" y="11" width="2" height="3" rx="0.5"/>
          <rect x="6" y="8" width="2" height="6" rx="0.5"/>
          <rect x="10" y="5" width="2" height="9" rx="0.5"/>
          <rect x="14" y="2" width="2" height="12" rx="0.5"/>
        </svg>
        <svg width="22" height="11" viewBox="0 0 24 12" fill="none">
          <rect x="0.5" y="1" width="20" height="10" rx="2" stroke="#fff" strokeOpacity="0.8" fill="none"/>
          <rect x="2" y="2.5" width="14" height="7" rx="1" fill="#fff"/>
          <rect x="21" y="4" width="2" height="4" rx="0.5" fill="#fff" fillOpacity="0.6"/>
        </svg>
      </div>
    </div>
  );
}

function AndroidNavBarDark() {
  return (
    <div style={{
      height: 22, display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0,
    }}>
      <div style={{
        width: 132, height: 4, borderRadius: 2,
        background: '#fff', opacity: 0.5,
      }} />
    </div>
  );
}

function AndroidDeviceDark({
  children, width = 412, height = 892,
  accent = 'oklch(0.66 0.22 25)', onAir = false,
  bezel = true,
}) {
  const radius = bezel ? 38 : 0;
  return (
    <div style={{
      width: bezel ? width : width,
      height: bezel ? height : height,
      borderRadius: radius,
      overflow: 'hidden',
      background: 'oklch(0.10 0.003 260)',
      border: bezel ? '10px solid #15161a' : 'none',
      boxShadow: bezel
        ? '0 0 0 1px rgba(255,255,255,0.04), 0 30px 80px rgba(0,0,0,0.55)'
        : 'none',
      display: 'flex', flexDirection: 'column', boxSizing: 'border-box',
      position: 'relative',
    }}>
      <AndroidStatusBarDark accent={accent} onAir={onAir} />
      <div style={{ flex: 1, overflow: 'hidden', position: 'relative', display: 'flex', flexDirection: 'column' }}>
        {children}
      </div>
      <AndroidNavBarDark />
    </div>
  );
}

Object.assign(window, {
  AndroidDeviceDark, AndroidStatusBarDark, AndroidNavBarDark,
});
