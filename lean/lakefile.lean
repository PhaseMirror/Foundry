import Lake
open Lake DSL

require std from git "https://github.com/leanprover/std4" @ "v4.32.0"

package Prime where

lean_lib Core where
  srcDir := "."
  roots := #[`Core.Resonance, `Core.F1, `Core.F1Square, `Core.PIRTM, `Core.MOC, `Core.GOLDILOCKS, `Core.Governance, `Core.UOR, `Core.Spine, `Core.universal_closure.PartialUC, `Core.universal_closure.UniversalClosure, `Core.universal_closure.Completion, `Core.universal_closure.DefectAlgebra, `Core.universal_closure.UniversalCalculator, `Core.Properties.AdjunctionProp, `Core.Properties.DefectProps, `Core.Properties.NNOProp, `Core.Ext.FFI, `Core.Theorems.Adjunction, `Core.Theorems.NNO, `Core.Theorems.DefectComposition, `Core.Theorems.MorphismSoundness, `Examples.Arithmetic, `Examples.QuantumGate, `Core.prime_tensors, `Core.moc]

lean_lib FFI where
  srcDir := "FFI"
  defaultFacets := #[LeanLib.sharedFacet]

lean_lib ADR where
  srcDir := "Core"
  roots := #[
    `ADR.Core,
    `ADR.Logics,
    `ADR.Proofs,
    `ADR.History,
    `ADR.Governance,
    `ADR.Examples,
    `ADR.Export,
    `ADR.Test
  ]

lean_lib UOR where
  srcDir := "Core/moc"
  roots := #[`UOR.Enforcement, `UOR.Enums, `UOR.Examples, `UOR.Individuals, `UOR.Pipeline, `UOR.Prelude, `UOR.Primitives, `UOR.Structures, `UOR.Test, `UOR.UORMatMul]

lean_lib ACE_SCN_CSC where
  srcDir := "projects/ACE_SCN_CSC/src"

lean_exe PrimeWasm where
  srcDir := "."
  exeName := "Prime"
lean_exe RiemannZetaTests where
  srcDir := "Core/f1_square"
  exeName := "RiemannZetaTests"

@[test_driver]
lean_exe adr_test {
  srcDir := "Core"
  root := `ADR.Test
}
