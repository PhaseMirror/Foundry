import Lake
open Lake DSL

package «lean-proofs» where
  moreServerArgs := #["-DwarningAsError=true"]
  -- warn.sorry = true

lean_lib «UAC_Invariants» where
  -- add library configuration options here

@[default_target]
lean_exe «verify» where
  root := `Main
