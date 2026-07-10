// Verdict algebra, WORM invariants, policy validation
// Mirrors Sovereign.Policy (Lean 4) and Bifrost.Policy (Lean 4)

const MAX_DEPTH = 32;

export const VERDICT_PRIORITY = {
  approve: 0,
  defer: 1,
  reject: 2,
  human_required: 3,
  escalate: 4,
};

export function verdictPriority(verdict) {
  return VERDICT_PRIORITY[verdict.type] ?? 0;
}

// Combine: strictest verdict wins. human_required lists merge.
export function combineVerdicts(verdicts) {
  if (verdicts.length === 0) {
    return { type: 'approve', policyId: 'SOV-DEFAULT-PASS' };
  }
  return verdicts.reduce((best, cur) => {
    if (best.type === 'human_required' && cur.type === 'human_required') {
      return {
        type: 'human_required',
        policyIds: [
          ...(best.policyIds ?? [best.policyId]),
          ...(cur.policyIds ?? [cur.policyId]),
        ],
      };
    }
    return verdictPriority(cur) > verdictPriority(best) ? cur : best;
  });
}

export function verdictNatsSubject(verdict) {
  switch (verdict.type) {
    case 'approve':
    case 'reject':
      return 'sovereign.audit.bifrost.commit.v1';
    default:
      return 'sovereign.governance.decision.pending.v1';
  }
}

export function verdictIsFinal(verdict) {
  return verdict.type === 'approve' || verdict.type === 'reject';
}

export function validateChainDepth(depth) {
  return Number.isInteger(depth) && depth >= 0 && depth <= MAX_DEPTH;
}

// WORM seal invariant: once sealed, cannot be modified
export function wormSealInvariant(cid, wormState) {
  return wormState instanceof Set ? wormState.has(cid) : Boolean(wormState[cid]);
}

// validJitCompile: souliir sealed AND wasm not yet sealed
export function validJitCompile(souliirCid, wasmCid, wormState) {
  return wormSealInvariant(souliirCid, wormState) && !wormSealInvariant(wasmCid, wormState);
}

// validCapTransfer: policyCid sealed (or zero), capHash in capMap (or zero)
export function validCapTransfer(capHash, policyCid, wormState, capMap) {
  const isZero = cid => !cid || cid === '0';
  const policyOk = isZero(policyCid) || wormSealInvariant(policyCid, wormState);
  const capOk = isZero(capHash) || (capMap instanceof Set ? capMap.has(capHash) : Boolean(capMap[capHash]));
  return policyOk && capOk;
}

// validAttestation: epoch root matches recorded state
export function validAttestation(epoch, rootCid, epochRoots) {
  return epochRoots[epoch] === rootCid;
}
