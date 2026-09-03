import Lake
open Lake DSL



package foundations

@[default_target]
lean_lib Foundations where
  roots := #[`Foundations]

-- ADR formal governance library (single source of truth).
-- This lib exposes `ADR.*` modules to `Foundations.lean` and to the
-- `adrTest` executable. The legacy `Foundations.ADR.*` shadow namespace
-- has been removed; see ADR/README.md.
lean_lib ADR where
  roots := #[`ADR]

-- ADR formal governance test harness (single source of truth).
-- `lake test` builds and runs this executable, which exercises the
-- Layer-B-gated membrane, fail-closed acceptance/mint gates, registry
-- invariants, consequence entailment, migrated ADR-0040/0041/0043/0057-0061
-- invariants, and export determinism.
--
-- All ADR sources live under `ADR.*` (this file's directory).
@[test_driver]
lean_exe adrTest where root := `ADR.Test

-- Word Love hybrid primality + certified coupling (ADR-0031 §6, ADR-0033 P5).
-- Roots map to the `Foundations.WordLove` namespace; built as `libFoundations_WordLove.so`
-- for the `wordlove-ffi` Rust binding (`lake build WordLove:shared`).
lean_lib WordLove where
  roots := #[`Foundations.WordLove]
