// Home dashboard, Listener live, Push log

// ───────── Home / Dashboard ─────────
function ScreenHome({ state, dispatch, accent }) {
  const { listenerCount, current, live } = state;
  const next = state.queue[0];
  const sched = MOCK.SCHEDULE.find(s => s.current);
  return (
    <div style={{ padding: '14px 16px 20px', display: 'flex', flexDirection: 'column', gap: 14 }}>
      {/* Greeting + Live status hero */}
      <div style={{
        background: `linear-gradient(180deg, var(--surface) 0%, var(--bg-elev) 100%)`,
        border: '1px solid var(--hairline-soft)',
        borderRadius: 12,
        padding: 14,
        display: 'flex', flexDirection: 'column', gap: 12,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div className="eyebrow" style={{ marginBottom: 2 }}>RadioKit · regia</div>
            <div style={{ fontSize: 18, fontWeight: 600 }}>Ciao, Sara</div>
          </div>
          <OnAirChip live={live} />
        </div>
        {/* On Air now strip */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          padding: 10,
          background: 'var(--bg)',
          border: '1px solid var(--hairline-soft)',
          borderRadius: 8,
        }}>
          <CoverPlaceholder size={48} tone={current.cover} label=""/>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="eyebrow" style={{ marginBottom: 2 }}>{sched ? sched.show : 'AutoDJ'}</div>
            <div style={{ fontSize: 13, fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{current.title}</div>
            <div style={{ fontSize: 11, color: 'var(--text-3)' }}>{current.artist}</div>
          </div>
          <EqBars color={accent} active={true} height={18}/>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <Btn variant="accent" size="md" style={{ flex: 1 }} onClick={() => dispatch({ type: 'tab', tab: 'now' })}>
            <Icon name="play" size={16}/>
            Apri regia
          </Btn>
          <Btn variant="ghost" size="md" onClick={() => dispatch({ type: 'jingle-open' })}>
            <Icon name="jingle" size={16}/>
            Jingle
          </Btn>
        </div>
      </div>

      {/* KPIs */}
      <div style={{ display: 'flex', gap: 8 }}>
        <Stat label="Live" value={listenerCount.toLocaleString('it-IT')} unit="ascolt." delta="+12%" color={accent}/>
        <Stat label="Picco oggi" value="1.412" unit="alle 18:34" />
        <Stat label="Push aperte" value="74%" delta="+8%" />
      </div>

      {/* Live/AutoDJ master toggle */}
      <Card padded>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
          <div>
            <div className="eyebrow" style={{ marginBottom: 2 }}>Modalità trasmissione</div>
            <div style={{ fontSize: 14, fontWeight: 500 }}>Diretta v2 ↔ RadioBOSS</div>
          </div>
          <Pill icon="signal">SYNCED</Pill>
        </div>
        <BigToggle live={live} onChange={(v) => dispatch({ type: 'toggle-live', live: v })} accent={accent}/>
        <div className="mono" style={{ fontSize: 10, color: 'var(--text-3)', marginTop: 10 }}>
          {live ? '◆ Diretta v2 attivo · RadioBOSS in standby' : '◆ AutoDJ playlist “Notturna 98” · 142 brani'}
        </div>
      </Card>

      {/* Quick actions row */}
      <div>
        <div className="eyebrow-strong" style={{ marginBottom: 8 }}>Quick actions</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 }}>
          <QuickAction icon="upload"   label="Upload"   onClick={() => dispatch({ type: 'tab', tab: 'lib' })} />
          <QuickAction icon="bell"     label="Push"     onClick={() => dispatch({ type: 'tab', tab: 'push' })} />
          <QuickAction icon="schedule" label="Palinsesto" onClick={() => dispatch({ type: 'tab', tab: 'sched' })} />
          <QuickAction icon="users"    label="Listener" onClick={() => dispatch({ type: 'tab', tab: 'live' })} />
        </div>
      </div>

      {/* Alerts */}
      <Card padded>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
          <div className="eyebrow-strong">Alert stream</div>
          <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)' }}>{MOCK.ALERTS.length} oggi</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {MOCK.ALERTS.map(a => <AlertRow key={a.id} a={a}/>)}
        </div>
      </Card>
    </div>
  );
}

function QuickAction({ icon, label, onClick }) {
  return (
    <button onClick={onClick} className="press" style={{
      background: 'var(--surface)',
      border: '1px solid var(--hairline-soft)',
      borderRadius: 8, padding: '12px 8px',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
      color: 'var(--text)', cursor: 'pointer',
    }}>
      <Icon name={icon} size={20} color="var(--text-2)"/>
      <span style={{ fontSize: 10, fontFamily: "'Geist Mono', ui-monospace, monospace", letterSpacing: 0.05 }}>{label}</span>
    </button>
  );
}

function AlertRow({ a }) {
  const colors = {
    info:  'var(--info)',
    warn:  'var(--warn)',
    error: 'var(--accent)',
  }[a.sev];
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '8px 0',
    }}>
      <div style={{ width: 6, height: 6, borderRadius: '50%', background: colors }}/>
      <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', width: 36 }}>{a.t}</span>
      <span style={{ flex: 1, fontSize: 12 }}>{a.text}</span>
      <span className="mono" style={{ fontSize: 9, color: colors, textTransform: 'uppercase', letterSpacing: 0.1 }}>{a.kind}</span>
    </div>
  );
}

// ───────── Listener live ─────────
function ScreenLive({ state, dispatch, accent }) {
  const [refreshing, setRefreshing] = React.useState(false);
  const [pull, setPull] = React.useState(0);
  const startY = React.useRef(0);
  const onTouchStart = (e) => { startY.current = e.touches?.[0]?.clientY ?? 0; };
  const onTouchMove = (e) => {
    const dy = (e.touches?.[0]?.clientY ?? 0) - startY.current;
    if (dy > 0 && !refreshing && e.target.closest('.scroll-area').scrollTop === 0) {
      setPull(Math.min(dy * 0.5, 60));
    }
  };
  const onTouchEnd = () => {
    if (pull > 40 && !refreshing) {
      setRefreshing(true);
      setTimeout(() => {
        setRefreshing(false);
        setPull(0);
        dispatch({ type: 'refresh-listeners' });
      }, 1100);
    } else {
      setPull(0);
    }
  };
  // Mouse fallback for desktop preview
  const onMouseDown = (e) => {
    const tgt = e.currentTarget;
    if (tgt.scrollTop !== 0) return;
    let lastY = e.clientY;
    const move = (ev) => {
      const dy = ev.clientY - lastY;
      if (dy > 0 && !refreshing) setPull(p => Math.min(p + dy * 0.5, 60));
      lastY = ev.clientY;
    };
    const up = () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
      onTouchEnd();
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
  };

  return (
    <div className="scroll-area scroll" style={{ overflowY: 'auto', height: '100%' }}
         onTouchStart={onTouchStart} onTouchMove={onTouchMove} onTouchEnd={onTouchEnd}
         onMouseDown={onMouseDown}>
      {/* Pull indicator */}
      <div style={{
        height: pull, display: 'flex', alignItems: 'center', justifyContent: 'center',
        overflow: 'hidden',
        transition: refreshing ? 'none' : 'height 200ms ease',
      }}>
        {(refreshing || pull > 8) && (
          <div className={refreshing ? 'spin' : ''} style={{
            width: 24, height: 24, borderRadius: '50%',
            border: `2px solid var(--hairline)`,
            borderTopColor: accent,
            opacity: pull / 60,
          }}/>
        )}
      </div>

      <div style={{ padding: '14px 16px 24px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        {/* Big number */}
        <Card padded>
          <div className="eyebrow" style={{ marginBottom: 8 }}>Listener live · adesso</div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10 }}>
            <span className="kpi-num" style={{ fontSize: 56, color: accent, lineHeight: 0.95, letterSpacing: -0.04 }}>
              {state.listenerCount.toLocaleString('it-IT')}
            </span>
            <div style={{ paddingBottom: 6 }}>
              <div className="mono" style={{ fontSize: 11, color: 'var(--autodj)' }}>+12% / 1h</div>
              <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)' }}>vs 1.114</div>
            </div>
          </div>
          <div style={{ marginTop: 14 }}>
            <ListenerGraph data={MOCK.LISTENERS.slice(-24).map(v => v + (state.listenerCount - 1247))} color={accent} height={120}/>
            <AxisTimes labels={['20:45','21:00','21:15','21:30','21:45','22:00','22:15','22:30','22:47']}/>
          </div>
        </Card>

        {/* Source breakdown */}
        <Card padded>
          <div className="eyebrow-strong" style={{ marginBottom: 10 }}>Sorgenti</div>
          <SourceBar label="App mobile"  value={612} pct={49} color={accent}/>
          <SourceBar label="Web player"  value={398} pct={32} color="var(--info)"/>
          <SourceBar label="Smart speaker" value={148} pct={12} color="var(--autodj)"/>
          <SourceBar label="Auto / DAB"  value={89}  pct={7}  color="var(--warn)"/>
        </Card>

        {/* Alert stream */}
        <Card padded>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
            <div className="eyebrow-strong">Alert stream</div>
            <Btn variant="ghost" size="sm">
              <Icon name="filter" size={12}/>
              Filtri
            </Btn>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>
            {[...MOCK.ALERTS, ...MOCK.ALERTS.map(a => ({...a, id: a.id+'b', t: '19:'+a.t.slice(3)}))].map((a, i) => (
              <React.Fragment key={a.id}>
                {i > 0 && <div className="divider"/>}
                <div style={{ padding: '10px 0' }}><AlertRow a={a}/></div>
              </React.Fragment>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}

function SourceBar({ label, value, pct, color }) {
  return (
    <div style={{ marginBottom: 10 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
        <span style={{ fontSize: 12 }}>{label}</span>
        <span className="mono" style={{ fontSize: 11, color: 'var(--text-2)' }}>
          {value.toLocaleString('it-IT')} <span style={{ color: 'var(--text-3)' }}>· {pct}%</span>
        </span>
      </div>
      <div style={{ height: 4, background: 'var(--surface-2)', borderRadius: 2 }}>
        <div style={{ height: '100%', width: `${pct}%`, background: color, borderRadius: 2 }}/>
      </div>
    </div>
  );
}

// ───────── Push notifications log ─────────
function ScreenPush({ state, dispatch, accent }) {
  const [composing, setComposing] = React.useState(false);
  return (
    <div style={{ overflowY: 'auto', height: '100%' }} className="scroll">
      <div style={{ padding: '14px 16px 24px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        {/* Compose CTA */}
        <Card padded>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
            <div>
              <div className="eyebrow" style={{ marginBottom: 2 }}>OneSignal · 4.218 device</div>
              <div style={{ fontSize: 14, fontWeight: 500 }}>Push manuale</div>
            </div>
            <Pill icon="bell">PRONTO</Pill>
          </div>
          <Btn variant="accent" size="md" style={{ width: '100%' }} onClick={() => dispatch({ type: 'push-fire' })}>
            <Icon name="bell" size={16}/>
            Invia push “Afternoon Show inizia ora”
          </Btn>
          <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', marginTop: 8, textAlign: 'center' }}>
            Trigger: cambio show · evento RadioBOSS
          </div>
        </Card>

        {/* Stats */}
        <div style={{ display: 'flex', gap: 8 }}>
          <Stat label="Inviate" value="9.555" unit="oggi" mini/>
          <Stat label="Aperte" value="32%" delta="+8%" color="var(--autodj)" mini/>
          <Stat label="CTR" value="14%" mini/>
        </div>

        {/* Log */}
        <div>
          <div className="eyebrow-strong" style={{ marginBottom: 10 }}>Log notifiche</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {state.pushLog.map(p => <PushRow key={p.id} p={p} accent={accent}/>)}
          </div>
        </div>
      </div>
    </div>
  );
}

function PushRow({ p, accent }) {
  const kindColor = {
    live:  accent,
    promo: 'var(--info)',
    alert: 'var(--warn)',
  }[p.kind];
  const kindIcon = {
    live: 'mic', promo: 'flame', alert: 'alert',
  }[p.kind];
  return (
    <Card style={{ padding: 12 }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 6,
          background: `oklch(from ${kindColor} l c h / 0.2)`,
          color: kindColor,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
        }}>
          <Icon name={kindIcon} size={16}/>
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, marginBottom: 2 }}>
            <div style={{ fontSize: 13, fontWeight: 500, lineHeight: 1.2 }}>{p.title}</div>
            <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', flexShrink: 0 }}>{p.t}</span>
          </div>
          <div style={{ fontSize: 11, color: 'var(--text-3)', marginBottom: 8, lineHeight: 1.3 }}>{p.body}</div>
          <div style={{ display: 'flex', gap: 8 }}>
            <span className="mono" style={{ fontSize: 9, color: 'var(--text-3)' }}>
              {p.sent.toLocaleString('it-IT')} sent
            </span>
            <span className="mono" style={{ fontSize: 9, color: 'var(--autodj)' }}>
              {p.opens.toLocaleString('it-IT')} open
            </span>
            <span className="mono" style={{ fontSize: 9, color: 'var(--text-3)' }}>
              · {Math.round(p.opens / p.sent * 100)}% CTR
            </span>
          </div>
        </div>
      </div>
    </Card>
  );
}

Object.assign(window, {
  ScreenHome, ScreenLive, ScreenPush, AlertRow, SourceBar, PushRow, QuickAction,
});
