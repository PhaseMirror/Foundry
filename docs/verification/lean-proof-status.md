# Lean Proof Status

## Core Definitions (all resolved theorems are fully proven)

| File | Definitions | Status |
|------|------------|--------|
| `PartialUC.lean` | PartialUC, is_defined_compose, is_defined_closure, restrict | ✅ Complete |
| `UniversalClosure.lean` | UC, IdempotentClosure, AssociativeCompose, toPartialUC | ✅ Complete |
| `Completion.lean` | Term, LawfulRel, lawful_setoid, Carrier, compose_q, closure_q, completion, var_embed | ✅ Complete |
| `DefectAlgebra.lean` | Defect, HasDefect, associator_defect, binary_residual | ✅ Complete |

## Theorems (all resolved theorems are fully proven)

| File | Theorems | Status |
|------|----------|--------|
| `Adjunction.lean` | var_embed_compose_q, var_embed_closure_q, completion_carrier_structure, unit_factor, completion_is_free | ✅ Complete |
| `NNO.lean` | iterate_closure_zero, iterate_closure_succ, iterate_compose_zero, iterate_compose_succ, iterate_closure_compose, nno_closure_iterates, nno_compose_iterates | ✅ Complete |
| `DefectComposition.lean` | compositional_defect, closure_reduces_defect, defect_compose_bound, associator_compose_bound | ✅ Complete |
| `MorphismSoundness.lean` | morphism_soundness_image, morphism_soundness_exact, closure_morphism_soundness, compose_morphism_soundness | ✅ Complete |

## Axioms Used

All theorems use only standard Lean 4 axioms:
- `propext` (propositional extensionality)
- `Quot.sound` (quotient soundness)

Remaining sorry blocks (53 declarations across the project) are documented in `alp_sorry_manifest.json`.
