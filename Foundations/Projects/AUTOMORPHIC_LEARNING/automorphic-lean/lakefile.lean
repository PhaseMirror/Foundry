import Lake
open Lake DSL

package AutomorphicLean where
  version := v!"0.1.0"

@[default_target]
lean_lib Automorphic where
  srcDir := "."
  roots := #[`Automorphic]
