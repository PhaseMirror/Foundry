# PWEH Side-by-Side Validation Report

**Date:** 2026-06-30
**Owner:** L0 Substrate Team
**Target:** Drift detection between `pweh-parser` crate implementation and `PWEH_External_Interface_Description.md`

## 1. Validation Setup
A fresh `v566` trace mock was parsed using the `pweh-parser` Rust crate. The resulting structurally parsed `PwehReceipt` was re-serialized to JSON to confirm exact 1:1 key mapping against the external document.

## 2. Side-By-Side Comparison

| Crate Field (`PwehReceipt`) | JSON Key Emitted | Documented Element (`External_Interface.md`) | Status |
| :--- | :--- | :--- | :--- |
| `s_integrity` | `"s_integrity"` | 1. Integrity State | MATCH |
| `last_prime_move` | `"last_prime_move"` | 2. Last Action | MATCH |
| `policy_root_hash` | `"policy_root_hash"` | 3. Policy Root | MATCH |
| `crmf_certificate` | `"crmf_certificate"` | 4. Safety Certificate | MATCH |
| `lambda_m_resonance_score` | `"lambda_m_resonance_score"` | 5. Resonance Score | MATCH |

## 3. Results
- **Discrepancies:** ZERO discrepancies found.
- **Data Types:** All string validations (hex format for hashes) and numeric parsing for the resonance score align perfectly with the external specification limits.
- **Approval:** The exact key mappings match the descriptive elements. The external document and the Rust crate are mathematically and structurally bound.

**Next Step:** Both artifacts are approved for external release to DecisionAssure.
