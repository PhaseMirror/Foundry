/-
F1 square — exact cycle/closed-walk counts (R6), as kernel-checked `decide` theorems.

Companion `characteristic_1_constructions.md` R6 (Bowen–Lanford trace identity): for the running
example graph with 0/1 adjacency `B`, the closed-walk counts are `N_m = tr(Bᵐ)`, and the document
asserts `N_1 … N_8 = 0, 2, 6, 2, 10, 14, 14, 34`. Here those are turned from "verified in our
runtime" (un-kernel-checked numerics) into **kernel-checked** theorems: each is `by decide` over
exact integer matrix powers — the UOR exact-arithmetic discipline (no floats). Pure Lean 4.

Example edges (companion §0): 0→1, 0→3, 1→2, 2→0, 2→3, 3→2.
-/

namespace UOR.Bridge.F1Square.CycleCounts

/-- A 4×4 integer matrix. -/
abbrev Mat : Type := Fin 4 → Fin 4 → Int

/-- The 0/1 adjacency of the running example graph. -/
def B : Mat := fun i j =>
  match i.val, j.val with
  | 0, 1 => 1
  | 0, 3 => 1
  | 1, 2 => 1
  | 2, 0 => 1
  | 2, 3 => 1
  | 3, 2 => 1
  | _, _ => 0

/-- The identity matrix. -/
def idM : Mat := fun i j => if i = j then 1 else 0

/-- Ordinary 4×4 matrix product. -/
def mul (A C : Mat) : Mat := fun i j =>
  A i 0 * C 0 j + A i 1 * C 1 j + A i 2 * C 2 j + A i 3 * C 3 j

/-- Matrix power. -/
def powM (A : Mat) : Nat → Mat
  | 0     => idM
  | n + 1 => mul (powM A n) A

/-- Trace. -/
def trace (A : Mat) : Int := A 0 0 + A 1 1 + A 2 2 + A 3 3

-- R6: the Bowen–Lanford closed-walk counts `N_m = tr(Bᵐ)`, kernel-checked.

theorem N1 : trace (powM B 1) = 0 := by decide
theorem N2 : trace (powM B 2) = 2 := by decide
theorem N3 : trace (powM B 3) = 6 := by decide
theorem N4 : trace (powM B 4) = 2 := by decide
theorem N5 : trace (powM B 5) = 10 := by decide
theorem N6 : trace (powM B 6) = 14 := by decide
theorem N7 : trace (powM B 7) = 14 := by decide
theorem N8 : trace (powM B 8) = 34 := by decide

end UOR.Bridge.F1Square.CycleCounts
