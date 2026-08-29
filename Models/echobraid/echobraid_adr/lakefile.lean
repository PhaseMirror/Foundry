import Lake

open Lake DSL

package «echobraid_adr» where
  buildType := .release
  moreLeancArgs := #["-fPIC"]

@[default_target]
lean_lib «EchobraidAdr» where
