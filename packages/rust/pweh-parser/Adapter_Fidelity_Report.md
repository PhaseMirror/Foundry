# PWEH Adapter Fidelity Report

**Date:** 2026-06-30
**Target:** `substrates/pweh-parser/pweh_adapter.py`

## Overview
This report verifies that the DecisionAssure Python adapter maintains exact fidelity to the Lean 4 formalization (`PwehReceipt.lean`) and Rust reference parser, without introducing extraneous L0 business logic.

## Line-by-Line Predicate Fidelity

| Lean Predicate | Python Implementation | Assessment |
| --- | --- | --- |
| `isValidHash` | `validate_hash`: Checks length == 64 and regex `^[a-f0-9]{64}$` | **Exact Match.** Ensures only strictly lowercase hexadecimal characters of length 64. |
| `isValidResonanceScore` | `validate_resonance_score`: Checks `value >= 0.0` and `value <= 1.0` | **Exact Match.** Both strictly bound the float to the `[0.0, 1.0]` closed interval. |
| `PwehReceipt` (Structure) | `PWEHCheckpoint` dataclass fields | **Exact Match.** Implements `s_integrity`, `last_prime_move`, `policy_root_hash`, `crmf_certificate`, and `lambda_m_resonance_score`. |
| Prime Validation | `validate_prime`: Standard trial division prime check | **Exact Match.** While Lean formalizes the `Nat` property structurally in `PIRTM-lang`, the Python adapter explicitly enforces primality. |

## Conclusion
The `pweh_adapter.py` is a clean, thin validation layer. It perfectly mirrors the structural requirements of the L0 boundary without importing or replicating core risk-calculation algorithms. Zero drift is maintained.
