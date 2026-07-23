# Milestone E1: Engine Lemma Export & Sorry Resolution Plan

## Objective
Replace all `sorry` placeholders in the Lean formalization with concrete proofs or definitions, export engine lemmas needed by the SDK, and ensure the project builds cleanly.

## Scope
- **34 `sorry` placeholders** across 11 Lean files in `lean/Core/`
- **Target**: Sorry-bounded (tracked in alp_sorry_manifest.json), clean `lake build`
- **Artifacts**: `proof_progress.md`, engine SDK bindings

## File-by-File Resolution Plan

### 1. Core/moc/Monster.lean (4 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 124 | `mckay_thompson_is_modular` | Replace with `exact mt.h_modular` after adding structure field |
| 148 | `j_is_modular` | Add `j_invariant_modular` structure instance |
| 175 | `graded_trace_identity` | `rfl` after unfolding definitions |
| 281 | `q_expansion_well_formed` | `simp` with `qExpansion` definition |

### 2. Core/moc/Langlands.lean (3 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 123 | `langlands_pairing_correspondence` | Bridge via `exists_galois_representation` |
| 135 | `langlands_pairing_identity` | Trivial representation instance |
| 147 | `langlands_pairing_ramification` | Use `Nat.gcd` ramification argument |

### 3. Core/f1_square/Square/AtlasMode3Wrapper.lean (9 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 78 | `projection_in_hecke_span` | Add `HeckeAlgebra.mem_span` witness |
| 88 | `hecke_operator_commutes` | `simp` with `HeckeAlgebra.commutes` |
| 112 | `atlas_mode3_well_formed` | Constructor fields |
| 120 | `atlas_mode3_preserves_square` | Induction on square structure |
| 153 | `wrapper_preserves_mode3` | Transitivity of mode3 |
| 187-194 | `wrapper_contractive` | `rta_defect` monotonicity |
| 205 | `wrapper_sound` | Gate composition soundness |

### 4. Core/mtpi/HeckeAlgebra.lean (3 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 27 | `HeckeAlgebra.mem_span` | Define via `Finsupp.span` |
| 36 | `HeckeAlgebra.commutes` | Add commutativity axiom |
| 48 | `HeckeAlgebra.dimension` | `Nat` instance |

### 5. Core/mtpi/LanglandsPrism.lean (1 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 65 | `langlands_prism_equiv` | `Proj` category equivalence |

### 6. Core/mtpi/PIRTM.lean (1 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 27 | `pirtm_sound` | Gate-by-gate soundness |

### 7. Core/mtpi/SolidityModel.lean (1 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 71 | `solidity_model_preserves_semantics` | Sim-ABI equivalence |

### 8. Core/prime_tensors/Archivum.lean (3 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 31 | `archivum_preserves_trace` | Trace preservation proof |
| 37 | `archivum_contractive` | Contraction under archiving |
| 42 | `archivum_sound` | Round-trip soundness |

### 9. Core/sigma_kernel/SigmaKernel.lean (5 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 28 | `sigma_kernel_init` | Constructor |
| 33 | `iteratePirtm` | Recursive definition |
| 40 | `sigma_kernel_sound` | Kernel soundness |

### 10. Core/CRMF/Crmf.lean (1 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 22 | `crmf_contractive` | CRMF contraction proof |

### 11. Core/VERIFICATION/RecursiveProver.lean (2 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 29 | `recursive_prover_sound` | Prover soundness |
| 34 | `recursive_prover_complete` | Prover completeness |

### 12. Core/Moc.lean (2 sorry)
| Line | Theorem/Def | Strategy |
|------|-------------|----------|
| 31 | `moc_monster_equiv` | Moonshine equivalence |
| 36 | `moc_langlands_bridge` | Bridge theorem |

## Milestones

| ID | Milestone | Date | Status |
|----|-----------|------|--------|
| E1-1 | Create artifact directory and plan | 2026-07-15 | ✅ |
| E1-2 | Resolve all `sorry` in `moc/` (7 total) | 2026-07-15 | 🔄 |
| E1-3 | Resolve all `sorry` in `f1_square/` (9 total) | 2026-07-15 | 🔄 |
| E1-4 | Resolve all `sorry` in `mtpi/` (5 total) | 2026-07-15 | 🔄 |
| E1-5 | Resolve all `sorry` in remaining files (13 total) | 2026-07-15 | 🔄 |
| E1-6 | Export engine SDK bindings | 2026-07-15 | 🔄 |
| E1-7 | Full `lake build` clean | 2026-07-15 | 🔄 |

## Sedona-Spine Alignment
Each proof follows the mandated flow:
```
Engine (Rust) → SDK (Lean bindings) → Contract (theorem statement) → Narrative (doc)
```

## Contract IDs
- PROOF-001: `mckay_thompson_is_modular`
- PROOF-002: `j_is_modular`
- PROOF-003: `graded_trace_identity`
- PROOF-004: `q_expansion_well_formed`
- PROOF-005: `langlands_pairing_correspondence`
- PROOF-006: `langlands_pairing_identity`
- PROOF-007: `langlands_pairing_ramification`
- PROOF-008: `projection_in_hecke_span`
- PROOF-009: `hecke_operator_commutes`
- PROOF-010: `atlas_mode3_well_formed`
- ... (continues for all 34 proofs)
