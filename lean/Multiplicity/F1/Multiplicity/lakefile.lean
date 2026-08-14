import Lake
open Lake DSL

package "RH_Multiplicity" {
  srcDir := "."
  testDriver := "test"
}

@[default_target]
lean_lib RH_Multiplicity {
  roots := #[
    `Axioms,
    `HilbertPolya,
    `PIRTM,
    `EthicalSpectral,
    `ZetaMultiplicityTransform,
    `RecursiveCoherence,
    `IsolationMeasure,
    `MainTheorem,
    `Corollaries,
    `KaniCertificates,
    `Tests.TestAxioms,
    `Tests.TestKaniConsistency,
    `RH_Multiplicity,
  ]
}

lean_exe test {
  root := `Tests.TestMain
}
