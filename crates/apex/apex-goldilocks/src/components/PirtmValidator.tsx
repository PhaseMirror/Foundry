import { useState } from 'react';
import { validatePirtm, PirtmEnvelope } from '../lib/tauri';

export function PirtmValidator() {
  const [source, setSource] = useState('op(prime_index=7);\nop(prime_index=17);\n');
  const [primesJson, setPrimesJson] = useState('[2, 3, 5, 7, 11, 13]');
  const [stratum, setStratum] = useState('S1');
  const [result, setResult] = useState<PirtmEnvelope | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleValidate = async () => {
    try {
      const res = await validatePirtm(source, primesJson, stratum);
      setResult(res);
      setError(null);
    } catch (e: any) {
      setError(e.toString());
      setResult(null);
    }
  };

  return (
    <div className="p-6 bg-surface-variant rounded-lg shadow-lg border border-border max-w-2xl mx-auto my-10">
      <h2 className="text-2xl font-bold mb-4 text-foreground">PIRTM Source Validator</h2>
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-foreground-muted mb-1">
            PIRTM Source Code
          </label>
          <textarea
            value={source}
            onChange={(e) => setSource(e.target.value)}
            className="w-full h-32 p-2 bg-surface border border-border rounded text-foreground font-mono"
            placeholder="op(prime_index=7);"
          />
        </div>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-foreground-muted mb-1">
              Allowed Primes (JSON)
            </label>
            <input
              type="text"
              value={primesJson}
              onChange={(e) => setPrimesJson(e.target.value)}
              className="w-full p-2 bg-surface border border-border rounded text-foreground font-mono"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground-muted mb-1">
              Stratum ID
            </label>
            <input
              type="text"
              value={stratum}
              onChange={(e) => setStratum(e.target.value)}
              className="w-full p-2 bg-surface border border-border rounded text-foreground"
            />
          </div>
        </div>
        <button
          onClick={handleValidate}
          className="w-full py-2 px-4 bg-primary text-primary-foreground rounded hover:bg-primary-hover transition-colors font-bold"
        >
          Validate Admissibility
        </button>

        {error && (
          <div className="mt-4 p-3 bg-red-900/30 text-red-400 border border-red-500/50 rounded">
            Error: {error}
          </div>
        )}

        {result && (
          <div className="mt-4 space-y-2">
            <div className={`p-3 rounded font-bold ${result.diagnostics.length === 0 ? 'bg-green-900/30 text-green-400 border border-green-500/50' : 'bg-yellow-900/30 text-yellow-400 border border-yellow-500/50'}`}>
              Status: {result.diagnostics.length === 0 ? 'ADMISSIBLE' : 'INADMISSIBLE'} (v{result.version})
            </div>
            {result.diagnostics.length > 0 && (
              <div className="bg-surface border border-border rounded p-2 overflow-x-auto">
                <table className="w-full text-xs text-left">
                  <thead>
                    <tr className="border-b border-border">
                      <th className="p-1">Line:Col</th>
                      <th className="p-1">Code</th>
                      <th className="p-1">Message</th>
                    </tr>
                  </thead>
                  <tbody>
                    {result.diagnostics.map((d, i) => (
                      <tr key={i} className="border-b border-border/50">
                        <td className="p-1 font-mono text-foreground-muted">{d.start_line}:{d.start_col}</td>
                        <td className="p-1 font-bold text-yellow-500">{d.code}</td>
                        <td className="p-1 text-foreground">{d.message}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}
      </div>
      <div className="mt-6 text-xs text-foreground-muted italic">
        * Advancement: PIRTM-lang Phase A (Grammar via Tree-Sitter)
      </div>
    </div>
  );
}
