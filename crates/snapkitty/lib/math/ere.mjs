// 5-pass Enochian Reading Engine (ERE)
// Mirrors edaulc_verify.pl and quantum_monad.pl ere_pass/3 exactly.

const FABRICATION_MARKERS = ['fabricat', 'invent', 'i made up', 'i cannot provide', 'as an ai'];
const MISSION_VIOLATIONS = new Set(['null', 'undefined', 'none']);

// Pass 1 — structural (Enochian LTR): non-empty, instantiated
export function erePass1(input) {
  if (typeof input === 'string') return input.length > 3;
  if (Array.isArray(input)) return input.length > 0;
  return input != null;
}

// Pass 2 — scholarly (Latin LTR): non-fabricated content
export function erePass2(input) {
  const str = typeof input === 'string' ? input.toLowerCase() : '';
  return !FABRICATION_MARKERS.some(m => str.includes(m));
}

// Pass 3 — invariants (Hebrew RTL): reverse read is valid
export function erePass3(input) {
  if (Array.isArray(input)) return [...input].reverse().length > 0;
  if (typeof input === 'string') return input.length > 0;
  return true;
}

// Pass 4 — mission (Arabic RTL): aligned to sovereign mission
export function erePass4(input) {
  const str = String(input ?? '').toLowerCase();
  return !MISSION_VIOLATIONS.has(str) && !str.includes('void');
}

// Pass 5 — root (Aramaic RTL): structural ancestor is valid
export function erePass5(input) {
  return input !== undefined;
}

const PASSES = [erePass1, erePass2, erePass3, erePass4, erePass5];

// ERE score ∈ [0,1]: 0.0 = all pass (clean), 1.0 = all fail
export function ereScore(input) {
  return PASSES.filter(p => !p(input)).length / PASSES.length;
}

export function ereRunPasses(input) {
  const results = PASSES.map((p, i) => ({ pass: i + 1, result: p(input) }));
  const score = ereScore(input);
  return {
    pass1: results[0].result,
    pass2: results[1].result,
    pass3: results[2].result,
    pass4: results[3].result,
    pass5: results[4].result,
    score,
    certified: score === 0,
    metatron: score === 0 ? 'YES' : 'NO',
  };
}

const SEARCH_ORDERS = {
  analytical: [0, 1, 2, 3, 4],       // Passes 1→2→3→4→5
  creative:   [4, 3, 2, 1, 0],       // Passes 5→4→3→2→1
  receptive:  [0, 2, 4, 1, 3],       // Passes 1→3→5→2→4
  grounding:  [4, 3, 2, 1, 0],       // Passes 5→4→3→2→1
};

// Run passes in the order dictated by a watchtower's search mode
export function ereRunMode(mode, input) {
  const order = SEARCH_ORDERS[mode] ?? SEARCH_ORDERS.analytical;
  for (const idx of order) {
    if (!PASSES[idx](input)) {
      return { certified: false, failedAt: idx + 1, mode };
    }
  }
  return { certified: true, mode };
}
