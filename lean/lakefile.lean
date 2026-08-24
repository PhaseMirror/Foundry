import Lake
open Lake DSL

package adr_scaffold {
  srcDir := "."
}

@[default_target]
lean_lib Multiplicity where
  roots := #[`Multiplicity.Complex, `Multiplicity.Prime, `Multiplicity.Axioms, `Multiplicity.RSA, `Multiplicity.RSA.PrimePowerRSA, `Multiplicity.FPES.Core, `Multiplicity.FPES.Proofs, `Multiplicity.FPES.Examples, `Multiplicity.FPES.FFI, `Multiplicity.FPES.Test, `Multiplicity.Fold.Core, `Multiplicity.Fold.Proofs, `Multiplicity.Fold.Examples, `Multiplicity.Fold.Test, `Multiplicity.WordLove.Core, `Multiplicity.WordLove.Proofs, `Multiplicity.WordLove.Examples, `Multiplicity.WordLove.FFI, `Multiplicity.WordLove.Test]

lean_exe adr_test where
  root := `ADR.Test

lean_exe test where
  root := `Test.RSA

@[test_runner]
lean_exe fpes_test where
  root := `Multiplicity.FPES.Test

lean_exe fold_test where
  root := `Multiplicity.Fold.Test

lean_exe word_love_test where
  root := `Multiplicity.WordLove.Test

lean_lib PdeRnn where
  roots := #[`PdeRnn.FFI, `PdeRnn.Spec, `PdeRnn.Smm]

lean_lib CertificateCore where
  roots := #[`CertificateCore.Certificate]

lean_lib AlphaFunction where
  roots := #[`AlphaFunction.AlphaFunction]

lean_lib IfmdSafety where
  roots := #[`IfmdSafety.Projection]

-- ADR-0034-F1-Geometry Scaffolding (spectral attractor layer).
lean_lib SpectralAttractor where
  roots := #[`Multiplicity.SpectralAttractor]

lean_exe spectral_attractor_tests where
  srcDir := "lean"
  root := `Multiplicity.SpectralAttractor.Tests
