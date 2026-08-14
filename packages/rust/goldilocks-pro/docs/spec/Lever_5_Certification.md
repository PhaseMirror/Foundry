# Lever 5: Spectral Witness & Certification (Normative)

## 1. Witness Preservation Invariant (ADR-028)
Certification objects MUST preserve the richest witness required for Tier 4 recovery.
- Fields: `delta_pz` (scalar), `zero_spacings` (u64 array).

## 2. Tier 4 Recovery Check
When the spectral gap falls below the GUE floor, the system checks the nearest-neighbor spacing distribution.
- `CONDITIONAL`: Gap trend is positive AND distribution is GUE-like (Wigner-Dyson).
- `VETO`: Distribution indicates clustering or non-random degeneracies.

## 3. Certification Status
- `PASS`: Healthy spectral gap.
- `CONDITIONAL`: Sub-floor gap but verified via Tier 4 recovery.
- `VETO`: Failed recovery or critical degeneracy.
- `PROVISIONAL`: Missing recursive seal or incomplete witness.
