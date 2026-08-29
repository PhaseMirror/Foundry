import Lake
open Lake DSL

require mathlib from git "https://github.com/leanprover-community/mathlib4" @ "master"

package foundations

@[default_target]
lean_lib Foundations where
  roots := #[`Foundations]
