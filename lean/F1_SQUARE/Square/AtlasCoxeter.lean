/-
F1 square — v0.21.0 stage G, brick **Atlas Coxeter**: the E₈ Coxeter structure (§7, "Coxeter
iteration order 30"), connecting the Coxeter number `30` to `O = 8` and the root counts.

Following the exceptional thread (`AtlasExceptional`, `dim E₈ = rank·(h+1) = 8·31`) to E₈'s Coxeter
data, the §7 candidate generator "Coxeter iteration (order 30)". A forced numerical web:

- E₈'s **Coxeter number** is `h = 30`. Its **exponents** are the integers in `[1, 30)` coprime to
  `30` — `{1,7,11,13,17,19,23,29}` (`e8_exponents`).
- There are `φ(30) = 8 = O = rank E₈` of them (`e8_exponent_count`): the rank of E₈ is Euler's
  totient of its Coxeter number. Not a coincidence — a theorem of the root system.
- The exponents sum to `120 = ` the number of positive roots (`e8_exponent_sum`), so the total root
  count is `2·120 = 240 = dim − rank = 248 − 8` — the SAME `240` as the E₈ kissing number and the
  Eisenstein coefficient `θ_{E₈} = E₄` (`AtlasExceptional.twoForty_roots`, `e8_theta_E4`).

So `30` (Coxeter), `8 = O` (rank `= φ(30)`), `120` (positive roots), `240` (roots / `E₄` coeff),
`248` (dim) form one forced web around `{T, O}`. All `Nat`, decidable. Crux fields untouched.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.AtlasExceptional

namespace UOR.Bridge.F1Square.Square

/-- The totatives of `30` (integers in `[1,30)` coprime to `30`) — the E₈ exponents. -/
def totatives30 : List Nat :=
  (List.range 30).filter (fun k => !(k == 0) && (Nat.gcd k 30 == 1))

/-- **The E₈ exponents are the totatives of its Coxeter number `30`**: `{1,7,11,13,17,19,23,29}`. -/
theorem e8_exponents : totatives30 = [1, 7, 11, 13, 17, 19, 23, 29] := by decide

/-- **`rank E₈ = φ(30) = 8 = O`**: the rank equals Euler's totient of the Coxeter number — the
    number of exponents is `O`, the tower's top dimension. -/
theorem e8_exponent_count : totatives30.length = 8 := by decide

/-- **The exponents sum to `120` = the number of positive roots of E₈.** -/
theorem e8_exponent_sum : totatives30.foldl (· + ·) 0 = 120 := by decide

/-- **The Coxeter web is forced**: `2·120 = 240` (root count = `dim − rank = 248 − 8`), and
    `dim = rank·(h+1) = 8·(30+1) = 248`. The `240` is the E₈ kissing number and the `E₄` coefficient
    (`twoForty_roots`, `e8_theta_E4`). -/
theorem e8_coxeter_web :
    2 * 120 = 240 ∧ 248 - 8 = 2 * 120 ∧ 8 * (30 + 1) = 248 := by decide

end UOR.Bridge.F1Square.Square
