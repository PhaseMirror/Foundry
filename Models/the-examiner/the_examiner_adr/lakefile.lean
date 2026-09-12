import Lake

open Lake DSL

package «the_examiner_adr» where
  buildType := .release
  moreLeancArgs := #["-fPIC"]

@[default_target]
lean_lib «TheExaminerAdr» where
