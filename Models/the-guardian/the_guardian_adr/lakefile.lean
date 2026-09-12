import Lake

open Lake DSL

package «the_guardian_adr» where
  buildType := .release
  moreLeancArgs := #["-fPIC"]

@[default_target]
lean_lib «TheGuardianAdr» where
