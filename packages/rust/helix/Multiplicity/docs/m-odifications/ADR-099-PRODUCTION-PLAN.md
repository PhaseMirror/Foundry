# ADR-099: CSL Production Plan — Day 7 MKT Bridge Validation

**Phase:** 3 (CSL-ADR-ROADMAP-3)
**Gate Artifact:** checksums/mkt_jones_result.json
**Governs:** lawfulness_threshold in multiplicity/ethics.py

---

## Objective

Compute $J_\text{MKT}(W_{3_1})|_{s=i}$ for the trefoil knot and confirm whether $c_0 = \ln|J_\text{MKT}| \approx \ln 10$ as required for the MKT bridge validation. This result gates any change to the lawfulness_threshold parameter in production code.

---

## Protocol

1. Run `python multiplicity/mkt_jones.py` to compute the invariant and write the result artifact.
2. Review `checksums/mkt_jones_result.json` for the following fields:
    - `knot`: "3_1"
    - `s`: "i"
    - `J_MKT`: <float>
    - `ln_J_MKT`: <float>
    - `c0_confirmed`: true/false
    - `delta_crit_derived`: true/false
3. If `c0_confirmed` is true and `delta_crit_derived` is true:
    - Open PR: set `lawfulness_threshold = 0.83` in `ethics.py`
    - Remove CF-PENDING from `constitutional_field.py` C_ZERO
    - Update KnotProtection: "calibrated" → "derived"
4. If `c0_confirmed` is false or `delta_crit_derived` is false:
    - Open issue: ADR-101-FALLBACK — per-knot c0 fitting
    - lawfulness_threshold remains 0.95
    - Update constitutional_field.py: c0 per-knot table
    - KnotProtection.P must use knot-specific c0(K)

---

## Branch Protection Rule

No PR may modify `lawfulness_threshold` in `ethics.py` until `checksums/mkt_jones_result.json` exists and `c0_confirmed = true`.

---

## Related Files

- `multiplicity/mkt_jones.py` — computation script
- `checksums/mkt_jones_result.json` — gate artifact
- `multiplicity/ethics.py` — governed parameter
- `docs/governance/BRANCH-PROTECTION-MKT-GATE.md` — branch protection rule
- `tests/test_adr101_mkt_jones.py` — test for computation and artifact
