# Phase 5 Pre-Execution Checklist
# Lindblad Renormalization Gate

**Date:** 2026-03-27  
**Gate:** Phase 5 — ADR-103 Analytical SlopeUB  
**Blocker:** All items below must be complete before Phase 5 runs.

---

## Checklist

- [ ] **Phase 3 remediation owner assigned**
      Owner: Stephen Hope
      Sign-off: Ryan van Gelder
      Deadline: 2026-04-03
      Artifact: `checksums/c0_remediation.json`
      Spec: `helix-physics-gate/PHASE3_REMEDIATION_SPEC.md`

- [ ] **`receipt.py` stub committed**
      File: `helix-physics-gate/receipt.py`
      Smoke test: `python helix-physics-gate/receipt.py` → receipt emitted
      Must be imported by Phase 5 runner before execution.

- [ ] **Lindblad renormalization inputs pinned in schema**
      Schema: `helix-physics-gate/lindblad_inputs_schema.json`
      Pinned inputs file: `checksums/lindblad_inputs_pinned.json` (to be created)
      Required fields: primes, gamma_heal, c_zero_empirical, delta_crit,
                       tau_zero, slope_ub_naive, renormalization_target,
                       coupling_model

- [ ] **Bistable healing model in parallel branch**
      File: `helix-physics-gate/bistable_healing.py`
      Gate: `checksums/bistable_healing_result.json`
      Required: `classification = "first_order"` and `hysteresis_area > 0.001`

- [ ] **SlopeUB 7.23 threshold documented with physical justification**
      Current value: `sup_p L_p|ω_p| = 2π·C₀/2 = π·C₀ ≈ 7.23` at p=2
      Physical cause: naive coupling `L_p = C₀·ln(p)/p` combined with
                      `ω_p = 2π/ln(p)` gives `L_p·ω_p = 2π·C₀/p`,
                      which at p=2 = π·ln(10) ≈ 7.23.
      Required fix: rescale coupling so `sup_p L_p|ω_p| < 1`.
                    Candidate: `L_p = α·ln(p)/p` where `α = 1/(2π)`.
      Document in: `checksums/slope_ub_justification.json`

---

## Phase 5 Execution Command (once checklist complete)

```powershell
python Z:\run_phase5.py
```

Expected output:
```json
{
  "extended_sweep_997": {"valid_lt_1": true},
  "wetterich_fixed_point": {"converged": true},
  "renormalization_status": "RESOLVED"
}
```

---

## Cross-Contamination Guard

Physics gate work (Phases 3-5) is isolated to:
- `Z:\helix-physics-gate\` — scripts and specs
- `Z:\checksums\` — gate artifacts
- `Z:\run_phase*.py` — runners

Governance runtime work remains in:
- `Z:\helix-hamiltonian\` — TTD bridge, invariants, authority
- `Z:\aws-attention\` — Lambda kernel
- `Z:\azure-memory\` — Azure function
- `Z:\gicd-scanner\` — GCP scanner

**Zero cross-contamination commits. These are separate branches.**
