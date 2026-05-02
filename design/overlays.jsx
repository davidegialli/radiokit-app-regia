// Jingle insert modal + Push live notification banner

function JingleInsertModal({ open, onClose, onConfirm, accent, jingles }) {
  const [selected, setSelected] = React.useState(jingles[0]?.id);
  const [mode, setMode] = React.useState('next'); // 'now' | 'next' | 'fade'
  React.useEffect(() => { if (open) setSelected(jingles[0]?.id); }, [open]);
  const j = jingles.find(x => x.id === selected);
  return (
    <Modal open={open} onClose={onClose}
      title="Insert jingle"
      footer={<>
        <Btn variant="ghost" size="md" style={{ flex: 1 }} onClick={onClose}>Annulla</Btn>
        <Btn variant="accent" size="md" style={{ flex: 1 }} onClick={() => onConfirm(j, mode)}>
          <Icon name="jingle" size={14}/>
          Conferma
        </Btn>
      </>}
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        {/* Mode */}
        <div>
          <div className="eyebrow" style={{ marginBottom: 8 }}>Modalità</div>
          <div style={{ display: 'flex', gap: 6 }}>
            {[
              { id: 'now',  label: 'Ora',         sub: 'taglio brusco' },
              { id: 'next', label: 'A fine brano',sub: 'consigliato'   },
              { id: 'fade', label: 'Cross-fade',  sub: '2.5s'          },
            ].map(m => (
              <button key={m.id} onClick={() => setMode(m.id)} style={{
                flex: 1, padding: '10px 6px',
                background: mode === m.id ? 'var(--accent-soft)' : 'var(--surface)',
                border: `1px solid ${mode === m.id ? accent : 'var(--hairline-soft)'}`,
                color: mode === m.id ? accent : 'var(--text-2)',
                borderRadius: 8, cursor: 'pointer',
                display: 'flex', flexDirection: 'column', gap: 3, alignItems: 'center',
              }}>
                <span style={{ fontSize: 12, fontWeight: 600 }}>{m.label}</span>
                <span className="mono" style={{ fontSize: 9, color: 'var(--text-3)' }}>{m.sub}</span>
              </button>
            ))}
          </div>
        </div>

        {/* List */}
        <div>
          <div className="eyebrow" style={{ marginBottom: 8 }}>Scegli jingle</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4, maxHeight: 240, overflowY: 'auto' }} className="scroll">
            {jingles.map(j => {
              const sel = j.id === selected;
              return (
                <button key={j.id} onClick={() => setSelected(j.id)} style={{
                  display: 'flex', alignItems: 'center', gap: 10,
                  padding: '10px 12px',
                  background: sel ? 'var(--accent-soft)' : 'var(--surface)',
                  border: `1px solid ${sel ? accent : 'var(--hairline-soft)'}`,
                  borderRadius: 8, cursor: 'pointer', textAlign: 'left',
                  color: 'var(--text)',
                }}>
                  <div style={{
                    width: 28, height: 28, borderRadius: 4,
                    background: sel ? accent : 'var(--surface-2)',
                    color: sel ? '#fff' : 'var(--text-3)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                  }}>
                    <Icon name="jingle" size={13}/>
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{j.name}</div>
                    <div style={{ display: 'flex', gap: 8 }}>
                      <span className="mono" style={{ fontSize: 9, color: sel ? accent : 'var(--text-3)', letterSpacing: 0.1 }}>{j.tag}</span>
                      <span className="mono" style={{ fontSize: 9, color: 'var(--text-3)' }}>{j.dur}</span>
                    </div>
                  </div>
                  {sel && <Icon name="check" size={16} color={accent}/>}
                </button>
              );
            })}
          </div>
        </div>
      </div>
    </Modal>
  );
}

function PushBanner({ push, onClose }) {
  React.useEffect(() => {
    const id = setTimeout(onClose, 4000);
    return () => clearTimeout(id);
  }, [onClose]);
  return (
    <div style={{
      position: 'absolute', top: 8, left: 8, right: 8,
      background: 'rgba(20,21,25,0.92)',
      backdropFilter: 'blur(16px)',
      border: '1px solid var(--hairline)',
      borderRadius: 12, padding: '10px 12px',
      display: 'flex', alignItems: 'flex-start', gap: 10,
      zIndex: 80,
      animation: 'push-in 320ms cubic-bezier(0.2, 0.8, 0.2, 1)',
      boxShadow: '0 16px 40px rgba(0,0,0,0.5)',
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 8,
        background: 'var(--accent)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <Icon name="mic" size={16} color="#fff"/>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 6, marginBottom: 2 }}>
          <span style={{ fontFamily: "'Geist Mono', ui-monospace, monospace", fontSize: 9, color: 'var(--text-3)', letterSpacing: 0.1 }}>RADIOKIT · ora</span>
        </div>
        <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 1 }}>{push.title}</div>
        <div style={{ fontSize: 11, color: 'var(--text-2)', lineHeight: 1.3 }}>{push.body}</div>
      </div>
    </div>
  );
}

Object.assign(window, { JingleInsertModal, PushBanner });
