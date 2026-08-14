import Lake
open Lake DSL

package "Prime"

lean_lib Multiplicity {
  srcDir := "lean"
}

lean_lib Prime {
  srcDir := "."
}

@[default_target]
lean_lib PhaseMirror {
  roots := #[`PhaseMirror]
}
