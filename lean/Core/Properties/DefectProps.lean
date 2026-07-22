import Core.universal_closure.DefectAlgebra
import Core.universal_closure.UniversalClosure

/-!
# Defect Properties — Specification Only
-/

open Defect in
def CompositionalDefectSpec {X : Type} {U : UC X} (hd : HasDefect U) : Prop :=
  ∀ x y, (hd.mu (U.compose x y)) ≤
    (Defect.add (Defect.add (hd.mu x) (hd.mu y)) (hd.binary_residual x y))

open Defect in
def ClosureReducesDefectSpec {X : Type} {U : UC X} (hd : HasDefect U) : Prop :=
  ∀ x, (hd.mu (U.closure x)) ≤ (hd.mu x)
