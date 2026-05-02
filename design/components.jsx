// Core UI primitives for the regia app

const { useState, useEffect, useRef, useMemo } = React;

// ───────── Cover placeholder (striped, mono explainer) ─────────
function CoverPlaceholder({ size = 72, label = 'COVER', tone = 0 }) {
  // tone 0..3 = different background hues for variety
  const tones = [
    'oklch(0.32 0.02 30)',
    'oklch(0.30 0.02 240)',
    'oklch(0.30 0.02 145)',
    'oklch(0.30 0.02 75)',
  ];
  const bg = tones[tone % tones.length];
  return (
    <div style={{
      width: size, height: size, flexShrink: 0,
      borderRadius: 6,
      background: `repeating-linear-gradient(135deg, ${bg} 0 6px, oklch(0.20 0.01 260) 6px 12px)`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: 'rgba(255,255,255,0.55)',
      fontFamily: "'Geist Mono', ui-monospace, monospace",
      fontSize: Math.max(8, size * 0.11),
      letterSpacing: 0.1,
      border: '1px solid var(--hairline-soft)',
      overflow: 'hidden',
    }}>{label}</div>
  );
}

// ───────── ON AIR chip ─────────
function OnAirChip({ live = true, accent = 'var(--accent)' }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '4px 8px 4px 7px', borderRadius: 4,
      background: live ? 'oklch(0.66 0.22 25 / 0.14)' : 'oklch(0.78 0.16 145 / 0.14)',
      color: live ? 'var(--accent)' : 'var(--autodj)',
      fontFamily: "'Geist Mono', ui-monospace, monospace",
      fontSize: 10, fontWeight: 600, letterSpacing: 0.12,
      border: `1px solid ${live ? 'oklch(0.66 0.22 25 / 0.5)' : 'oklch(0.78 0.16 145 / 0.5)'}`,
    }}>
      <span style={{
        width: 6, height: 6, borderRadius: '50%',
        background: 'currentColor',
        animation: live ? 'dot-pulse 1.4s ease-in-out infinite' : 'none',
      }} />
      {live ? 'ON AIR' : 'AUTODJ'}
    </div>
  );
}

// ───────── EQ bars (animated, indicates audio level) ─────────
function EqBars({ count = 4, color = 'var(--accent)', height = 14, active = true }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'flex-end', gap: 2, height,
    }}>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} style={{
          width: 2.5, height: '100%', background: color, borderRadius: 1,
          transformOrigin: 'bottom',
          animation: active ? `eq-bar ${0.5 + (i * 0.13)}s ease-in-out ${i * 0.1}s infinite` : 'none',
        }} />
      ))}
    </div>
  );
}

// ───────── Waveform (live, generated peaks) ─────────
function Waveform({ width = 360, height = 64, color = 'var(--accent)', bg = 'transparent', live = true, dense = false, playhead = 0.62 }) {
  const [tick, setTick] = useState(0);
  useEffect(() => {
    if (!live) return;
    const id = setInterval(() => setTick(t => t + 1), 110);
    return () => clearInterval(id);
  }, [live]);
  const barCount = dense ? 80 : 56;
  // Deterministic pseudorandom waveform that "breathes" w/ tick
  const peaks = useMemo(() => {
    const base = Array.from({ length: barCount }).map((_, i) => {
      const a = Math.sin(i * 0.32) * 0.35 + Math.sin(i * 0.13) * 0.4 + Math.sin(i * 0.81) * 0.2;
      return 0.5 + a * 0.5;
    });
    return base;
  }, [barCount]);
  const playIdx = Math.floor(barCount * playhead);
  return (
    <div style={{
      width: '100%', height, display: 'flex', alignItems: 'center',
      gap: 2, background: bg, position: 'relative', justifyContent: 'space-between',
    }}>
      {peaks.map((p, i) => {
        const wobble = live ? Math.sin((i + tick) * 0.7) * 0.08 + Math.cos((i + tick) * 0.2) * 0.06 : 0;
        const h = Math.max(0.08, Math.min(1, p + wobble));
        const past = i < playIdx;
        return (
          <div key={i} style={{
            flex: 1,
            height: `${h * 100}%`,
            minHeight: 2,
            background: past ? color : 'var(--text-4)',
            opacity: past ? (live ? 1 : 0.85) : 0.5,
            borderRadius: 1,
            transition: 'height 110ms linear',
          }} />
        );
      })}
    </div>
  );
}

// ───────── Time-of-day list strip (for listener graph axis) ─────────
function AxisTimes({ labels }) {
  return (
    <div className="mono" style={{
      display: 'flex', justifyContent: 'space-between',
      fontSize: 9, color: 'var(--text-4)', letterSpacing: 0.1,
      padding: '4px 0 0',
    }}>
      {labels.map(l => <span key={l}>{l}</span>)}
    </div>
  );
}

// ───────── Listener live line graph ─────────
function ListenerGraph({ data, color = 'var(--accent)', height = 110 }) {
  const w = 360, h = height;
  const max = Math.max(...data) * 1.1;
  const min = Math.min(...data) * 0.7;
  const path = data.map((v, i) => {
    const x = (i / (data.length - 1)) * w;
    const y = h - ((v - min) / (max - min)) * h;
    return `${i === 0 ? 'M' : 'L'}${x.toFixed(1)},${y.toFixed(1)}`;
  }).join(' ');
  const fill = `${path} L${w},${h} L0,${h} Z`;
  // playhead = last point (live)
  const lastX = w;
  const lastY = h - ((data[data.length - 1] - min) / (max - min)) * h;
  return (
    <svg width="100%" viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none" style={{ display: 'block', overflow: 'visible' }}>
      <defs>
        <linearGradient id="lg-fill" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.32" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      {/* gridlines */}
      {[0.25, 0.5, 0.75].map(g => (
        <line key={g} x1="0" x2={w} y1={h * g} y2={h * g}
              stroke="var(--hairline-soft)" strokeWidth="1" strokeDasharray="2 4" />
      ))}
      <path d={fill} fill="url(#lg-fill)" />
      <path d={path} stroke={color} strokeWidth="1.8" fill="none" strokeLinejoin="round" strokeLinecap="round" />
      <circle cx={lastX} cy={lastY} r="3.5" fill={color} />
      <circle cx={lastX} cy={lastY} r="7" fill={color} fillOpacity="0.25">
        <animate attributeName="r" from="4" to="10" dur="1.4s" repeatCount="indefinite"/>
        <animate attributeName="fill-opacity" from="0.4" to="0" dur="1.4s" repeatCount="indefinite"/>
      </circle>
    </svg>
  );
}

// ───────── Section card (the dominant container) ─────────
function Card({ children, padded = true, style, ...rest }) {
  return (
    <div {...rest} style={{
      background: 'var(--surface)',
      border: '1px solid var(--hairline-soft)',
      borderRadius: 10,
      padding: padded ? 14 : 0,
      ...style,
    }}>{children}</div>
  );
}

// ───────── Button ─────────
function Btn({ children, variant = 'ghost', size = 'md', onClick, style, ...rest }) {
  const sizes = {
    sm: { h: 32, fs: 12, px: 10 },
    md: { h: 40, fs: 13, px: 14 },
    lg: { h: 48, fs: 14, px: 18 },
  }[size];
  const variants = {
    primary: { bg: 'var(--text)', color: 'var(--bg)', border: 'transparent' },
    accent:  { bg: 'var(--accent)', color: '#fff', border: 'transparent' },
    success: { bg: 'var(--autodj)', color: 'var(--bg)', border: 'transparent' },
    outline: { bg: 'transparent', color: 'var(--text)', border: 'var(--hairline)' },
    ghost:   { bg: 'var(--surface-2)', color: 'var(--text)', border: 'var(--hairline-soft)' },
    danger:  { bg: 'var(--accent-soft)', color: 'var(--accent)', border: 'oklch(0.66 0.22 25 / 0.5)' },
  }[variant];
  return (
    <button {...rest} className="press" onClick={onClick} style={{
      height: sizes.h, padding: `0 ${sizes.px}px`,
      borderRadius: 8, fontSize: sizes.fs, fontWeight: 500,
      letterSpacing: 0.05,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      background: variants.bg, color: variants.color,
      border: `1px solid ${variants.border}`,
      cursor: 'pointer',
      whiteSpace: 'nowrap',
      ...style,
    }}>{children}</button>
  );
}

// ───────── Tab bar ─────────
function TabBar({ tabs, current, onChange, accent }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'stretch', justifyContent: 'space-around',
      background: 'oklch(0.13 0.004 260)',
      borderTop: '1px solid var(--hairline-soft)',
      paddingBottom: 4,
      flexShrink: 0,
    }}>
      {tabs.map(t => {
        const active = t.id === current;
        return (
          <button key={t.id} onClick={() => onChange(t.id)} style={{
            flex: 1, background: 'transparent', border: 0,
            padding: '10px 4px 8px', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
            color: active ? accent : 'var(--text-3)',
            transition: 'color 120ms ease',
            position: 'relative',
          }}>
            <Icon name={t.icon} size={22} />
            <span style={{
              fontFamily: "'Geist Mono', ui-monospace, monospace",
              fontSize: 9, letterSpacing: 0.1, fontWeight: active ? 600 : 500,
              textTransform: 'uppercase',
            }}>{t.label}</span>
            {active && (
              <div style={{
                position: 'absolute', top: 0, left: '50%', transform: 'translateX(-50%)',
                width: 28, height: 2, background: accent, borderRadius: 0,
              }} />
            )}
          </button>
        );
      })}
    </div>
  );
}

// ───────── Page header (top of each scroll area) ─────────
function PageHeader({ title, eyebrow, right, onBack }) {
  return (
    <div style={{
      padding: '14px 16px 12px',
      display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between',
      gap: 10,
      borderBottom: '1px solid var(--hairline-soft)',
      background: 'var(--bg)',
      flexShrink: 0,
    }}>
      <div style={{ minWidth: 0, display: 'flex', alignItems: 'center', gap: 10 }}>
        {onBack && (
          <button onClick={onBack} className="press" style={{
            width: 32, height: 32, borderRadius: 6,
            background: 'transparent', border: '1px solid var(--hairline-soft)',
            color: 'var(--text-2)', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="back" size={18} />
          </button>
        )}
        <div style={{ minWidth: 0 }}>
          {eyebrow && <div className="eyebrow" style={{ marginBottom: 2 }}>{eyebrow}</div>}
          <div style={{ fontSize: 22, fontWeight: 600, letterSpacing: -0.02 }}>{title}</div>
        </div>
      </div>
      {right}
    </div>
  );
}

// ───────── Stat tile ─────────
function Stat({ label, value, unit, delta, color = 'var(--text)', mini = false }) {
  return (
    <div style={{
      flex: 1,
      padding: mini ? '10px 12px' : '12px 14px',
      background: 'var(--surface)',
      border: '1px solid var(--hairline-soft)',
      borderRadius: 10,
      minWidth: 0,
    }}>
      <div className="eyebrow" style={{ marginBottom: 6 }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
        <span className="kpi-num" style={{
          fontSize: mini ? 20 : 24, color, lineHeight: 1,
        }}>{value}</span>
        {unit && <span className="mono" style={{ fontSize: 11, color: 'var(--text-3)' }}>{unit}</span>}
      </div>
      {delta && (
        <div className="mono" style={{
          fontSize: 10, marginTop: 4,
          color: delta.startsWith('+') ? 'var(--autodj)' : 'var(--accent)',
        }}>{delta}</div>
      )}
    </div>
  );
}

// ───────── Toggle (for Live/AutoDJ — bigger and more visible than a checkbox) ─────────
function BigToggle({ live, onChange, accent = 'var(--accent)' }) {
  return (
    <button onClick={() => onChange(!live)} style={{
      position: 'relative',
      width: 220, height: 44, borderRadius: 8,
      border: `1px solid ${live ? accent : 'var(--autodj)'}`,
      background: 'oklch(0.18 0.005 260)',
      cursor: 'pointer',
      padding: 3,
      display: 'flex', alignItems: 'center',
      transition: 'border-color 200ms ease',
    }}>
      <div style={{
        position: 'absolute',
        left: live ? 'calc(50% + 1px)' : 3,
        top: 3,
        width: 'calc(50% - 4px)', height: 'calc(100% - 6px)',
        borderRadius: 6,
        background: live ? accent : 'var(--autodj)',
        transition: 'left 240ms cubic-bezier(0.5, 0.1, 0.2, 1)',
        boxShadow: live ? `0 0 16px oklch(0.66 0.22 25 / 0.45)` : '0 0 16px oklch(0.78 0.16 145 / 0.35)',
      }} />
      <div style={{
        flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative', zIndex: 1,
        fontFamily: "'Geist Mono', ui-monospace, monospace",
        fontSize: 11, fontWeight: 600, letterSpacing: 0.1,
        color: !live ? '#0a0a0a' : 'var(--text-3)',
      }}>AUTODJ</div>
      <div style={{
        flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative', zIndex: 1,
        fontFamily: "'Geist Mono', ui-monospace, monospace",
        fontSize: 11, fontWeight: 600, letterSpacing: 0.1,
        color: live ? '#fff' : 'var(--text-3)',
      }}>● ON AIR</div>
    </button>
  );
}

// ───────── Pill ─────────
function Pill({ children, color = 'var(--text-2)', bg = 'var(--surface-2)', icon }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      padding: '3px 8px', borderRadius: 4,
      background: bg, color,
      fontFamily: "'Geist Mono', ui-monospace, monospace",
      fontSize: 10, letterSpacing: 0.1, fontWeight: 500,
      border: '1px solid var(--hairline-soft)',
    }}>
      {icon && <Icon name={icon} size={11} />}
      {children}
    </span>
  );
}

// ───────── Toast ─────────
function Toast({ message, kind = 'info', onClose }) {
  useEffect(() => {
    const id = setTimeout(onClose, 2600);
    return () => clearTimeout(id);
  }, [onClose]);
  const colors = {
    success: { bg: 'var(--autodj)', fg: '#0a0a0a', icon: 'check' },
    info:    { bg: 'var(--info)', fg: '#0a0a0a', icon: 'bell' },
    error:   { bg: 'var(--accent)', fg: '#fff', icon: 'alert' },
  }[kind];
  return (
    <div style={{
      position: 'absolute', left: 16, right: 16, bottom: 80,
      background: colors.bg, color: colors.fg,
      borderRadius: 8, padding: '12px 14px',
      display: 'flex', alignItems: 'center', gap: 10,
      fontSize: 13, fontWeight: 500,
      animation: 'toast-in 220ms ease-out',
      boxShadow: '0 10px 30px rgba(0,0,0,0.4)',
      zIndex: 50,
    }}>
      <Icon name={colors.icon} size={18} />
      <span style={{ flex: 1 }}>{message}</span>
    </div>
  );
}

// ───────── Modal ─────────
function Modal({ open, onClose, title, children, footer }) {
  if (!open) return null;
  return (
    <>
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.55)',
        zIndex: 90, animation: 'overlay-in 160ms ease-out',
        backdropFilter: 'blur(2px)',
      }} />
      <div style={{
        position: 'absolute', left: 16, right: 16, bottom: 16,
        background: 'var(--bg-elev)', borderRadius: 14,
        border: '1px solid var(--hairline)',
        padding: 18,
        zIndex: 91,
        animation: 'modal-in 240ms cubic-bezier(0.2, 0.8, 0.2, 1)',
        maxHeight: '88%', display: 'flex', flexDirection: 'column',
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          marginBottom: 14,
        }}>
          <div style={{ fontSize: 16, fontWeight: 600 }}>{title}</div>
          <button onClick={onClose} style={{
            background: 'transparent', border: 0, color: 'var(--text-2)',
            cursor: 'pointer', padding: 4, display: 'flex',
          }}><Icon name="close" size={20}/></button>
        </div>
        <div style={{ flex: 1, overflowY: 'auto', minHeight: 0 }} className="scroll">
          {children}
        </div>
        {footer && <div style={{
          marginTop: 14, paddingTop: 14,
          borderTop: '1px solid var(--hairline-soft)',
          display: 'flex', gap: 8,
        }}>{footer}</div>}
      </div>
    </>
  );
}

Object.assign(window, {
  CoverPlaceholder, OnAirChip, EqBars, Waveform, ListenerGraph, AxisTimes,
  Card, Btn, TabBar, PageHeader, Stat, BigToggle, Pill, Toast, Modal,
});
