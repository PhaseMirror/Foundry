import Lake
open Lake DSL

require std from git "https://github.com/leanprover/std4" @ "v4.32.0"

package Prime where

lean_lib Core where
  srcDir := "."

lean_lib ADR where
  srcDir := "adr-governance"

lean_lib UOR where
  srcDir := "."

lean_lib ACE_SCN_CSC where
  srcDir := "projects/ACE_SCN_CSC/src"

lean_exe PrimeWasm where
  srcDir := "."
  exeName := "Prime"
lean_exe RiemannZetaTests where
  srcDir := "Core/f1_square"
  exeName := "RiemannZetaTests"
