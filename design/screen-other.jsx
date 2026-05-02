// Library / jingle, Playlist, Login, Storico screens

// ───────── Library / Jingles ─────────
function ScreenLibrary({ state, dispatch, accent }) {
  const [tab, setTab] = React.useState('jingles');
  const [uploading, setUploading] = React.useState(false);
  const [uploadProgress, setUploadProgress] = React.useState(0);
  const [dragOver, setDragOver] = React.useState(false);

  const fakeUpload = () => {
    if (uploading) return;
    setUploading(true);
    setUploadProgress(0);
    let p = 0;
    const id = setInterval(() => {
      p += 8 + Math.random() * 14;
      if (p >= 100) {
        p = 100;
        clearInterval(id);
        setTimeout(() => {
          setUploading(false);
          setUploadProgress(0);
          dispatch({ type: 'jingle-uploaded' });
        }, 380);
      }
      setUploadProgress(p);
    }, 180);
  };

  return (
    <div style={{ overflowY: 'auto', height: '100%' }} className="scroll">
      <div style={{ padding: '14px 16px 24px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        {/* Sub-tabs */}
        <div style={{ display: 'flex', gap: 4, padding: 3, background: 'var(--surface)', border: '1px solid var(--hairline-soft)', borderRadius: 8 }}>
          {[
            { id: 'jingles', label: 'Jingles' },
            { id: 'tracks',  label: 'Brani'   },
          ].map(t => (
            <button key={t.id} onClick={() => setTab(t.id)} style={{
              flex: 1, padding: '8px 10px', borderRadius: 6, border: 0,
              background: tab === t.id ? accent : 'transparent',
              color: tab === t.id ? '#fff' : 'var(--text-2)',
              fontSize: 12, fontWeight: 500, cursor: 'pointer',
              transition: 'all 160ms ease',
            }}>{t.label}</button>
          ))}
        </div>

        {/* Upload zone */}
        <div
          onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
          onDragLeave={() => setDragOver(false)}
          onDrop={(e) => { e.preventDefault(); setDragOver(false); fakeUpload(); }}
          onClick={() => !uploading && fakeUpload()}
          style={{
            border: `1.5px dashed ${dragOver ? accent : 'var(--hairline)'}`,
            background: dragOver ? 'oklch(0.66 0.22 25 / 0.05)' : 'var(--surface)',
            borderRadius: 10, padding: '18px 14px',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
            cursor: uploading ? 'wait' : 'pointer',
            transition: 'all 160ms ease',
          }}>
          {uploading ? (
            <>
              <div className="mono" style={{ fontSize: 11, color: accent }}>
                CARICAMENTO · {Math.round(uploadProgress)}%
              </div>
              <div style={{ width: '100%', height: 4, background: 'var(--surface-2)', borderRadius: 2, overflow: 'hidden' }}>
                <div style={{
                  width: `${uploadProgress}%`, height: '100%', background: accent,
                  transition: 'width 180ms ease',
                }}/>
              </div>
              <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)' }}>
                stinger_estate_2026.mp3 · 1.4 MB
              </div>
            </>
          ) : (
            <>
              <div style={{
                width: 40, height: 40, borderRadius: 8,
                background: 'var(--surface-2)', border: '1px solid var(--hairline-soft)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name="upload" size={20} color={accent}/>
              </div>
              <div style={{ fontSize: 13, fontWeight: 500 }}>Carica jingle</div>
              <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', textAlign: 'center' }}>
                MP3 / WAV · max 5 MB · drop o tap
              </div>
            </>
          )}
        </div>

        {/* List */}
        {tab === 'jingles' && (
          <div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <div className="eyebrow-strong">Libreria · {state.jingles.length}</div>
              <Btn variant="ghost" size="sm">
                <Icon name="search" size={12}/>
                Cerca
              </Btn>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              {state.jingles.map(j => (
                <Card key={j.id} style={{ padding: '10px 12px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <button className="press" style={{
                      width: 36, height: 36, borderRadius: 6,
                      background: 'var(--accent-soft)', border: '1px solid oklch(0.66 0.22 25 / 0.4)',
                      color: accent,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      cursor: 'pointer',
                    }}>
                      <Icon name="play" size={14}/>
                    </button>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{j.name}</div>
                      <div style={{ display: 'flex', gap: 8, marginTop: 2 }}>
                        <span className="mono" style={{ fontSize: 9, color: accent, letterSpacing: 0.1 }}>{j.tag}</span>
                        <span className="mono" style={{ fontSize: 9, color: 'var(--text-3)' }}>{j.dur}</span>
                        <span className="mono" style={{ fontSize: 9, color: 'var(--text-3)' }}>· {j.uses} usi</span>
                      </div>
                    </div>
                    <Btn variant="outline" size="sm" onClick={() => dispatch({ type: 'jingle-fire', id: j.id })}>
                      <Icon name="jingle" size={12}/>
                      Insert
                    </Btn>
                  </div>
                </Card>
              ))}
            </div>
          </div>
        )}
        {tab === 'tracks' && (
          <div>
            <div className="eyebrow-strong" style={{ marginBottom: 10 }}>Brani · {MOCK.TRACKS.length}</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              {MOCK.TRACKS.map((t, i) => <QueueRow key={t.id} track={t} idx={i} accent={accent}/>)}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ───────── Schedule / Palinsesto ─────────
function ScreenSchedule({ state, dispatch, accent }) {
  return (
    <div style={{ overflowY: 'auto', height: '100%' }} className="scroll">
      <div style={{ padding: '14px 16px 24px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div className="eyebrow">Palinsesto</div>
            <div style={{ fontSize: 18, fontWeight: 600 }}>Oggi · giovedì 1 mag</div>
          </div>
          <Btn variant="ghost" size="sm">
            <Icon name="schedule" size={14}/>
            Settimana
          </Btn>
        </div>

        <Card padded={false}>
          {MOCK.SCHEDULE.map((s, i) => (
            <React.Fragment key={s.time}>
              {i > 0 && <div className="divider"/>}
              <div style={{
                padding: '14px 14px',
                display: 'flex', alignItems: 'center', gap: 12,
                background: s.current ? 'oklch(0.66 0.22 25 / 0.06)' : 'transparent',
                position: 'relative',
              }}>
                {s.current && (
                  <div style={{
                    position: 'absolute', left: 0, top: 0, bottom: 0,
                    width: 3, background: accent,
                  }}/>
                )}
                <div style={{ width: 56 }}>
                  <div className="mono" style={{
                    fontSize: 14, fontWeight: 600,
                    color: s.current ? accent : 'var(--text)',
                    letterSpacing: 0.02,
                  }}>{s.time}</div>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 500, marginBottom: 2 }}>{s.show}</div>
                  <div style={{ fontSize: 11, color: 'var(--text-3)' }}>{s.host}</div>
                </div>
                {s.current && <OnAirChip live={s.live}/>}
                {!s.current && (
                  s.host === 'AutoDJ'
                    ? <Pill icon="music">AUTODJ</Pill>
                    : <Pill icon="mic">LIVE</Pill>
                )}
              </div>
            </React.Fragment>
          ))}
        </Card>
      </div>
    </div>
  );
}

// ───────── Storico (history) ─────────
function ScreenHistory({ state, dispatch, accent }) {
  return (
    <div style={{ overflowY: 'auto', height: '100%' }} className="scroll">
      <div style={{ padding: '14px 16px 24px' }}>
        <div className="eyebrow-strong" style={{ marginBottom: 12 }}>Storico brani · ultime 2h</div>
        <Card padded={false}>
          {MOCK.HISTORY.map((h, i) => (
            <React.Fragment key={i}>
              {i > 0 && <div className="divider"/>}
              <div style={{
                padding: '10px 12px',
                display: 'flex', alignItems: 'center', gap: 12,
                opacity: h.jingle ? 0.7 : 1,
              }}>
                <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', width: 36 }}>{h.time}</span>
                <div style={{
                  width: 26, height: 26, borderRadius: 4,
                  background: h.jingle ? 'var(--accent-soft)' : 'var(--surface-2)',
                  color: h.jingle ? accent : 'var(--text-3)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  <Icon name={h.jingle ? 'jingle' : 'music'} size={13}/>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 12, fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{h.title}</div>
                  <div style={{ fontSize: 10, color: 'var(--text-3)' }}>{h.artist}</div>
                </div>
                <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)' }}>{h.dur}</span>
              </div>
            </React.Fragment>
          ))}
        </Card>
      </div>
    </div>
  );
}

// ───────── Account / Login ─────────
function ScreenAccount({ state, dispatch, accent }) {
  const [authed, setAuthed] = React.useState(true);
  if (!authed) return <ScreenLogin onLogin={() => setAuthed(true)} accent={accent}/>;
  return (
    <div style={{ overflowY: 'auto', height: '100%' }} className="scroll">
      <div style={{ padding: '14px 16px 24px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        {/* Profile */}
        <Card padded>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{
              width: 56, height: 56, borderRadius: '50%',
              background: `repeating-linear-gradient(45deg, oklch(0.4 0.05 30) 0 6px, oklch(0.3 0.04 260) 6px 12px)`,
              border: '1px solid var(--hairline)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: "'Geist Mono', ui-monospace, monospace", fontWeight: 700, fontSize: 18,
            }}>SB</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 16, fontWeight: 600 }}>Sara Bonetti</div>
              <div style={{ fontSize: 11, color: 'var(--text-3)' }}>Conduttrice · Pomeriggio RK</div>
              <div style={{ display: 'flex', gap: 6, marginTop: 6 }}>
                <Pill icon="check">REGIA FULL</Pill>
                <Pill>2FA ON</Pill>
              </div>
            </div>
          </div>
        </Card>

        {/* Connections */}
        <div>
          <div className="eyebrow-strong" style={{ marginBottom: 8 }}>Connessioni</div>
          <Card padded={false}>
            <SettingRow icon="signal" label="RadioBOSS API" value="connesso · v6.4" ok/>
            <div className="divider"/>
            <SettingRow icon="mic" label="Diretta v2" value="online · sync ok" ok/>
            <div className="divider"/>
            <SettingRow icon="bell" label="OneSignal" value="App ID ··3a72" ok/>
            <div className="divider"/>
            <SettingRow icon="library" label="Database brani" value="42.118 brani" />
          </Card>
        </div>

        {/* Account actions */}
        <div>
          <div className="eyebrow-strong" style={{ marginBottom: 8 }}>Account</div>
          <Card padded={false}>
            <SettingRow icon="settings" label="Impostazioni regia"/>
            <div className="divider"/>
            <SettingRow icon="schedule" label="I miei show" value="3 attivi"/>
            <div className="divider"/>
            <SettingRow icon="bell" label="Notifiche personali" value="Tutte"/>
            <div className="divider"/>
            <SettingRow icon="close" label="Esci" onClick={() => setAuthed(false)} danger/>
          </Card>
        </div>

        <div className="mono" style={{ fontSize: 9, color: 'var(--text-4)', textAlign: 'center', marginTop: 8 }}>
          RadioKit Regia · build 0.1.4 · Flutter 3.24
        </div>
      </div>
    </div>
  );
}

function SettingRow({ icon, label, value, ok, danger, onClick }) {
  return (
    <button onClick={onClick} className="press" style={{
      width: '100%', background: 'transparent', border: 0,
      padding: '12px 14px',
      display: 'flex', alignItems: 'center', gap: 12,
      cursor: 'pointer', color: 'var(--text)',
      textAlign: 'left',
    }}>
      <div style={{
        width: 28, height: 28, borderRadius: 6,
        background: danger ? 'var(--accent-soft)' : 'var(--surface-2)',
        color: danger ? 'var(--accent)' : 'var(--text-2)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <Icon name={icon} size={14}/>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, color: danger ? 'var(--accent)' : 'var(--text)' }}>{label}</div>
        {value && (
          <div className="mono" style={{ fontSize: 10, color: ok ? 'var(--autodj)' : 'var(--text-3)', marginTop: 1 }}>
            {ok && '◆ '}{value}
          </div>
        )}
      </div>
      <Icon name="back" size={14} color="var(--text-4)" style={{ transform: 'scaleX(-1)' }}/>
    </button>
  );
}

// ───────── Login screen ─────────
function ScreenLogin({ onLogin, accent }) {
  const [email, setEmail] = React.useState('sara.bonetti@radiokit.app');
  const [pwd, setPwd] = React.useState('••••••••');
  const [showPwd, setShowPwd] = React.useState(false);
  const [loading, setLoading] = React.useState(false);
  const submit = () => {
    setLoading(true);
    setTimeout(() => { setLoading(false); onLogin(); }, 900);
  };
  return (
    <div style={{
      height: '100%', overflow: 'auto',
      padding: '32px 24px',
      display: 'flex', flexDirection: 'column', gap: 24,
    }}>
      {/* Logo */}
      <div style={{ marginTop: 40 }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 10,
          padding: '6px 12px',
          border: `1px solid ${accent}`,
          borderRadius: 4,
          color: accent,
          fontFamily: "'Geist Mono', ui-monospace, monospace",
          fontSize: 11, fontWeight: 700, letterSpacing: 0.18,
        }}>
          <span style={{
            width: 8, height: 8, borderRadius: '50%', background: accent,
            animation: 'dot-pulse 1.4s ease-in-out infinite',
          }}/>
          RADIOKIT · REGIA
        </div>
        <div style={{ fontSize: 30, fontWeight: 700, lineHeight: 1.1, marginTop: 24, letterSpacing: -0.02 }}>
          Bentornato in regia.
        </div>
        <div style={{ fontSize: 13, color: 'var(--text-3)', marginTop: 8, lineHeight: 1.4 }}>
          Accedi con il tuo account conduttore per gestire palinsesto, jingle e push.
        </div>
      </div>

      {/* Form */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        <Field label="Email" value={email} onChange={setEmail}/>
        <Field label="Password" value={pwd} onChange={setPwd}
          type={showPwd ? 'text' : 'password'}
          right={
            <button onClick={() => setShowPwd(!showPwd)} style={{
              background: 'transparent', border: 0, color: 'var(--text-3)', cursor: 'pointer', padding: 4,
            }}><Icon name={showPwd ? 'eye_off' : 'eye'} size={16}/></button>
          }
        />
        <Btn variant="accent" size="lg" onClick={submit} style={{ marginTop: 6 }} disabled={loading}>
          {loading ? <div className="spin" style={{ width: 16, height: 16, borderRadius: '50%', border: '2px solid rgba(255,255,255,0.4)', borderTopColor: '#fff' }}/> : <Icon name="check" size={16}/>}
          {loading ? 'Connessione…' : 'Entra in regia'}
        </Btn>
        <button style={{
          background: 'transparent', border: 0, color: 'var(--text-2)',
          fontSize: 12, padding: 8, cursor: 'pointer', alignSelf: 'center',
        }}>Password dimenticata?</button>
      </div>

      <div style={{ flex: 1 }}/>

      <div className="mono" style={{ fontSize: 9, color: 'var(--text-4)', textAlign: 'center' }}>
        2FA · SSO Studio · build 0.1.4
      </div>
    </div>
  );
}

function Field({ label, value, onChange, type = 'text', right }) {
  return (
    <div>
      <div className="eyebrow" style={{ marginBottom: 6 }}>{label}</div>
      <div style={{
        display: 'flex', alignItems: 'center',
        background: 'var(--surface)',
        border: '1px solid var(--hairline)',
        borderRadius: 8,
        padding: '0 12px',
        height: 46,
      }}>
        <input value={value} onChange={(e) => onChange(e.target.value)} type={type}
          style={{
            flex: 1, background: 'transparent', border: 0,
            color: 'var(--text)', fontSize: 14, outline: 'none',
            fontFamily: 'inherit',
          }}/>
        {right}
      </div>
    </div>
  );
}

Object.assign(window, {
  ScreenLibrary, ScreenSchedule, ScreenHistory, ScreenAccount, ScreenLogin, SettingRow, Field,
});
