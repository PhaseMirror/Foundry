import Lake
open Lake DSL

package «bridge» where

lean_lib Bridge where
  srcDir := "src"
  precompileModules := true

require «moc-core» from ".."
