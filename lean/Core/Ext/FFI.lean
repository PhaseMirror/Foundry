import Core.universal_closure.PartialUC
import Core.universal_closure.UniversalClosure
import Core.universal_closure.Completion
import Core.universal_closure.DefectAlgebra
import Core.Properties.AdjunctionProp
import Core.Properties.DefectProps

/-!
# FFI to Kani Verification Results

Axiomatic declarations backed by Rust/Kani.
Kani proves bounded properties; Lean imports them as trusted axioms.
Zero proofs in Lean — all verification is external.
-/

open Completion

axiom kani_adjunction_proof : ∀ {X : Type} (P : PartialUC X), AdjunctionProperty P

axiom kani_compositional_defect : ∀ {X : Type} {U : UC X} (hd : HasDefect U),
  CompositionalDefectSpec hd

axiom kani_closure_reduces_defect : ∀ {X : Type} {U : UC X} (hd : HasDefect U),
  ClosureReducesDefectSpec hd
