import Lake
open Lake DSL

package «axiom-clean» where
  -- Strictly no Mathlib allowed here

lean_lib AxiomCleanCore where
  srcDir := "src"
