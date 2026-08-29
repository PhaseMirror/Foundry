import Lake

open Lake DSL

package «ataraxia_adr» where
  buildType := .release
  moreLeancArgs := #["-fPIC"]

@[default_target]
lean_lib «AtaraxiaAdr» where
