# Phase 3 Remediation Spec — c₀ Falsification

**Date:** 2026-03-27  
**Status:** OPEN  
**Owner:** Stephen Hope  
**Sign-off:** Ryan van Gelder (Multiplicity Foundation)  
**Deadline:** 7 days (2026-04-03)  
**Artifact:** `checksums/c0_remediation.json`

---

## What Was Falsified

`J_MKT(W_{3_1})|_{s=i}` evaluated at `t = e^{-2π}` gives `|J_MKT| = 1.0`,
`ln|J_MKT| = 0.0`. The universal constant `c₀ = ln 10` is **not** a derived
invariant of the trefoil at this evaluation point.

```json
{
  "knot": "3_1",
  "s": "i",
  "J_MKT": 1.0,
  "ln_J_MKT": 0.0,
  "c0_confirmed": false
}
```

---

## What Replaces c₀ = ln 10

Three candidate paths — Ryan to select and sign off:

### Path A — Per-Knot Fitted c₀
Each knot type gets its own empirical `c₀(K)` derived from numerical
evaluation of `J_MKT(W_K)` at the physically motivated evaluation point.

- `c₀(3_1)` = fitted from trefoil data
- `c₀(4_1)` = fitted from figure-eight data
- Universality claim dropped from `constitutional_field.py`
- `protection_factor()` becomes `protection_factor(K, c0_K)`

**Risk:** Breaks universality. All downstream CF thresholds become knot-dependent.

### Path B — Alternative Evaluation Point
Evaluate at a different root of unity where `ln|J_MKT| ≈ ln 10` holds.
Candidates: `s = 1/6` (Volume Conjecture limit), `s = e^{2πi/3}`.

**Risk:** Oracle advises against — may be fitting to salvage a preconception.
Only pursue if there is physical motivation for the alternative `s`.

### Path C — Lindblad-First
Defer `c₀` derivation entirely until Lindblad renormalization (Phase 5)
is complete. Keep `c₀ = ln 10` as empirical calibration with explicit
`CF-PENDING` annotation. Re-evaluate after renormalization reveals the
true coupling structure.

**Recommended by Phase Mirror oracle.**

---

## Remediation Checklist

- [ ] Ryan selects Path A, B, or C
- [ ] `constitutional_field.py` updated with chosen path
- [ ] All `CF-PENDING` annotations resolved or extended
- [ ] `KnotProtection` values recomputed if Path A
- [ ] `checksums/c0_remediation.json` committed with sign-off hash
- [ ] ADR-101 status updated from PROPOSED → FALSIFIED/REMEDIATED

---

## Sign-off Format

```json
{
  "remediation_path": "A|B|C",
  "c0_new": "<value or 'per-knot'>",
  "signed_by": "ryan.vangelder@multiplicityfoundation.org",
  "date": "YYYY-MM-DD",
  "sha256_of_constitutional_field": "<hash>"
}
```
