import Lake
open Lake DSL



package foundations

@[default_target]
lean_lib Foundations where
  roots := #[`Foundations]

-- ADR formal governance test harness. `lake test` builds and runs this executable,
-- which exercises the Layer-B-gated membrane, fail-closed acceptance/mint gates,
-- registry invariants, consequence entailment, and export determinism.
@[test_driver]
lean_exe adrTest where root := `Foundations.ADR.Test

-- Word Love hybrid primality + certified coupling (ADR-0031 §6, ADR-0033 P5).
-- Roots map to the `Foundations.WordLove` namespace; built as `libFoundations_WordLove.so`
-- for the `wordlove-ffi` Rust binding (`lake build WordLove:shared`).
lean_lib WordLove where
  roots := #[`Foundations.WordLove]
