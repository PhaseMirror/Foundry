import Lake
open Lake DSL

package adr_scaffold {
  srcDir := "."
}

@[default_target]
lean_lib Multiplicity where
  roots := #[`Multiplicity.Complex, `Multiplicity.Prime, `Multiplicity.Axioms, `Multiplicity.RSA, `Multiplicity.RSA.PrimePowerRSA]

lean_exe adr_test where
  root := `ADR.Test

@[test_runner]
lean_exe test where
  root := `Test.RSA

lean_lib PdeRnn where
  roots := #[`PdeRnn.FFI, `PdeRnn.Spec, `PdeRnn.Smm]

lean_lib CertificateCore where
  roots := #[`CertificateCore.Certificate]

lean_lib AlphaFunction where
  roots := #[`AlphaFunction.AlphaFunction]

lean_lib IfmdSafety where
  roots := #[`IfmdSafety.Projection]
