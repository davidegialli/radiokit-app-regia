// Stream input — launch live broadcast from external stream URL with title
// The conductor points the regia to an icecast/shoutcast/HLS source
// (encoder personale, evento esterno, radio partner) and overrides metadata
// with program title + host name. RadioBOSS picks it up via `playurl`.

function ScreenStream({ state, dispatch, accent }) {
  const [streaming, setStreaming] = React.useState(false);
  const [url, setUrl] = React.useState('https://encoder.miosito.com:8000/live');
  const [title, setTitle] = React.useState('Notte Italiana');
  const [host, setHost] = React.useState('Davide Gialli');
  const [duration, setDuration] = React.useState('120'); // minuti, '0' = manuale
  const [startMode, setStartMode] = React.useState('endtrack'); // now | endtrack | fade
  const [autoFallback, setAutoFallback] = React.useState(true);

  // Source metadata read from URL probe (read-only)
  const [srcCodec, setSrcCodec] = React.useState('—');
  const [srcBitrate, setSrcBitrate] = React.useState('—');
  const [srcHealth, setSrcHealth] = React.useState('idle'); // idle | probing | ok | buffering | down
  const [elapsed, setElapsed] = React.useState(0);
  const [bytesRcv, setBytesRcv] = React.useState(0);

  const validUrl = /^https?:\/\/[^\s]+/i.test(url.trim());
  const canStart = validUrl && title.trim().length > 0 && !streaming;

  // Tick stream timer + telemetry
  React.useEffect(() => {
    if (!streaming) {
      setElapsed(0);
      setBytesRcv(0);
      return;
    }
    const id = setInterval(() => {
      setElapsed(e => e + 1);
      setBytesRcv(b => b + Math.round(15000 + Math.random() * 2000));
      // Simulate occasional buffering blips
      const blip = Math.random();
      if (blip > 0.97) setSrcHealth('buffering');
      else setSrcHealth('ok');
    }, 1000);
    return () => clearInterval(id);
  }, [streaming]);

  // Auto-stop when planned duration elapses
  React.useEffect(() => {
    if (!streaming || duration === '0') return;
    const max = parseInt(duration, 10) * 60;
    if (elapsed >= max) stopStream();
  }, [elapsed, streaming, duration]);

  const fmtElapsed = (s) => {
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    const ss = s % 60;
    return `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}:${String(ss).padStart(2,'0')}`;
  };

  const fmtBytes = (b) => {
    if (b < 1024) return b + ' B';
    if (b < 1024 * 1024) return (b / 1024).toFixed(1) + ' KB';
    return (b / 1024 / 1024).toFixed(2) + ' MB';
  };

  const startStream = () => {
    if (!canStart) return;
    setSrcHealth('probing');
    // Mock probe → resolves source metadata
    setTimeout(() => {
      setSrcCodec('MP3');
      setSrcBitrate('128 kbps');
      setSrcHealth('ok');
      setStreaming(true);
    }, 600);
  };
  const stopStream = () => {
    setStreaming(false);
    setSrcHealth('idle');
  };

  return (
    <div style={{ overflowY: 'auto', height: '100%' }} className="scroll">
      <div style={{ padding: '14px 16px 24px', display: 'flex', flexDirection: 'column', gap: 14 }}>

        {/* HERO — broadcast halo, status, title preview */}
        <div style={{
          background: streaming
            ? `radial-gradient(120% 100% at 50% 0%, oklch(from ${accent} l c h / 0.18) 0%, var(--surface) 55%, var(--bg-elev) 100%)`
            : `linear-gradient(180deg, var(--surface) 0%, var(--bg-elev) 100%)`,
          border: `1px solid ${streaming ? 'oklch(from ' + accent + ' l c h / 0.4)' : 'var(--hairline-soft)'}`,
          borderRadius: 14,
          padding: '20px 16px 18px',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14,
          transition: 'all 320ms ease',
        }}>
          {/* Status chip */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '4px 10px', borderRadius: 4,
            background: streaming ? accent : 'var(--surface-2)',
            color: streaming ? '#fff' : 'var(--text-3)',
            fontFamily: "'Geist Mono', ui-monospace, monospace",
            fontSize: 9, letterSpacing: 0.15, fontWeight: 600,
          }}>
            <span style={{
              width: 5, height: 5, borderRadius: '50%',
              background: streaming ? '#fff' : 'var(--text-3)',
              animation: streaming ? 'dot-pulse 1.2s ease-in-out infinite' : 'none',
            }}/>
            {streaming ? 'IN ONDA · STREAM ESTERNO' : 'PRONTO · NON IN ONDA'}
          </div>

          {/* Big circular broadcast disc with halo */}
          <BroadcastHalo streaming={streaming} health={srcHealth} accent={accent}/>

          {/* Title preview */}
          <div style={{ textAlign: 'center', minHeight: 60 }}>
            <div style={{ fontSize: 18, fontWeight: 600, letterSpacing: -0.01 }}>
              {streaming ? title : 'Lancio diretta da URL'}
            </div>
            <div style={{ fontSize: 11, color: 'var(--text-3)', marginTop: 4, lineHeight: 1.4 }}>
              {streaming
                ? `Conduce ${host} · metadata in onda`
                : 'Punta la regia a uno stream esterno (icecast/shoutcast/HLS) e imposta il titolo del programma.'}
            </div>
          </div>

          {/* Primary CTA */}
          {!streaming ? (
            <Btn
              variant="accent"
              size="lg"
              style={{ width: '100%', justifyContent: 'center', opacity: canStart ? 1 : 0.5 }}
              onClick={startStream}
              disabled={!canStart}
            >
              <Icon name="signal" size={18}/>
              {srcHealth === 'probing' ? 'Verifica sorgente…' : 'Vai in onda'}
            </Btn>
          ) : (
            <Btn variant="accent" size="lg" style={{ width: '100%', justifyContent: 'center' }} onClick={stopStream}>
              <Icon name="close" size={16}/>
              Stop diretta
            </Btn>
          )}
        </div>

        {/* Live telemetry — when streaming */}
        {streaming && (
          <Card padded>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <div className="eyebrow-strong">Telemetria live</div>
              <span className="mono" style={{ fontSize: 10, color: accent, fontWeight: 600 }}>
                {fmtElapsed(elapsed)}
              </span>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
              <TelemTile
                label="Sorgente"
                value={srcHealth === 'ok' ? 'OK' : srcHealth === 'buffering' ? 'BUF' : 'DOWN'}
                unit={srcCodec}
                good={srcHealth === 'ok'}
                warn={srcHealth === 'buffering'}
              />
              <TelemTile label="Bitrate" value={srcBitrate.replace(' kbps','')} unit="kbps"/>
              <TelemTile label="Ricevuto" value={fmtBytes(bytesRcv)} unit="tot"/>
            </div>
            {duration !== '0' && (
              <div style={{ marginTop: 12, paddingTop: 12, borderTop: '1px solid var(--hairline-soft)' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
                  <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)' }}>DURATA PIANIFICATA</span>
                  <span className="mono" style={{ fontSize: 10, color: 'var(--text-2)' }}>
                    {fmtElapsed(elapsed)} / {duration}m
                  </span>
                </div>
                <DurationBar progress={Math.min(1, elapsed / (parseInt(duration,10) * 60))} accent={accent}/>
              </div>
            )}
          </Card>
        )}

        {/* Sorgente — input URL + titolo + conduttore */}
        <Card padded>
          <div className="eyebrow-strong" style={{ marginBottom: 12 }}>Sorgente stream</div>

          <FieldRow label="URL stream" hint="https:// o http:// — icecast, shoutcast, HLS">
            <input
              type="url"
              value={url}
              onChange={e => setUrl(e.target.value)}
              disabled={streaming}
              placeholder="https://encoder.miosito.com:8000/live"
              style={inputStyle(validUrl || !url, streaming)}
            />
          </FieldRow>

          <div className="divider" style={{ margin: '12px 0' }}/>

          <FieldRow label="Titolo programma" hint="Mostrato come metadata in onda">
            <input
              type="text"
              value={title}
              onChange={e => setTitle(e.target.value)}
              disabled={streaming}
              maxLength={60}
              placeholder="Es. Notte Italiana"
              style={inputStyle(true, streaming)}
            />
          </FieldRow>

          <div className="divider" style={{ margin: '12px 0' }}/>

          <FieldRow label="Conduttore" hint="Opzionale — appare come artista RDS">
            <input
              type="text"
              value={host}
              onChange={e => setHost(e.target.value)}
              disabled={streaming}
              maxLength={40}
              placeholder="Nome conduttore"
              style={inputStyle(true, streaming)}
            />
          </FieldRow>

          <div className="divider" style={{ margin: '12px 0' }}/>

          <SettingRow
            label="Modalità avvio"
            hint={
              startMode === 'now'      ? 'Taglia il brano corrente · stacco netto' :
              startMode === 'endtrack' ? 'Aspetta la fine del brano corrente' :
                                         'Cross-fade graduale 4s sul brano corrente'
            }
          >
            <SegRadio
              value={startMode}
              options={[
                { value: 'now',      label: 'Subito'     },
                { value: 'endtrack', label: 'Fine brano' },
                { value: 'fade',     label: 'Cross-fade' },
              ]}
              onChange={setStartMode}
              accent={accent}
              disabled={streaming}
            />
          </SettingRow>

          <div className="divider" style={{ margin: '12px 0' }}/>

          <SettingRow label="Durata stimata" hint={duration === '0' ? 'Manuale · stop tu' : `Auto-stop dopo ${duration} minuti`}>
            <SegRadio
              value={duration}
              options={[
                { value: '30',  label: '30m' },
                { value: '60',  label: '1h'  },
                { value: '120', label: '2h'  },
                { value: '240', label: '4h'  },
                { value: '0',   label: '∞'   },
              ]}
              onChange={setDuration}
              accent={accent}
              disabled={streaming}
            />
          </SettingRow>

          <div className="divider" style={{ margin: '12px 0' }}/>

          <SettingRow label="Fallback automatico" hint="Se sorgente cade >10s → ritorno ad AutoDJ + push alert">
            <ToggleSwitch on={autoFallback} onChange={setAutoFallback} accent={accent}/>
          </SettingRow>
        </Card>

        {/* Routing — where this audio goes */}
        <Card padded>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
            <div className="eyebrow-strong">Routing in RadioBOSS</div>
            <Pill icon="signal" color={accent} bg={`oklch(from ${accent} l c h / 0.15)`}>PLAYURL</Pill>
          </div>

          <RouteHop label="URL sorgente" sub={shortUrl(url)} icon="signal" active={streaming} accent={accent}/>
          <RouteLine streaming={streaming} accent={accent}/>
          <RouteHop label="VPS RadioKit" sub="Watchdog · auto-fallback se cade" icon="signal" active={streaming} accent={accent}/>
          <RouteLine streaming={streaming} accent={accent}/>
          <RouteHop label="RadioBOSS" sub={`playurl · titolo: "${title || '—'}"`} icon="library" active={streaming} accent={accent} last/>

          <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', marginTop: 12, paddingTop: 10, borderTop: '1px solid var(--hairline-soft)', textAlign: 'center', letterSpacing: 0.1 }}>
            ◆ I metadata in onda vengono sostituiti con titolo + conduttore
          </div>
        </Card>

        {/* Recent launches */}
        <Card padded>
          <div className="eyebrow-strong" style={{ marginBottom: 10 }}>Lanci recenti</div>
          <LaunchRow t="22:14" dur="00:18:42" title="Drive Time" host="Federico R." ok/>
          <div className="divider"/>
          <LaunchRow t="ieri" dur="01:02:11" title="Notte Italiana" host="Davide Gialli" ok/>
          <div className="divider"/>
          <LaunchRow t="ieri" dur="00:04:09" title="Eventi LIVE" host="evento esterno" warn="sorgente cadde · fallback"/>
          <div className="divider"/>
          <LaunchRow t="lun" dur="00:42:18" title="Mattina RK" host="Sara Bonetti" ok/>
        </Card>

      </div>
    </div>
  );
}

function shortUrl(u) {
  try {
    const x = new URL(u);
    return x.host + (x.pathname.length > 1 ? x.pathname : '');
  } catch { return u || '—'; }
}

function inputStyle(valid, disabled) {
  return {
    width: '100%',
    padding: '8px 10px',
    background: 'var(--bg)',
    border: '1px solid ' + (valid ? 'var(--hairline-soft)' : 'oklch(0.68 0.22 28)'),
    borderRadius: 6,
    color: 'var(--text)',
    fontFamily: "'Geist Mono', ui-monospace, monospace",
    fontSize: 12,
    outline: 'none',
    opacity: disabled ? 0.55 : 1,
  };
}

// ───────── BroadcastHalo: big disc with concentric pulse rings ─────────
function BroadcastHalo({ streaming, health, accent }) {
  const size = 132;
  const ringScale = streaming ? 1.25 : 1;
  const ringOpacity = streaming ? 0.55 : 0;

  return (
    <div style={{
      position: 'relative',
      width: size, height: size,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      {/* Outer pulse ring */}
      <div style={{
        position: 'absolute', inset: 0,
        borderRadius: '50%',
        border: `1.5px solid ${accent}`,
        opacity: ringOpacity * 0.4,
        transform: `scale(${ringScale * 1.15})`,
        animation: streaming ? 'dot-pulse 1.6s ease-in-out infinite' : 'none',
      }}/>
      {/* Mid ring */}
      <div style={{
        position: 'absolute', inset: 0,
        borderRadius: '50%',
        border: `1.5px solid ${accent}`,
        opacity: ringOpacity * 0.7,
        transform: `scale(${ringScale * 1.05})`,
        animation: streaming ? 'dot-pulse 1.6s ease-in-out infinite 0.3s' : 'none',
      }}/>

      {/* Solid broadcast disc */}
      <div style={{
        width: 96, height: 96,
        borderRadius: '50%',
        background: streaming
          ? `radial-gradient(circle at 30% 25%, oklch(from ${accent} calc(l + 0.08) c h) 0%, ${accent} 70%, oklch(from ${accent} calc(l - 0.12) c h) 100%)`
          : 'linear-gradient(160deg, var(--surface-2) 0%, var(--surface) 100%)',
        border: streaming ? 'none' : '1px solid var(--hairline)',
        boxShadow: streaming
          ? `0 0 32px oklch(from ${accent} l c h / 0.45), inset 0 1px 0 oklch(from ${accent} calc(l + 0.15) c h / 0.5)`
          : 'inset 0 1px 0 oklch(0.3 0 0)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative',
        transition: 'all 280ms ease',
      }}>
        <Icon
          name="signal"
          size={42}
          color={streaming ? '#fff' : 'var(--text-2)'}
        />
        {streaming && health === 'buffering' && (
          <div style={{
            position: 'absolute', bottom: -2, right: -2,
            width: 22, height: 22, borderRadius: '50%',
            background: 'var(--warn)',
            border: '2px solid var(--bg-elev)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 9, fontWeight: 700, color: '#000',
          }}>!</div>
        )}
      </div>
    </div>
  );
}

// ───────── Duration progress bar ─────────
function DurationBar({ progress, accent }) {
  return (
    <div style={{
      height: 6, background: 'var(--surface-2)', borderRadius: 3, overflow: 'hidden', position: 'relative',
    }}>
      <div style={{
        position: 'absolute', inset: 0,
        width: `${progress * 100}%`,
        background: `linear-gradient(90deg, ${accent} 0%, oklch(from ${accent} calc(l + 0.05) c h) 100%)`,
        transition: 'width 800ms linear',
      }}/>
    </div>
  );
}

// ───────── Field row (label + input) ─────────
function FieldRow({ label, hint, children }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <div style={{ fontSize: 13, fontWeight: 500 }}>{label}</div>
      {children}
      {hint && (
        <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: 0.05 }}>
          {hint}
        </div>
      )}
    </div>
  );
}

// ───────── Setting row (label + control) ─────────
function SettingRow({ label, hint, children }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 500 }}>{label}</div>
        {hint && (
          <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', marginTop: 2, letterSpacing: 0.05 }}>
            {hint}
          </div>
        )}
      </div>
      <div style={{ flexShrink: 0 }}>{children}</div>
    </div>
  );
}

// ───────── Segmented radio ─────────
function SegRadio({ value, options, onChange, accent, disabled }) {
  return (
    <div style={{
      display: 'inline-flex',
      padding: 2,
      background: 'var(--bg)',
      border: '1px solid var(--hairline-soft)',
      borderRadius: 6,
      opacity: disabled ? 0.5 : 1,
      pointerEvents: disabled ? 'none' : 'auto',
    }}>
      {options.map(o => (
        <button key={o.value} onClick={() => onChange(o.value)} style={{
          padding: '5px 9px',
          borderRadius: 4, border: 0,
          background: value === o.value ? accent : 'transparent',
          color: value === o.value ? '#fff' : 'var(--text-2)',
          fontSize: 11,
          fontFamily: "'Geist Mono', ui-monospace, monospace",
          fontWeight: 500, letterSpacing: 0.05,
          cursor: 'pointer',
          transition: 'all 140ms ease',
        }}>{o.label}</button>
      ))}
    </div>
  );
}

// ───────── Toggle switch ─────────
function ToggleSwitch({ on, onChange, accent }) {
  return (
    <button onClick={() => onChange(!on)} style={{
      width: 40, height: 22, borderRadius: 11,
      background: on ? accent : 'var(--surface-2)',
      border: '1px solid ' + (on ? 'transparent' : 'var(--hairline)'),
      padding: 0, cursor: 'pointer', position: 'relative',
      transition: 'background 180ms ease',
    }}>
      <div style={{
        position: 'absolute', top: 2, left: on ? 20 : 2,
        width: 16, height: 16, borderRadius: '50%',
        background: '#fff',
        transition: 'left 180ms ease',
        boxShadow: '0 1px 2px rgba(0,0,0,0.4)',
      }}/>
    </button>
  );
}

// ───────── Telemetry tile ─────────
function TelemTile({ label, value, unit, good, warn }) {
  const valColor = good ? 'var(--autodj)' : warn ? 'var(--warn)' : 'var(--text)';
  return (
    <div style={{
      padding: 10,
      background: 'var(--bg)',
      border: '1px solid var(--hairline-soft)',
      borderRadius: 6,
    }}>
      <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: 0.1, marginBottom: 4 }}>
        {label.toUpperCase()}
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
        <span className="mono" style={{ fontSize: 18, fontWeight: 600, color: valColor, letterSpacing: -0.01 }}>
          {value}
        </span>
        <span className="mono" style={{ fontSize: 9, color: 'var(--text-3)' }}>{unit}</span>
      </div>
    </div>
  );
}

// ───────── Routing hop ─────────
function RouteHop({ label, sub, icon, active, accent, last }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <div style={{
        width: 36, height: 36, borderRadius: 8,
        background: active ? `oklch(from ${accent} l c h / 0.18)` : 'var(--bg)',
        border: '1px solid ' + (active ? `oklch(from ${accent} l c h / 0.4)` : 'var(--hairline-soft)'),
        color: active ? accent : 'var(--text-3)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
        transition: 'all 240ms ease',
      }}>
        <Icon name={icon} size={18}/>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 500 }}>{label}</div>
        <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: 0.05, marginTop: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {sub}
        </div>
      </div>
      {active && (
        <div style={{
          width: 6, height: 6, borderRadius: '50%',
          background: accent,
          animation: 'dot-pulse 1.4s ease-in-out infinite',
        }}/>
      )}
    </div>
  );
}

function RouteLine({ streaming, accent }) {
  return (
    <div style={{ paddingLeft: 18, height: 18, display: 'flex', alignItems: 'center' }}>
      <div style={{
        width: 1, height: '100%',
        background: streaming
          ? `linear-gradient(180deg, ${accent} 0%, oklch(from ${accent} l c h / 0.3) 100%)`
          : 'var(--hairline)',
        position: 'relative',
        overflow: 'visible',
      }}>
        {streaming && (
          <div style={{
            position: 'absolute', left: -1, top: 0,
            width: 3, height: 6,
            background: accent,
            borderRadius: 1,
            animation: 'flow-down 1.2s linear infinite',
          }}/>
        )}
      </div>
    </div>
  );
}

// ───────── Launch row ─────────
function LaunchRow({ t, dur, title, host, ok, warn }) {
  return (
    <div style={{ padding: '10px 0', display: 'flex', alignItems: 'center', gap: 10 }}>
      <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', width: 36, flexShrink: 0 }}>{t}</span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 12, fontWeight: 500, marginBottom: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{title}</div>
        <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: 0.05 }}>
          {dur} · {host} {warn ? '· ' + warn : ''}
        </div>
      </div>
      <span className="mono" style={{
        fontSize: 9,
        color: ok ? 'var(--autodj)' : 'var(--warn)',
        textTransform: 'uppercase', letterSpacing: 0.1,
      }}>
        {ok ? 'OK' : 'warn'}
      </span>
    </div>
  );
}

window.ScreenStream = ScreenStream;
