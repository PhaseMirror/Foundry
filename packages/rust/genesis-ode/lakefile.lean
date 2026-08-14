import Lake
open Lake DSL

package genesis_ode where
  leanOptions := {}
  moreLeanArgs := #[]

-- Mathlib removed to comply with axiom-clean mandate

lean_lib GenesisOde where
  srcDir := "lean"
  moreLeanArgs := #[]
lean_exe FullTestSuite where
  supportInterpreter := true

lean_exe EquivalenceProofs where
  supportInterpreter := true
