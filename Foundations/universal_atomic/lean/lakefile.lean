import Lake
open Lake DSL

package uacLean {
  defaultFacets := {lean}
  srcDir := "src"
}

lean_lib UacLean {
  root := "src"
}
