/-
F1 square — **certified integration, brick 75** (`DyadicApprox.lean`): **EVERY RATIONAL IN `[0,1)`
HAS A DYADIC POINT WITHIN `1/2^m`** — the constructive floor the density extension of brick 74
was missing:

    `0 ≤ q < 1`  ⟹  `∃ j < 2^m`,  `|q − j/2^m| ≤ 1/2^m`   (`dyadApprox_spec`, `dyadJ_lt`).

Brick 74 proved `∫₀¹ φ² ≈ 0 ⟹ φ(p) ≈ 0` at **dyadic** `p`, and noted the extension to all real
points needs a way to *find* a dyadic point near an arbitrary one. This supplies it, and it is
where the constructivity actually lives: one cannot locate a **real** (given `x` there is no
deciding `x ≤ 1/2`), but one *can* locate a **rational**, because `ℚ` has decidable order and
`ℕ` division is computable. Since every real comes with rational approximants `x.seq N` of known
accuracy, locating the rational is enough.

The witness is `⌊q·2^m⌋`, computed as the `ℕ` division `(n·2^m)/d` on `q = n/d`. Its correctness
is the division algorithm and nothing else: `d·j + r = n·2^m` with `r < d` gives
`0 ≤ n·2^m − j·d < d`, which is exactly `|q − j/2^m| ≤ 1/2^m` after clearing denominators. No
real is compared to anything.

HONEST SCOPE. This is the *rational* half of the density argument, complete and self-contained.
The assembly — pushing it through `x.seq N` to a real `x`, and then through brick 74b's
`sq_ge_on_piece_near` to conclude `φ(x) ≈ 0` for **every** `x ∈ [0,1]` — is **not** performed
here. Until it is, brick 74's definiteness remains stated at dyadic points. Nothing here touches
the Weil form. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.L2Definite

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The dyadic floor index** of a rational at depth `m`: `⌊q·2^m⌋`, computed as `ℕ` division.
    (`q.num.toNat` is the numerator; the caller supplies `0 ≤ q.num`.) -/
def dyadJ (q : Q) (m : Nat) : Nat := (q.num.toNat * 2 ^ m) / q.den

/-- The division algorithm, spelled out. (`omega` is NOT usable here: on a division with a
    VARIABLE divisor it reasons classically and pulls `Classical.choice`, which the honesty gate
    rejects. The two `calc`s below are the same facts, choice-free.) -/
private theorem bracket_core (n d : Nat) (hd : 0 < d) :
    d * (n / d) ≤ n ∧ n < d * (n / d) + d := by
  refine ⟨?_, ?_⟩
  · calc d * (n / d) ≤ d * (n / d) + n % d := Nat.le_add_right _ _
      _ = n := Nat.div_add_mod n d
  · calc n = d * (n / d) + n % d := (Nat.div_add_mod n d).symm
      _ < d * (n / d) + d := Nat.add_lt_add_left (Nat.mod_lt n hd) _

/-- **The floor bracket**: `d·j ≤ n·2^m < d·j + d` — the division algorithm, nothing more. -/
theorem dyadJ_bracket (q : Q) (hd : 0 < q.den) (m : Nat) :
    q.den * dyadJ q m ≤ q.num.toNat * 2 ^ m
    ∧ q.num.toNat * 2 ^ m < q.den * dyadJ q m + q.den :=
  bracket_core (q.num.toNat * 2 ^ m) q.den hd

/-- **The index fits below `2^m`** when `q < 1` (as `q.num.toNat < q.den`). -/
theorem dyadJ_lt (q : Q) (hd : 0 < q.den) (hq : q.num.toNat < q.den) (m : Nat) :
    dyadJ q m < 2 ^ m := by
  have hpow : 0 < 2 ^ m := two_pow_pos m
  obtain ⟨hlo, _⟩ := dyadJ_bracket q hd m
  have hstep : q.num.toNat * 2 ^ m < q.den * 2 ^ m :=
    Nat.mul_lt_mul_of_lt_of_le hq (Nat.le_refl _) hpow
  -- `Nat.lt_of_mul_lt_mul_left` pulls `Classical.choice`; this cancellation is choice-free.
  have hmul : q.den * dyadJ q m < q.den * 2 ^ m := Nat.lt_of_le_of_lt hlo hstep
  rcases Nat.lt_or_ge (dyadJ q m) (2 ^ m) with hh | hh
  · exact hh
  · exact absurd hmul (Nat.not_lt.mpr (Nat.mul_le_mul_left q.den hh))

/-- The `Int` core of the approximation bound: with `0 ≤ n·P − j·d < d`, the scaled numerator is
    non-negative and bounded by `d·P`. -/
private theorem approx_core (N P J D : Int) (hPnn : 0 ≤ P)
    (hlo : D * J ≤ N * P) (hhi : N * P < D * J + D) :
    (0 : Int) ≤ N * P + (-J) * D ∧ (N * P + (-J) * D) * P ≤ 1 * (D * P) := by
  have e : (-J) * D = -(D * J) := by ring_uor
  refine ⟨by rw [e]; omega, ?_⟩
  have hb : N * P + (-J) * D ≤ D := by rw [e]; omega
  have hm := Int.mul_le_mul_of_nonneg_right hb hPnn
  have e2 : (1 : Int) * (D * P) = D * P := by ring_uor
  rw [e2]
  exact hm

/-- **THE APPROXIMATION, over abstract `ℕ` data** — stated so every product is a variable, which
    is what keeps `push_cast`/`omega` on the rails (a literal `2^m` gets decomposed and then the
    two sides no longer share atoms). -/
theorem dyadApprox_gen (num : Int) (den P j : Nat) (hd : 0 < den) (hn : 0 ≤ num)
    (hlo : den * j ≤ num.toNat * P) (hhi : num.toNat * P < den * j + den) :
    Qle (Qabs (Qsub (⟨num, den⟩ : Q) (⟨(j : Int), P⟩ : Q))) (⟨1, P⟩ : Q) := by
  have hnum : ((num.toNat : Nat) : Int) = num := Int.toNat_of_nonneg hn
  have hloZ : ((den : Nat) : Int) * ((j : Nat) : Int) ≤ num * ((P : Nat) : Int) := by
    have h := Int.ofNat_le.mpr hlo
    push_cast at h
    rw [← hnum]
    push_cast
    exact h
  have hhiZ : num * ((P : Nat) : Int)
      < ((den : Nat) : Int) * ((j : Nat) : Int) + ((den : Nat) : Int) := by
    have h := Int.ofNat_lt.mpr hhi
    push_cast at h
    rw [← hnum]
    push_cast
    exact h
  obtain ⟨hz, hb⟩ := approx_core num ((P : Nat) : Int) ((j : Nat) : Int) ((den : Nat) : Int)
    (Int.ofNat_nonneg P) hloZ hhiZ
  show ((Int.natAbs (num * ((P : Nat) : Int) + (-((j : Nat) : Int)) * ((den : Nat) : Int))
      : Nat) : Int) * ((P : Nat) : Int) ≤ 1 * (((den * P : Nat)) : Int)
  rw [Int.natAbs_of_nonneg hz]
  have e : (1 : Int) * (((den * P : Nat)) : Int)
      = 1 * (((den : Nat) : Int) * ((P : Nat) : Int)) := by push_cast; ring_uor
  rw [e]
  exact hb

/-- **THE APPROXIMATION**: `|q − ⌊q·2^m⌋/2^m| ≤ 1/2^m` for every `q ≥ 0`. -/
theorem dyadApprox_spec (q : Q) (hd : 0 < q.den) (hn : 0 ≤ q.num) (m : Nat) :
    Qle (Qabs (Qsub q (⟨((dyadJ q m : Nat) : Int), 2 ^ m⟩ : Q))) (⟨1, 2 ^ m⟩ : Q) := by
  obtain ⟨hlo, hhi⟩ := dyadJ_bracket q hd m
  exact dyadApprox_gen q.num q.den (2 ^ m) (dyadJ q m) hd hn hlo hhi

end Multiplicity.UOR.Bridge.F1Square.Square
