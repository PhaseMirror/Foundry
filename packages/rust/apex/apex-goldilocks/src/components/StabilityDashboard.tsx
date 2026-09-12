import { useState } from 'react';
import { verifyStability } from '../lib/tauri';

export function StabilityDashboard() {
  const [totalNorm, setTotalNorm] = useState(800000);
  const [govC, setGovC] = useState(50000);
  const [result, setResult] = useState<string | null>(null);

  const handleVerify = async () => {
    const res = await verifyStability(totalNorm, govC);
    setResult(res);
  };

  return (
    <div className="p-6 bg-surface-variant rounded-lg shadow-lg border border-border max-w-md mx-auto my-10">
      <h2 className="text-2xl font-bold mb-4 text-foreground">ACE Stability Dashboard</h2>
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-foreground-muted mb-1">
            Total Operator Norm (μ-units)
          </label>
          <input
            type="number"
            value={totalNorm}
            onChange={(e) => setTotalNorm(parseInt(e.target.value))}
            className="w-full p-2 bg-surface border border-border rounded text-foreground"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground-muted mb-1">
            Governance Constant c (μ-units)
          </label>
          <input
            type="number"
            value={govC}
            onChange={(e) => setGovC(parseInt(e.target.value))}
            className="w-full p-2 bg-surface border border-border rounded text-foreground"
          />
        </div>
        <button
          onClick={handleVerify}
          className="w-full py-2 px-4 bg-primary text-primary-foreground rounded hover:bg-primary-hover transition-colors font-bold"
        >
          Verify Stability
        </button>
        {result && (
          <div className={`mt-4 p-3 rounded font-mono ${result === 'PASS' ? 'bg-green-900/30 text-green-400 border border-green-500/50' : 'bg-red-900/30 text-red-400 border border-red-500/50'}`}>
            Result: {result}
          </div>
        )}
      </div>
      <div className="mt-6 text-xs text-foreground-muted italic">
        * Advancement: PIRTM-lang Phase C (ACE Invariant Checks)
      </div>
    </div>
  );
}
