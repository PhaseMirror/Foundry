import Multiplicity.Lake
open Lake DSL

package «lean-proofs» where
  moreServerArgs := #["-DwarningAsError=true"]
  -- warn.sorry = true

lean_lib «UAC_Invariants» where
  -- add library configuration options here

lean_lib MTPI where
  roots := #[`MTPI.ADR, `MTPI.Proofs, `MTPI.Examples, `MTPI.SedonaSpine, `MTPI.WasmSDK, `MTPI.Lifebushido, `MTPI.PhaseMirror, `MTPI.ZkPrivacy, `MTPI.AgentContracts]

@[default_target]
lean_exe «verify» where
  root := `Main
