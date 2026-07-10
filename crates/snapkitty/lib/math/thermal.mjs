// Mirrors ThermalEngine.hs exactly. TypeScript displays. Haskell proves. JavaScript bridges.

const FRICTION_ALPHA = 0.2;
const LO_FACTOR = 16383;
const HI_FACTOR = 16384;
const UINT16_MAX = 65535;

export function mkFriction(f) {
  return Math.max(0, Math.min(1, f));
}

// EMA: f_{n+1} = α·score + (1−α)·current
export function frictionEMA(current, score) {
  const clamped = Math.max(0, Math.min(1, score));
  return mkFriction(FRICTION_ALPHA * clamped + (1 - FRICTION_ALPHA) * current);
}

// Proven invariant: lo(f) ≤ 16383 < 49151 ≤ hi(f) for all f ∈ [0,1]
export function computeThermalWindow(friction) {
  const lo = Math.round(friction * LO_FACTOR);
  const hi = UINT16_MAX - Math.round(friction * HI_FACTOR);
  if (lo >= hi) return { lo: 0, hi: UINT16_MAX, span: UINT16_MAX }; // fallback (unreachable for valid f)
  return { lo, hi, span: hi - lo };
}

export function normalizeWithinWindow(raw, { lo, hi, span }) {
  if (span === 0) return 0.5;
  const clamped = Math.max(lo, Math.min(hi, raw));
  return (clamped - lo) / span;
}

export function thermalMode(friction) {
  if (friction < 0.33) return 'Cool';
  if (friction < 0.66) return 'Warm';
  return 'Hot';
}

export function sampleCount(friction) {
  return 2 + Math.round(friction * 6);
}

// Steps to cool below f=0.1 from current friction
export function decisionsToCool(friction) {
  if (friction <= 0.1) return 0;
  return Math.ceil(Math.log(0.1) / Math.log(1 - FRICTION_ALPHA));
}

export function thermalFeedbackLoop(initialFriction, scores) {
  const final = scores.reduce(frictionEMA, initialFriction);
  return {
    friction: final,
    window: computeThermalWindow(final),
    mode: thermalMode(final),
    sampleCount: sampleCount(final),
    decisionsToCool: decisionsToCool(final),
  };
}

// Boltzmann partition function: Z = Σ exp(-E_i / kT)
export function boltzmannPartition(energies, temperature, boltzmann = 1.380649e-23) {
  return energies.reduce((z, e) => z + Math.exp(-e / (boltzmann * temperature)), 0);
}

// Boltzmann probability: P(E_i) = exp(-E_i/kT) / Z
export function boltzmannProb(energy, temperature, z, boltzmann = 1.380649e-23) {
  return Math.exp(-energy / (boltzmann * temperature)) / z;
}
