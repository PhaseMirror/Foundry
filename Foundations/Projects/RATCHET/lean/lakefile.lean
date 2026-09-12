import Lake
open Lake DSL

package «ratchet» where
  srcDir := "."

@[default_target]
lean_lib Ratchet where
  roots := #[
    `Ratchet.Types,
    `Ratchet.Conjectures,
    `Ratchet.Controller,
    `Ratchet.Sandbox,
    `Ratchet.Receipts,
    `Ratchet.Attacks,
    `Ratchet.PhaseB_RelaxedConjectures,
    `Ratchet.AdversarialTwin,
    `Ratchet
  ]

lean_exe «ratchet_test» where
  root := `tests.RatchetTest

lean_exe «phase_b_test» where
  root := `tests.PhaseBTest
