import Lake

open Lake DSL

package «finton_adr» where
  buildType := .release
  moreLeancArgs := #["-fPIC"]

@[default_target]
lean_lib «FintonAdr» where
