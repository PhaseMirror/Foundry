import Multiplicity.Multiplicity.Prime

/-!
# Multiplicity Kernel — Factorization (ADR-0001 Phase 1 scope)

The kernel defines the prime valuation `valuation p n` (the exponent of the
prime `p` in `n`) and an executable `primeFactors` list built from it, plus
product-reconstruction laws.  The full unique-factorisation theorem is a
documented classical gap; the executable witnesses below mirror the Rust
factorizer.
-/

namespace Multiplicity.Kernel

/-- Largest `k ≤ bound` with `p ^ k ∣ n`; structurally recursive, total. -/
def valuationAux (p : Nat) (n : Nat) : Nat → Nat
  | 0 => 0
  | k + 1 =>
      if _hd : p ^ (k + 1) ∣ n then k + 1 else valuationAux p n k

/-- The valuation of `p` in `n` (exponent of the largest power of `p`
dividing `n`).  For `n = 0` the convention is `0`. -/
def valuation (p n : Nat) : Nat :=
  if n = 0 then 0 else valuationAux p n n

/-- Computation rule at zero. -/
theorem valuationAux_zero (p n : Nat) : valuationAux p n 0 = 0 := rfl

/-- Computation rule for successors. -/
theorem valuationAux_succ (p n k : Nat) :
    valuationAux p n (k + 1) = if p ^ (k + 1) ∣ n then k + 1 else valuationAux p n k :=
  rfl

/-- The valuation of zero is zero by convention. -/
theorem valuation_zero (p : Nat) : valuation p 0 = 0 := by
  simp [valuation]

/-- A power of `p` divides a smaller power only when the exponent orders
match (`p ≥ 2`). -/
theorem pow_dvd_pow_le {p a b : Nat} (hp : 2 ≤ p) (h : p ^ a ∣ p ^ b) : a ≤ b := by
  by_cases hab : a ≤ b
  · exact hab
  · have hb : b < a := Nat.lt_of_not_ge hab
    have hba : b + 1 ≤ a := Nat.succ_le_of_lt hb
    have hdiv : p ^ (b + 1) ∣ p ^ b := Nat.dvd_trans (Nat.pow_dvd_pow p hba) h
    have hpos : 0 < p ^ b := Nat.pow_pos (by omega)
    have hle : p ^ (b + 1) ≤ p ^ b := Nat.le_of_dvd hpos hdiv
    have hge : p ^ b ≤ p ^ (b + 1) := Nat.pow_le_pow_right (by omega) (by omega)
    have heq : p ^ (b + 1) = p ^ b := Nat.le_antisymm hle hge
    have h2 : p ^ b * p = p ^ b := by
      rw [← Nat.pow_succ]
      exact heq
    have hcancel : p = 1 := Nat.eq_of_mul_eq_mul_left hpos (by simpa using h2)
    omega

/-- For `p ≥ 2`, the powers `p ^ k` strictly exceed `k`. -/
theorem pow_gt_self {p k : Nat} (hp : 2 ≤ p) : k < p ^ k := by
  induction k with
  | zero => simp
  | succ k ih =>
      calc
        k + 1 < 2 * (k + 1) := by omega
        _ ≤ 2 * p ^ k := by
            have hk : k + 1 ≤ p ^ k := Nat.succ_le_of_lt ih
            exact Nat.mul_le_mul_left 2 hk
        _ ≤ p * p ^ k := Nat.mul_le_mul_right (p ^ k) (by omega)
        _ = p ^ (k + 1) := by simp [Nat.pow_succ, Nat.mul_comm]

/-- When `m ≤ k`, the count-down search stops exactly at `m` for `n = p ^ k`. -/
theorem valuationAux_pow_of_le {p k m : Nat} (hm : m ≤ k) :
    valuationAux p (p ^ k) m = m := by
  induction m with
  | zero => rfl
  | succ m ih =>
      rw [valuationAux_succ]
      have hdiv : p ^ (m + 1) ∣ p ^ k := Nat.pow_dvd_pow p (by omega : m + 1 ≤ k)
      simp [hdiv]

/-- When `k < m`, the count-down search from `m` stops at `k` for `n = p ^ k`. -/
theorem valuationAux_pow_of_gt {p k m : Nat} (hp : 2 ≤ p) (hm : k < m) :
    valuationAux p (p ^ k) m = k := by
  induction m with
  | zero => omega
  | succ m ih =>
      rw [valuationAux_succ]
      by_cases hkm : k < m
      · have hnd : ¬ p ^ (m + 1) ∣ p ^ k := by
          intro hd
          have hle := pow_dvd_pow_le hp hd
          omega
        simp [hnd, ih hkm]
      · have hmk : m ≤ k := Nat.le_of_not_gt hkm
        have hk2 : k ≤ m := by omega
        have heq : m = k := Nat.le_antisymm hmk hk2
        subst m
        have hnd : ¬ p ^ (k + 1) ∣ p ^ k := by
          intro hd
          have hle := pow_dvd_pow_le hp hd
          omega
        simp [hnd]
        exact valuationAux_pow_of_le (by omega)

/-- A prime divides `p ^ k` to exactly the power `k`. -/
theorem valuation_pow_self {p k : Nat} (hp : 2 ≤ p) : valuation p (p ^ k) = k := by
  unfold valuation
  have hp0 : p ≠ 0 := by omega
  simp [hp0]
  apply valuationAux_pow_of_gt
  · exact hp
  · exact pow_gt_self hp

/-- The valuation of a product of two powers of the same prime. -/
theorem valuation_mul_pow {p a b : Nat} (hp : 2 ≤ p) :
    valuation p (p ^ a * p ^ b) = a + b := by
  rw [← Nat.pow_add]
  exact valuation_pow_self hp

/-- Executable witnesses for the valuation. -/
example : valuation 2 12 = 2 := by native_decide
example : valuation 3 27 = 3 := by native_decide
example : valuation 2 16 = 4 := by native_decide
example : valuation 5 100 = 2 := by native_decide

/-- The list of prime factors with multiplicity, in increasing order. -/
def primeFactors (n : Nat) : List Nat :=
  ((List.range (n + 1)).filterMap
    (fun p => if isPrime p then some (List.replicate (valuation p n) p) else none)).flatten

/-- The product of a factor list. -/
def factorProduct (fs : List Nat) : Nat := fs.prod

/-- The product of an empty list is one. -/
theorem factorProduct_nil : factorProduct [] = 1 := rfl

/-- The product of a cons is the head times the tail product. -/
theorem factorProduct_cons (f : Nat) (fs : List Nat) :
    factorProduct (f :: fs) = f * factorProduct fs := rfl

/-- Executable factorizations mirroring the Rust factorizer. -/
example : primeFactors 12 = [2, 2, 3] := by native_decide
example : primeFactors 18 = [2, 3, 3] := by native_decide
example : primeFactors 97 = [97] := by native_decide
example : factorProduct (primeFactors 12) = 12 := by native_decide
example : factorProduct (primeFactors 210) = 210 := by native_decide

/-!
The fundamental theorem of arithmetic (existence and uniqueness of the
factorization of every `n > 0`, i.e. `factorProduct (primeFactors n) = n`
for all `n`) is a documented gap of this minimal kernel: its proof needs the
full Euclidean algorithm and Bézout development.  The equality above is
certified on concrete inputs, and the Rust + Kani factorizer carries the
executable contract.
-/

end Multiplicity.Kernel
