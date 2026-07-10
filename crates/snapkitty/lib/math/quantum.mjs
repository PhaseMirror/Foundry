const TOWERS = ['east', 'south', 'west', 'north'];
const ANU_MAX = 65535;

export function qUnit(value) {
  return [{ weight: 1.0, value }];
}

export function qBind(superposition, fn) {
  const result = [];
  for (const { weight, value } of superposition) {
    const inner = fn(value);
    // failed fn → state destroyed (no-cloning corollary: failed paths do not survive bind)
    if (inner && inner.length > 0) {
      for (const { weight: w2, value: v2 } of inner) {
        result.push({ weight: weight * w2, value: v2 });
      }
    }
  }
  return result;
}

export function qMap(superposition, fn) {
  return superposition.map(({ weight, value }) => ({ weight, value: fn(value) }));
}

export function qNormalize(superposition) {
  if (superposition.length === 0) return [];
  const total = superposition.reduce((s, a) => s + a.weight, 0);
  if (total <= 0) {
    const w = 1 / superposition.length;
    return superposition.map(a => ({ ...a, weight: w }));
  }
  return superposition.map(a => ({ ...a, weight: a.weight / total }));
}

export function qPrune(superposition) {
  return superposition.filter(a => a.weight > 0);
}

export function qMeasure(superposition) {
  if (superposition.length === 0) return null;
  return superposition.reduce((best, a) => a.weight > best.weight ? a : best).value;
}

export function watchtowerAmplitudes([r0, r1, r2, r3]) {
  const raw = [r0, r1, r2, r3].map((r, i) => ({
    weight: r / ANU_MAX,
    value: TOWERS[i],
  }));
  return qNormalize(raw);
}

export function subleqGate(amplitudes, threshold = 0.3) {
  const passing = amplitudes.filter(a => a.weight >= threshold);
  return { passing, fired: passing.length > 0, count: passing.length };
}

// The 49th Call: reverse/2 — Prolog 1972 / Haskell: reverse / APL: ⌽
export function call49(superposition) {
  return [...superposition].reverse();
}

// Mirror identity: call49(call49(X)) = X for any list
export function mirrorIdentity(superposition) {
  const once = call49(superposition);
  const twice = call49(once);
  if (twice.length !== superposition.length) return false;
  return twice.every((a, i) => a.value === superposition[i].value);
}

export function sovereignDefaults() {
  // Al-Hamid abjad × 2^N sovereign defaults
  return watchtowerAmplitudes([53, 49, 106, 7]);
}
