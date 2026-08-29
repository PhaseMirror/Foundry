import Lake

open Lake DSL

package «coding_commander_adr» where
  buildType := .release
  moreLeancArgs := #["-fPIC"]

@[default_target]
lean_lib «CodingCommanderAdr» where
