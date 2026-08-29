import Lake

open Lake DSL

package «the_genius_adr» where
  buildType := .release
  moreLeancArgs := #["-fPIC"]

@[default_target]
lean_lib «TheGeniusAdr» where
