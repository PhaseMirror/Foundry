import Lake
open Lake DSL

-- Self-contained GRIMS+ / PIRTM formalization.
-- No Mathlib, no Std: depends only on Lean 4 `Init` (Rat, LinearOrderedField, List).
package GRIMS

lean_lib GRIMS where
  roots := #[`GRIMS]
