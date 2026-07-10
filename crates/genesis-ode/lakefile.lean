import Lake
open Lake DSL

package genesis_ode where
  leanOptions := {}
  moreLeanArgs := #[]

require mathlib from git "https://github.com/leanprover-community/mathlib4" @ "master"

lean_lib GenesisOde where
  srcDir := "lean"
  moreLeanArgs := #[]
lean_exe FullTestSuite where
  supportInterpreter := true

lean_exe EquivalenceProofs where
  supportInterpreter := true
