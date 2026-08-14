import Lake
open Lake DSL

package proofs where
  -- no extra packages

@[default_target]
lean_lib Proofs where
  srcDir := "."
  roots := #[`PwehReceipt]
