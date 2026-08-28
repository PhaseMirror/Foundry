import Lake

open Lake DSL

package «generalist_adr» where
  buildType := .release
  moreLeancArgs := #["-fPIC"]

@[default_target]
lean_lib «GeneralistAdr» where
