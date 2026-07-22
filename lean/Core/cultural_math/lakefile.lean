import Lake
open Lake DSL

package CulturalMath where
  -- Pure Lean4 formalization of cultural mathematics traditions
  -- No Mathlib dependency; all proofs are self-contained.

lean_lib Foundations where
  srcDir := "src"
  roots := #[
    `Foundations.Basic,
    `Foundations.Topology,
    `Foundations.FunctionalAnalysis,
    `Foundations.DynamicalSystems,
    `Foundations.LieGroups,
    `Foundations.Probability
  ]

lean_lib Theorems where
  srcDir := "src"
  roots := #[
    `Theorems.BasicTheorems,
    `Theorems.TensorNetworkTheorems,
    `Theorems.StabilityTheorems
  ]

lean_lib Specifications where
  srcDir := "src"
  roots := #[
    `Specifications.TensorSpec,
    `Specifications.DynamicsSpec,
    `Specifications.LieSpec,
    `Specifications.StochasticSpec
  ]

lean_lib CulturalMath where
  srcDir := "src"
  roots := #[
    `CulturalMath.Base,
    `CulturalMath.Egyptian,
    `CulturalMath.Chinese,
    `CulturalMath.Babylonian,
    `CulturalMath.Vedic,
    `CulturalMath.Pythagorean,
    `CulturalMath.Hebrew,
    `CulturalMath.Islamic,
    `CulturalMath.Japanese,
    `CulturalMath.Mayan,
    `CulturalMath.African,
    `CulturalMath.Russian,
    `CulturalMath.NumberTheory,
    `CulturalMath.GRTF,
    `CulturalMath.CulturalMath
  ]

@[default_target]
lean_exe CulturalMathTests where
  root := `test.AllTests
  supportInterpreter := true
