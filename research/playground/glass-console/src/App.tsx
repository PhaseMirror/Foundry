import { useState, useEffect } from 'react';
import { 
  Activity, 
  BrainCircuit, 
  Cpu, 
  Database, 
  HeartPulse, 
  Network, 
  Radio, 
  ShieldCheck 
} from 'lucide-react';
import { TensorTopography } from './TensorTopography';

const GlassConsole = () => {
  const [resonance, setResonance] = useState(0.85);
  const [entropy, setEntropy] = useState(0.12);
  const [feed, setFeed] = useState<{ id: number; val: string; time: string }[]>([]);

  // The baseline entropy used to calculate the Stability Margin (ΔAUC)
  const baselineEntropy = 0.30;
  const stabilityMargin = baselineEntropy - entropy;

  // Simulate incoming DMTP sensor telemetry
  useEffect(() => {
    const interval = setInterval(() => {
      const now = new Date();
      const timeStr = `${now.getHours()}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}.${now.getMilliseconds().toString().padStart(3, '0')}`;
      
      // Add new feed item
      setFeed(prev => {
        const newFeed = [{
          id: Date.now(),
          time: timeStr,
          val: `[c_${Math.floor(Math.random() * 10)},j] = ${(Math.random() * 0.99).toFixed(4)}`
        }, ...prev];
        return newFeed.slice(0, 5); // Keep last 5
      });

      // Gently perturb the resonance metric
      setResonance(r => {
        const newR = r + (Math.random() - 0.45) * 0.01;
        return Math.min(Math.max(newR, 0.7), 0.99);
      });
      
      // Gently perturb the entropy metric
      setEntropy(e => {
        const newE = e + (Math.random() - 0.55) * 0.005;
        return Math.max(newE, 0.01);
      });
    }, 1500);

    return () => clearInterval(interval);
  }, []);

  return (
    <>
      <div className="ambient-background">
        <div className="ambient-orb orb-1"></div>
        <div className="ambient-orb orb-2"></div>
      </div>
      
      <div className="dashboard">
        <aside className="sidebar glass-panel">
          <div className="logo">
            <div className="logo-icon">
              <Network size={20} />
            </div>
            PhaseMirror HQ
          </div>
          
          <nav style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <a href="#" className="nav-item active">
              <Activity size={18} />
              TensorTopography
            </a>
            <a href="#" className="nav-item">
              <HeartPulse size={18} />
              Sensor Binding (DMTP)
            </a>
            <a href="#" className="nav-item">
              <BrainCircuit size={18} />
              Epoch 1 ZK-Lock
            </a>
            <a href="#" className="nav-item">
              <Database size={18} />
              WORM Registry
            </a>
          </nav>

          <div style={{ marginTop: 'auto' }}>
            <div className="feed-item" style={{ fontSize: '0.8rem', padding: '16px', background: 'rgba(16, 185, 129, 0.05)', borderLeftColor: 'var(--accent-success)' }}>
              <ShieldCheck size={16} color="var(--accent-success)" style={{ marginBottom: '8px' }} />
              <div style={{ color: 'var(--text-secondary)' }}>Epoch 1 Status</div>
              <div style={{ color: 'var(--accent-success)', fontWeight: 'bold' }}>SEALED (282 Constraints)</div>
            </div>
          </div>
        </aside>

        <main className="main-content">
          <header className="header-row">
            <div>
              <h1 className="page-title">Citizen Gardens Node 01</h1>
              <p className="page-subtitle">Real-time Resonance Manifold Calibration (Epoch 2)</p>
            </div>
            <div className="status-pill">
              <div className="status-dot"></div>
              L0 Scope Enforced
            </div>
          </header>

          <div className="metrics-grid">
            <div className="metric-card glass-panel">
              <div className="metric-header">
                Global Resonance (R)
                <Activity size={16} color="var(--accent-primary)" />
              </div>
              <div className="metric-value">{(resonance * 100).toFixed(1)}%</div>
              <div className="metric-trend trend-up">
                ↑ 2.4% <span style={{ color: 'var(--text-muted)' }}>vs baseline</span>
              </div>
            </div>
            
            <div className="metric-card glass-panel">
              <div className="metric-header">
                System Entropy (ΔS)
                <Cpu size={16} color="var(--accent-secondary)" />
              </div>
              <div className="metric-value">{entropy.toFixed(3)}</div>
              <div className="metric-trend trend-down">
                ↓ 0.05 <span style={{ color: 'var(--text-muted)' }}>ΔAUC Target Reached</span>
              </div>
            </div>

            <div className="metric-card glass-panel">
              <div className="metric-header">
                Stability Margin (ΔAUC)
                <Network size={16} color="var(--text-secondary)" />
              </div>
              <div className="metric-value">{stabilityMargin.toFixed(3)}</div>
              <div className={`metric-trend ${stabilityMargin >= 0.05 ? 'trend-up' : 'trend-down'}`}>
                {stabilityMargin >= 0.05 ? 'Target ≥ 0.05 Met' : 'Warning: Dissonance High'}
              </div>
            </div>
          </div>

          <div className="viz-section">
            <div className="viz-panel glass-panel" style={{ border: stabilityMargin < 0.05 ? '1px solid var(--accent-danger)' : '' }}>
              <div className="viz-header">
                <span>Dissonance Graph (Topological)</span>
                <Radio size={18} color="var(--text-muted)" />
              </div>
              <div className="viz-content">
                <div className="signal-wave"></div>
                <TensorTopography stabilityMetric={stabilityMargin} />
              </div>
            </div>

            <div className="viz-panel glass-panel">
              <div className="viz-header">
                <span>Cross-Domain Spectral Stream</span>
              </div>
              <div className="data-feed">
                {feed.map(item => (
                  <div key={item.id} className="feed-item">
                    <span className="feed-time">{item.time}</span>
                    <span className="feed-value">{item.val}</span>
                  </div>
                ))}
              </div>
              <button 
                className="btn-primary" 
                style={{ opacity: stabilityMargin >= 0.05 ? 1 : 0.5, cursor: stabilityMargin >= 0.05 ? 'pointer' : 'not-allowed' }}
                disabled={stabilityMargin < 0.05}
              >
                Mint Multiplicity Stablecoin
              </button>
            </div>
          </div>
        </main>
      </div>
    </>
  );
};

export default GlassConsole;
