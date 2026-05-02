// Now Playing screens — Classica & Sperimentale variants

const { useState: useStateNP, useEffect: useEffectNP } = React;

// ───────── Track row (queue) ─────────
function QueueRow({ track, idx, isUp, accent, onSkip, dragging }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '8px 4px',
      borderRadius: 6,
      background: dragging ? 'var(--surface-2)' : 'transparent',
      transition: 'all 280ms cubic-bezier(0.5, 0.1, 0.2, 1)',
    }}>
      <div className="mono" style={{
        width: 22, fontSize: 11, color: isUp ? accent : 'var(--text-3)',
        fontWeight: isUp ? 600 : 400,
      }}>{String(idx + 1).padStart(2, '0')}</div>
      <CoverPlaceholder size={36} label="" tone={track.cover} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{track.title}</div>
        <div style={{ fontSize: 11, color: 'var(--text-3)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{track.artist}</div>
      </div>
      <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)' }}>{track.dur}</span>
    </div>
  );
}

// ───────── Now Playing — Classica (cover dominante) ─────────
function NowPlayingClassic({ state, dispatch, accent }) {
  const { current, queue, position, duration, live } = state;
  const remaining = duration - position;
  const fmt = (s) => {
    const m = Math.floor(s / 60), x = s % 60;
    return `${m}:${String(x).padStart(2, '0')}`;
  };
  return (
    <div style={{ padding: '14px 16px 20px', display: 'flex', flexDirection: 'column', gap: 16 }}>
      {/* Cover + meta */}
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
        <div style={{ flexShrink: 0, position: 'relative' }}>
          <CoverPlaceholder size={130} label="ALBUM ART" tone={current.cover} />
          <div style={{
            position: 'absolute', top: 8, left: 8,
          }}>
            <OnAirChip live={live} />
          </div>
        </div>
        <div style={{ flex: 1, minWidth: 0, paddingTop: 4 }}>
          <div className="eyebrow" style={{ marginBottom: 6 }}>Now Playing · {live ? 'Live show' : 'AutoDJ'}</div>
          <div style={{ fontSize: 18, fontWeight: 600, lineHeight: 1.15, marginBottom: 4, letterSpacing: -0.01 }}>{current.title}</div>
          <div style={{ fontSize: 13, color: 'var(--text-2)', marginBottom: 8 }}>{current.artist}</div>
          <div style={{ fontSize: 11, color: 'var(--text-3)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{current.album}</div>
          <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
            <Pill icon="signal">128 KBPS</Pill>
            <Pill>−4.2 DB</Pill>
          </div>
        </div>
      </div>

      {/* Waveform */}
      <div>
        <Waveform color={accent} live={true} playhead={position / duration} height={56} />
        <div style={{
          display: 'flex', justifyContent: 'space-between',
          marginTop: 6,
          fontFamily: "'Geist Mono', ui-monospace, monospace",
          fontSize: 10, color: 'var(--text-3)',
        }}>
          <span>{fmt(position)}</span>
          <span style={{ color: accent }}>−{fmt(remaining)}</span>
        </div>
      </div>

      {/* Transport */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
        <Btn variant="ghost" size="sm" onClick={() => dispatch({ type: 'jingle-open' })}>
          <Icon name="jingle" size={16}/>
          Insert jingle
        </Btn>
        <div style={{ display: 'flex', gap: 6 }}>
          <button className="press" style={iconBtn(44)}>
            <Icon name="prev" size={20} color="var(--text-2)"/>
          </button>
          <button className="press" style={{ ...iconBtn(56), background: accent, border: 'none' }}>
            <Icon name="pause" size={22} color="#fff"/>
          </button>
          <button className="press" onClick={() => dispatch({ type: 'skip' })} style={iconBtn(44)}>
            <Icon name="skip" size={20} color="var(--text-2)"/>
          </button>
        </div>
        <Btn variant="ghost" size="sm" onClick={() => dispatch({ type: 'tab', tab: 'live' })}>
          <Icon name="users" size={16}/>
          <span className="mono">{state.listenerCount.toLocaleString('it-IT')}</span>
        </Btn>
      </div>

      <div className="divider"/>

      {/* Queue */}
      <div>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
          <div className="eyebrow-strong">Coda · prossimi {queue.length}</div>
          <Btn variant="ghost" size="sm">
            <Icon name="list" size={14}/>
            Riordina
          </Btn>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {queue.slice(0, 5).map((t, i) => (
            <QueueRow key={t.id} track={t} idx={i} isUp={i === 0} accent={accent} />
          ))}
        </div>
      </div>
    </div>
  );
}

// ───────── Now Playing — Sperimentale (waveform fullbleed) ─────────
function NowPlayingExperimental({ state, dispatch, accent }) {
  const { current, queue, position, duration, live } = state;
  const fmt = (s) => {
    const m = Math.floor(s / 60), x = s % 60;
    return `${m}:${String(x).padStart(2, '0')}`;
  };
  return (
    <div style={{ display: 'flex', flexDirection: 'column' }}>
      {/* Hero — fullbleed cover with overlay */}
      <div style={{
        position: 'relative',
        height: 280,
        background: `repeating-linear-gradient(135deg, oklch(0.30 0.04 ${current.cover * 60 + 30}) 0 14px, oklch(0.18 0.02 260) 14px 28px)`,
        borderBottom: '1px solid var(--hairline)',
        overflow: 'hidden',
      }}>
        {/* Vignette */}
        <div style={{
          position: 'absolute', inset: 0,
          background: 'linear-gradient(180deg, rgba(0,0,0,0.35) 0%, rgba(0,0,0,0) 35%, rgba(0,0,0,0.85) 100%)',
        }} />
        {/* Top — chip + meta */}
        <div style={{
          position: 'absolute', top: 14, left: 16, right: 16,
          display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
        }}>
          <OnAirChip live={live} />
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(8px)',
            padding: '4px 8px', borderRadius: 4,
          }}>
            <EqBars color={accent} active={true} height={12} />
            <span className="mono" style={{ fontSize: 10, color: '#fff' }}>−4.2 dB</span>
          </div>
        </div>
        {/* Big "COVER" placeholder text */}
        <div style={{
          position: 'absolute', top: '40%', left: '50%', transform: 'translate(-50%, -50%)',
          fontFamily: "'Geist Mono', ui-monospace, monospace",
          color: 'rgba(255,255,255,0.25)', fontSize: 11, letterSpacing: 0.2,
        }}>ALBUM ART</div>
        {/* Bottom — title + waveform */}
        <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '0 16px 14px' }}>
          <div style={{ fontSize: 24, fontWeight: 700, lineHeight: 1.1, letterSpacing: -0.02, marginBottom: 4 }}>
            {current.title}
          </div>
          <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.7)', marginBottom: 10 }}>
            {current.artist} · {current.album}
          </div>
          <Waveform color={accent} live={true} playhead={position / duration} height={28} dense />
          <div style={{
            display: 'flex', justifyContent: 'space-between', marginTop: 4,
            fontFamily: "'Geist Mono', ui-monospace, monospace", fontSize: 10, color: 'rgba(255,255,255,0.6)',
          }}>
            <span>{fmt(position)}</span>
            <span style={{ color: accent }}>{fmt(duration)}</span>
          </div>
        </div>
      </div>

      {/* Transport row */}
      <div style={{
        display: 'grid', gridTemplateColumns: '1fr auto 1fr',
        gap: 8, padding: '14px 16px',
        borderBottom: '1px solid var(--hairline-soft)',
        alignItems: 'center',
      }}>
        <button className="press" onClick={() => dispatch({ type: 'jingle-open' })} style={{
          ...iconBtn(44), justifySelf: 'start',
          width: 56, borderRadius: 8,
          background: 'var(--accent-soft)',
          border: '1px solid oklch(0.66 0.22 25 / 0.5)',
          color: 'var(--accent)',
          flexDirection: 'column', gap: 2,
        }}>
          <Icon name="jingle" size={18}/>
          <span style={{ fontSize: 8, fontFamily: "'Geist Mono', ui-monospace, monospace", letterSpacing: 0.1 }}>JNG</span>
        </button>
        <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          <button className="press" style={iconBtn(44)}>
            <Icon name="prev" size={20} color="var(--text-2)"/>
          </button>
          <button className="press" style={{ ...iconBtn(60), background: accent, border: 'none' }}>
            <Icon name="pause" size={24} color="#fff"/>
          </button>
          <button className="press" onClick={() => dispatch({ type: 'skip' })} style={iconBtn(44)}>
            <Icon name="skip" size={20} color="var(--text-2)"/>
          </button>
        </div>
        <button className="press" onClick={() => dispatch({ type: 'tab', tab: 'live' })} style={{
          ...iconBtn(44), justifySelf: 'end',
          width: 56, borderRadius: 8,
          background: 'var(--surface-2)', border: '1px solid var(--hairline-soft)',
          flexDirection: 'column', gap: 2,
        }}>
          <Icon name="users" size={16} color="var(--text-2)"/>
          <span className="mono" style={{ fontSize: 9, color: 'var(--text-2)' }}>{state.listenerCount.toLocaleString('it-IT')}</span>
        </button>
      </div>

      {/* Queue (compact, scroll-y) */}
      <div style={{ padding: '12px 16px 20px' }}>
        <div className="eyebrow-strong" style={{ marginBottom: 10 }}>Coda · {queue.length} prossimi</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          {queue.slice(0, 6).map((t, i) => (
            <QueueRow key={t.id} track={t} idx={i} isUp={i === 0} accent={accent} />
          ))}
        </div>
      </div>
    </div>
  );
}

const iconBtn = (size) => ({
  width: size, height: size, borderRadius: '50%',
  background: 'var(--surface-2)', border: '1px solid var(--hairline-soft)',
  display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
  cursor: 'pointer',
  flexShrink: 0,
});

Object.assign(window, {
  NowPlayingClassic, NowPlayingExperimental, QueueRow,
});
