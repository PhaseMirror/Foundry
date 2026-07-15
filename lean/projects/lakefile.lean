import Lake
open Lake DSL

/-!
# Projects package — Lean 4 formalizations of the Prime/PhaseMirror projects

Build mandate (see `proofs/Kernel.lean`):
- **No `Mathlib`.** All arithmetic is discrete (`Nat` / `Int` / `Bool` / `List` /
  finite function spaces). Continuous / IEEE-754 mathematics that would otherwise
  require a real-analysis library are delegated to **Rust + Kani** verification
  harnesses (see `proofs/Kani.lean`).
- **No `sorry` / `admit`** anywhere under `proofs/`. The trusted core for the
  continuous parts is the Kani-verified Rust binary, surfaced in Lean as a small,
  explicitly specified `constant`/`axiom` bridge.

Build:  `lake build`
Test:   `lake test`
-/
package Projects

@[default_target]
lean_lib PP where
  srcDir := "proofs"
  roots := #[
    `Kernel,
    `Kani,
    `AceScnCsc,
    `Mersenne503,
    `AlphaFunction,
    `AutomorphicLearning,
    `Aztftc,
    `EigenSolvers,
    `ElasticTether,
    `ExoticSpheres,
    `GodelianTruth,
    `Hcqa,
    `IntegrativeSolver,
    `LanglandsPrism,
    `LorenzAtractor,
    `LowComplexityAttractor,
    `MatrixEngine,
    `Mcpe,
    `MonodialEnsembleAggregation,
    `MOperator,
    `Mqem,
    `Neuroplasticity,
    `RecursiveFoundations,
    `Shpa,
    `UniversalLogic,
    `WestEast,
    `Zetacell,
    `ZetaPhiPi,
    `Zmos,
    `Zmod,
    `EchoBraid,
    `Test
  ]
