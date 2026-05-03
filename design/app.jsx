// Main App — orchestrates state, screens, tweaks

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#e6614f",
  "density": "regular",
  "listenerCountBase": 1247,
  "variant": "classic",
  "showBezel": true
}/*EDITMODE-END*/;

const ACCENT_PRESETS = {
  red:    'oklch(0.66 0.22 25)',
  green:  'oklch(0.78 0.18 145)',
  purple: 'oklch(0.62 0.20 305)',
  blue:   'oklch(0.66 0.18 240)',
  amber:  'oklch(0.78 0.16 75)',
};

function useAppState(listenerBase) {
  const [state, setState] = React.useState(() => ({
    tab: 'home',
    live: true,
    current: MOCK.TRACKS[0],
    queue: MOCK.TRACKS.slice(1),
    position: 132,
    duration: 232,
    listenerCount: listenerBase,
    pushLog: MOCK.PUSH,
    jingles: MOCK.JINGLES,
    jingleModalOpen: false,
    toast: null,
    pushBanner: null,
  }));

  // playback ticking
  React.useEffect(() => {
    const id = setInterval(() => {
      setState(s => {
        let pos = s.position + 1;
        let cur = s.current, q = s.queue, dur = s.duration;
        if (pos >= dur) {
          cur = q[0];
          q = q.slice(1).concat(s.current);
          pos = 0;
          dur = parseDur(cur.dur);
        }
        // listener wiggle
        const wiggle = Math.round((Math.sin(Date.now() / 8000) * 14) + (Math.random() - 0.5) * 4);
        return { ...s, position: pos, current: cur, queue: q, duration: dur, listenerCount: listenerBase + wiggle };
      });
    }, 1000);
    return () => clearInterval(id);
  }, [listenerBase]);

  React.useEffect(() => {
    setState(s => ({ ...s, listenerCount: listenerBase }));
  }, [listenerBase]);

  const dispatch = (a) => {
    setState(s => {
      switch (a.type) {
        case 'tab': return { ...s, tab: a.tab };
        case 'skip': {
          const next = s.queue[0];
          return {
            ...s,
            current: next,
            queue: s.queue.slice(1).concat(s.current),
            position: 0,
            duration: parseDur(next.dur),
            toast: { kind: 'success', msg: `Skip → ${next.title}` },
          };
        }
        case 'jingle-open': return { ...s, jingleModalOpen: true };
        case 'jingle-close': return { ...s, jingleModalOpen: false };
        case 'jingle-confirm': {
          return {
            ...s,
            jingleModalOpen: false,
            toast: { kind: 'success', msg: `Jingle “${a.j.name}” inserito · ${a.mode === 'now' ? 'subito' : a.mode === 'fade' ? 'cross-fade' : 'a fine brano'}` },
          };
        }
        case 'jingle-fire':
          return { ...s, toast: { kind: 'success', msg: 'Jingle inserito a fine brano' } };
        case 'jingle-uploaded':
          return {
            ...s,
            jingles: [{ id: 'jU', name: 'stinger_estate_2026.mp3', dur: '0:05', tag: 'STING', uses: 0 }, ...s.jingles],
            toast: { kind: 'success', msg: 'Jingle caricato · pronto in libreria' },
          };
        case 'toggle-live':
          return { ...s, live: a.live, toast: { kind: 'info', msg: a.live ? 'Diretta v2 attivato — RadioBOSS in standby' : 'AutoDJ ripreso · playlist Notturna 98' } };
        case 'push-fire':
          return {
            ...s,
            pushLog: [
              { id: 'pN' + Date.now(), title: 'Afternoon Show inizia ora', body: 'Con Andrea Vella', t: 'ora', sent: 4218, opens: 0, kind: 'live' },
              ...s.pushLog,
            ],
            pushBanner: { id: 'pN', title: 'Afternoon Show inizia ora', body: 'Con Andrea Vella · RadioKit' },
            toast: { kind: 'info', msg: 'Push inviata a 4.218 device' },
          };
        case 'refresh-listeners':
          return { ...s, toast: { kind: 'info', msg: 'Listener aggiornati · OK' } };
        case 'toast-clear': return { ...s, toast: null };
        case 'push-banner-clear': return { ...s, pushBanner: null };
        default: return s;
      }
    });
  };

  return [state, dispatch];
}

function parseDur(d) {
  const [m, s] = d.split(':').map(Number);
  return m * 60 + s;
}

const TABS = [
  { id: 'home',   icon: 'home',     label: 'Home'    },
  { id: 'now',    icon: 'play',     label: 'On Air'  },
  { id: 'stream', icon: 'signal',   label: 'Stream'  },
  { id: 'live',   icon: 'users',    label: 'Listener'},
  { id: 'lib',    icon: 'library',  label: 'Library' },
];

const MORE_TABS = [
  { id: 'push',    icon: 'bell',    label: 'Push'    },
  { id: 'history', icon: 'list',    label: 'Storico' },
  { id: 'account', icon: 'account', label: 'Account' },
];

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const accent = ACCENT_PRESETS[
    t.accent === '#e6614f' ? 'red' :
    t.accent === '#5fc594' ? 'green' :
    t.accent === '#a36ce6' ? 'purple' : 'red'
  ] || ACCENT_PRESETS.red;
  const [state, dispatch] = useAppState(t.listenerCountBase);

  // Apply density attribute
  React.useEffect(() => {
    document.body.setAttribute('data-density', t.density);
    document.body.style.setProperty('--accent', accent);
  }, [t.density, accent]);

  const renderScreen = () => {
    switch (state.tab) {
      case 'home':    return <ScreenHome state={state} dispatch={dispatch} accent={accent}/>;
      case 'stream':  return <ScreenStream state={state} dispatch={dispatch} accent={accent}/>;
      case 'now':     return t.variant === 'experimental'
                        ? <NowPlayingExperimental state={state} dispatch={dispatch} accent={accent}/>
                        : <NowPlayingClassic      state={state} dispatch={dispatch} accent={accent}/>;
      case 'live':    return <ScreenLive state={state} dispatch={dispatch} accent={accent}/>;
      case 'lib':     return <ScreenLibrary state={state} dispatch={dispatch} accent={accent}/>;
      case 'sched':   return <ScreenSchedule state={state} dispatch={dispatch} accent={accent}/>;
      case 'push':    return <ScreenPush state={state} dispatch={dispatch} accent={accent}/>;
      case 'history': return <ScreenHistory state={state} dispatch={dispatch} accent={accent}/>;
      case 'account': return <ScreenAccount state={state} dispatch={dispatch} accent={accent}/>;
      default:        return null;
    }
  };

  // Header per screen
  const HEADER = {
    home:    { title: 'Regia',          eyebrow: 'RADIOKIT · 22:47' },
    now:     { title: 'On Air',         eyebrow: state.live ? 'LIVE · Pomeriggio RK' : 'AUTODJ · Notturna RK' },
    stream:  { title: 'Stream input',   eyebrow: 'INVIO ALLA REGIA' },
    live:    { title: 'Listener live',  eyebrow: 'STREAM · ICECAST 2' },
    lib:     { title: 'Libreria',       eyebrow: 'JINGLES · BRANI' },
    sched:   { title: 'Palinsesto',     eyebrow: 'SETTIMANA · OGGI' },
    push:    { title: 'Push',           eyebrow: 'ONESIGNAL · 4.218 DEVICE' },
    history: { title: 'Storico',        eyebrow: 'ULTIMI BRANI' },
    account: { title: 'Account',        eyebrow: 'CONDUTTORE' },
  };
  const h = HEADER[state.tab];

  // Right-side actions in header
  const headerRight = (
    <div style={{ display: 'flex', gap: 6 }}>
      {state.tab === 'home' && (
        <button onClick={() => dispatch({ type: 'tab', tab: 'push' })} style={iconHeaderBtn(accent)}>
          <Icon name="bell" size={16}/>
          <span style={{
            position: 'absolute', top: 5, right: 5,
            width: 6, height: 6, borderRadius: '50%', background: accent,
          }}/>
        </button>
      )}
      <button onClick={() => dispatch({ type: 'tab', tab: 'account' })} style={iconHeaderBtn(accent)}>
        <Icon name="account" size={16}/>
      </button>
    </div>
  );

  // For non-primary tabs (push, history, account), show back button
  const onBack = ['push', 'history', 'account'].includes(state.tab)
    ? () => dispatch({ type: 'tab', tab: 'home' })
    : null;

  return (
    <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column' }}>
      {state.pushBanner && <PushBanner push={state.pushBanner} onClose={() => dispatch({ type: 'push-banner-clear' })}/>}

      <PageHeader title={h.title} eyebrow={h.eyebrow} right={headerRight} onBack={onBack}/>

      <div style={{ flex: 1, overflow: 'hidden', position: 'relative', background: 'var(--bg)' }}>
        <div style={{ height: '100%', overflowY: state.tab === 'live' || state.tab === 'lib' || state.tab === 'sched' || state.tab === 'push' || state.tab === 'history' || state.tab === 'account' || state.tab === 'stream' ? 'hidden' : 'auto' }} className="scroll">
          {renderScreen()}
        </div>

        {state.toast && <Toast message={state.toast.msg} kind={state.toast.kind} onClose={() => dispatch({ type: 'toast-clear' })}/>}

        <JingleInsertModal
          open={state.jingleModalOpen}
          onClose={() => dispatch({ type: 'jingle-close' })}
          onConfirm={(j, mode) => dispatch({ type: 'jingle-confirm', j, mode })}
          accent={accent}
          jingles={state.jingles}
        />
      </div>

      <TabBar tabs={TABS} current={state.tab} onChange={(id) => dispatch({ type: 'tab', tab: id })} accent={accent}/>

      {/* Tweaks */}
      <TweaksPanel>
        <TweakSection label="Brand"/>
        <TweakRadio label="Accento" value={t.accent}
          options={[
            { value: '#e6614f', label: 'ON AIR' },
            { value: '#5fc594', label: 'Verde'  },
            { value: '#a36ce6', label: 'Viola'  },
          ]}
          onChange={(v) => setTweak('accent', v)}
        />
        <TweakSection label="Layout"/>
        <TweakRadio label="Now Playing" value={t.variant}
          options={[
            { value: 'classic',      label: 'Classica' },
            { value: 'experimental', label: 'Sperim.'  },
          ]}
          onChange={(v) => setTweak('variant', v)}
        />
        <TweakRadio label="Densità" value={t.density}
          options={['compact', 'regular']}
          onChange={(v) => setTweak('density', v)}
        />
        <TweakSection label="Stream"/>
        <TweakSlider label="Listener live" value={t.listenerCountBase}
          min={120} max={4500} step={10} unit="asc."
          onChange={(v) => setTweak('listenerCountBase', v)}
        />
        <TweakSection label="Demo"/>
        <TweakButton label="Trigger push"
          onClick={() => dispatch({ type: 'push-fire' })}/>
        <TweakButton label="Skip traccia"
          onClick={() => dispatch({ type: 'skip' })}/>
        <TweakButton label={state.live ? 'Spegni ON AIR' : 'Accendi ON AIR'}
          onClick={() => dispatch({ type: 'toggle-live', live: !state.live })}/>
      </TweaksPanel>
    </div>
  );
}

function iconHeaderBtn(accent) {
  return {
    width: 34, height: 34, borderRadius: 6,
    background: 'var(--surface)',
    border: '1px solid var(--hairline-soft)',
    color: 'var(--text-2)',
    cursor: 'pointer',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    position: 'relative',
  };
}

window.RegiaApp = App;
