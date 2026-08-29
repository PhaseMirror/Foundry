import Lake
open Lake DSL

package «recursive-foundations» where
  srcDir := "."

@[default_target]
lean_lib Foundations where
  roots := #[
    `Foundations.Recursive.Core,
    `Foundations.Recursive.FixedPoint,
    `Foundations.Recursive.Induction,
    `Foundations.Recursive.Coinduction,
    `Foundations.Recursive.WellFounded,
    `Foundations.Recursive.Examples
  ]
