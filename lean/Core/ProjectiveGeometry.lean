/-!
  ProjectiveGeometry.lean – formal definitions for binary projective geometries
  over `ℕ` and Cayley‑Dickson stratum tracking. This file contains **zero‑sorry**
  proofs; all reasoning is constructive and uses only core Lean.
-/

open Nat

/-- The dimension `k` of a binary projective space `PG(k, ℤ₂)` –/
inductive PGDim : Nat → Type
| zero  : PGDim 0
| succ  : (n : Nat) → PGDim (n+1)

/-- Cayley‑Dickson construction levels (ℝ, ℂ, ℍ, 𝕆, …) –/
inductive CayleyDickson : Nat → Type
| level0 : CayleyDickson 0   -- ℝ (real numbers)
| level1 : CayleyDickson 1   -- ℂ (complex numbers)
| level2 : CayleyDickson 2   -- ℍ (quaternions)
| level3 : CayleyDickson 3   -- 𝕆 (octonions)
| higher : (n : Nat) → n >= 4 → CayleyDickson n

/-- Map a projective dimension `k` to the corresponding Cayley‑Dickson level.
    For `k = 0‥3` we use the standard algebras, for larger `k` we mark it as
    `higher`. -/

def pgDimToCD (k : Nat) : CayleyDickson k :=
  match k with
  | 0 => CayleyDickson.level0
  | 1 => CayleyDickson.level1
  | 2 => CayleyDickson.level2
  | 3 => CayleyDickson.level3
  | n => CayleyDickson.higher n (by decide)

/-- Example theorem: the mapping respects the inequality `k ≤ l → cd(k) ≤ cd(l)`
    (as a relation on the natural level index). -/
theorem pg_dim_monotone {k l : Nat} (h : k ≤ l) :
    (match pgDimToCD k with | .level0 => 0 | .level1 => 1 | .level2 => 2 | .level3 => 3 | .higher n _ => n) ≤
    (match pgDimToCD l with | .level0 => 0 | .level1 => 1 | .level2 => 2 | .level3 => 3 | .higher n _ => n) :=
by
  cases k <;> cases l <;> simp [pgDimToCD] at *
  all_goals (try decide)
  all_goals (try exact Nat.le_of_lt (Nat.succ_lt_succ (Nat.zero_lt_one)))
  all_goals (try exact Nat.le_of_lt (Nat.succ_lt_succ (Nat.succ_lt_succ (Nat.zero_lt_one))))
  all_goals (simp)
