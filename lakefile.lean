import Lake
open Lake DSL

package "Prime"

lean_lib Multiplicity {
  srcDir := "lean"
}

lean_lib Prime {
  srcDir := "."
}

lean_lib ADR {
  roots := #[`ADR.Core, `ADR.Proofs, `ADR.Examples, `ADR.Export, `ADR.Test, `ADR.Theorems.CareViability]
}

@[default_target]
lean_lib PhaseMirror {
  roots := #[`PhaseMirror, `Care, `ADR.Theorems.CareViability, `ADR.Core, `ADR.Proofs, `ADR.Examples, `ADR.Export, `ADR.Test]
}

@[test_driver]
lean_exe adr_test {
  root := `ADR.Test
}

-- ADR-0034-F1-Geometry Scaffolding (spectral attractor layer).
lean_lib SpectralAttractor where
  srcDir := "lean"
  roots := #[`Multiplicity.SpectralAttractor]

lean_exe spectral_attractor_tests where
  srcDir := "lean"
  root := `Multiplicity.SpectralAttractor.Tests

-- WL-LARGEPRIME-012 / WordLove hybrid primality + certified coupling
-- Files live under lean/Multiplicity/WordLove/{Attrs,Core,Fixtures,Proofs,FFI,Examples,Certified,Test}.lean
lean_lib WordLove where
  srcDir := "lean"
  roots := #[
    `Multiplicity.WordLove.Attrs,
    `Multiplicity.WordLove.Core,
    `Multiplicity.WordLove.Fixtures,
    `Multiplicity.WordLove.Proofs,
    `Multiplicity.WordLove.FFI,
    `Multiplicity.WordLove.Examples,
    `Multiplicity.WordLove.Certified,
    `Multiplicity.WordLove.Test
  ]

lean_exe word_love_test where
  srcDir := "lean"
  root := `Multiplicity.WordLove.Test

-- F1 square repair path (ADR-0033 follow-up): spine closure of the
-- constructive-Real carried Weil PSD machinery.
lean_lib F1Spine where
  srcDir := "lean"
  roots := #[
    `Multiplicity.F1.Square.WeilPSD,
    `Multiplicity.F1.Square.CoupledWeilKernel
  ]
