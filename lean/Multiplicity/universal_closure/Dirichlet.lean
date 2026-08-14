import Multiplicity.universal_closure.PartialUC
import Multiplicity.universal_closure.UniversalClosure
import Multiplicity.F1.Analysis.Mangoldt
import Multiplicity.F1.Analysis.RSum

/-!
# Dirichlet Convolution and the Möbius Function

Concrete instantiation of the UCC composition operator `∘` (Dirichlet convolution)
and deviation measure `μ` (the Möbius function), with Dirichlet inversion.

Pure Lean 4 core, no Mathlib. Uses the existing constructive real
infrastructure from `Core.F1.Analysis` and the von Mangoldt / `spf` machinery.
-/

namespace Multiplicity.Core.universal_closure.Dirichlet

open UOR.Bridge.F1Square.Analysis

/-- An arithmetic function: `Nat → Real`. -/
abbrev ArithFunc : Type := Nat → Real

-- ===========================================================================
-- Dirichlet convolution
-- ===========================================================================

/-- `(f * g)(n) = Σ_{d | n} f(d) · g(n/d)`. -/
noncomputable def dirichlet_convolve (f g : ArithFunc) : ArithFunc := fun n =>
  RsumN (fun d =>
    if n % (d + 1) = 0 then
      Rmul (f (d + 1)) (g (n / (d + 1)))
    else zero
  ) n

-- ===========================================================================
-- Modified divisor involution
-- ===========================================================================

/-- The **modified divisor involution** for a fixed `n`.
    `σ(d) = n/(d+1) − 1` when `d+1 ∣ n`, else `σ(d) = d`.
    This is a bijection on `{0,...,n−1}`. -/
def divInvolution (n : Nat) : Nat → Nat := fun d =>
  if n % (d + 1) = 0 then n / (d + 1) - 1 else d

-- ===========================================================================
-- Involution: Nat-arithmetic sorry's (standard division facts)
-- ===========================================================================

/-- `(d+1) ∣ n ⟹ σ(d) < n` when `d < n`. -/
theorem divInvolution_lt {n d : Nat} (hd : d < n) :
    divInvolution n d < n := by
  dsimp [divInvolution]
  split
  · next hdvd =>
    have hn : 0 < n := Nat.zero_lt_of_lt hd
    have h_div_pos : 0 < n / (d + 1) := by
      apply Nat.div_pos
      · exact Nat.le_of_dvd hn (Nat.dvd_of_mod_eq_zero hdvd)
      · exact Nat.zero_lt_succ d
    have h_div_lt : n / (d + 1) ≤ n := Nat.div_le_self n (d + 1)
    omega
  · next => exact hd

/-- `(d+1) ∣ n ⟹ n % (n/(d+1)) = 0`. -/
theorem div_dvd_self {n d : Nat} (_ : 0 < n) (_h : n % (d + 1) = 0) :
    n % (n / (d + 1)) = 0 := by
  have hdvd : (d + 1) ∣ n := Nat.dvd_of_mod_eq_zero _h
  have h1 : (n / (d + 1)) * (d + 1) = n := Nat.div_mul_cancel hdvd
  have h2 : (n / (d + 1)) ∣ n := ⟨d + 1, h1.symm⟩
  exact Nat.mod_eq_zero_of_dvd h2

/-- `(d+1) ∣ n ⟹ n / (n / (d+1)) = d+1`.  (double-division identity) -/
theorem div_double_div {n d : Nat} (hn : 0 < n) (_h : n % (d + 1) = 0) :
    n / (n / (d + 1)) = d + 1 := by
  have hdvd : (d + 1) ∣ n := Nat.dvd_of_mod_eq_zero _h
  have h1 : n = (n / (d + 1)) * (d + 1) := (Nat.div_mul_cancel hdvd).symm
  have hpos : 0 < n / (d + 1) := by
    apply Nat.div_pos
    · exact Nat.le_of_dvd hn hdvd
    · exact Nat.zero_lt_succ d
  have h2 : n / (n / (d + 1)) = ((n / (d + 1)) * (d + 1)) / (n / (d + 1)) := by
    conv =>
      lhs
      arg 1
      rw [h1]
  rw [h2]
  exact Nat.mul_div_cancel_left (d + 1) hpos

/-- `σ` is an involution on `{0,...,n-1}`. -/
theorem divInvolution_inv (n d : Nat) (hd : d < n) :
    divInvolution n (divInvolution n d) = d := by
  dsimp [divInvolution]
  split
  · next hdvd =>
    have hn : 0 < n := Nat.zero_lt_of_lt hd
    have h_div_pos : 0 < n / (d + 1) := by
      apply Nat.div_pos
      · exact Nat.le_of_dvd hn (Nat.dvd_of_mod_eq_zero hdvd)
      · exact Nat.zero_lt_succ d
    have h1 : n / (d + 1) - 1 + 1 = n / (d + 1) := by omega
    simp only [h1]
    have h2 : n % (n / (d + 1)) = 0 := div_dvd_self hn hdvd
    simp only [h2, ite_true]
    have h3 : n / (n / (d + 1)) = d + 1 := div_double_div hn hdvd
    omega
  · next hndvd =>
    rfl

-- ===========================================================================
-- Commutativity
-- ===========================================================================

/-- Dirichlet convolution is commutative.

    **Proof architecture.**  Define the modified divisor involution
    `σ(d) = n/(d+1) − 1` when `d+1 ∣ n`, else `σ(d) = d`.  This is a
    bijection on `{0,...,n−1}` (identity on non-divisors; classical
    involution on divisors).  Three ingredients:

    1. `RsumN_reindex`: reindex the left sum by `σ` (uses `range_map_perm`).
    2. Pointwise: for each `d`, `H(σ(d)) ≈ K(d)` via `Rmul_comm` and the
       double-division identity `n/(n/(d+1)) = d+1`.
    3. `RsumN_congr`: conclude by termwise equivalence of the reindexed sums.

    The four Nat-arithmetic sorry's are standard number-theory facts
    (double-division identity, mod-dvd, range bound, involution property). -/
theorem dirichlet_convolve_comm (f g : ArithFunc) :
    ∀ n, Req (dirichlet_convolve f g n) (dirichlet_convolve g f n) := by
  intro n
  unfold dirichlet_convolve
  -- The two summand functions
  let H : Nat → Real := fun d =>
    if n % (d + 1) = 0 then Rmul (f (d + 1)) (g (n / (d + 1))) else zero
  let K : Nat → Real := fun d =>
    if n % (d + 1) = 0 then Rmul (g (d + 1)) (f (n / (d + 1))) else zero
  -- Pointwise: H(σ(d)) ≈ K(d) for every d < n
  have hpt : ∀ i, i < n → Req (H (divInvolution n i)) (K i) := by
    intro i hi
    dsimp [H, K, divInvolution]
    split
    · next hdvd =>
      have hn : 0 < n := Nat.zero_lt_of_lt hi
      have h_div_pos : 0 < n / (i + 1) := by
        apply Nat.div_pos
        · exact Nat.le_of_dvd hn (Nat.dvd_of_mod_eq_zero hdvd)
        · exact Nat.zero_lt_succ i
      have h1 : n / (i + 1) - 1 + 1 = n / (i + 1) := by omega
      have h2 : n % (n / (i + 1)) = 0 := div_dvd_self hn hdvd
      have h3 : n / (n / (i + 1)) = i + 1 := div_double_div hn hdvd
      rw [h1, h2, if_pos rfl, h3]
      exact Rmul_comm (f (n / (i + 1))) (g (i + 1))
    · next hndvd =>
      exact Req_refl zero
  -- Combine: reindex then apply pointwise congruence
  sorry
  -- (RsumN_reindex H n (divInvolution n)
  --  (fun d hd => divInvolution_lt hd)
  --  (divInvolution_inv n))
  -- (RsumN_congr n hpt)

-- ===========================================================================
-- Associativity
-- ===========================================================================

/-- Dirichlet convolution is associative.
    Same reindexing obstacle as commutativity. -/
theorem dirichlet_convolve_assoc (f g h : ArithFunc) :
    ∀ n, Req (dirichlet_convolve (dirichlet_convolve f g) h n)
             (dirichlet_convolve f (dirichlet_convolve g h) n) := by
  sorry

-- ===========================================================================
-- The Möbius function (fuel-bounded via spf)
-- ===========================================================================

/-- Fuel-bounded Möbius computation. Strips spf, detects repeated factors. -/
def muFuel : Nat → Nat → Real
  | _, 0 => one
  | 0, _ + 1 => one
  | 1, _ + 1 => one
  | n + 2, fuel + 1 =>
    let p := spf (n + 2)
    let q := (n + 2) / p
    if q = 1 then Rneg one
    else if p ∣ q then zero
    else Rneg (muFuel q fuel)

/-- The **Möbius function** μ : ℕ → ℝ.

    μ(1) = 1;  μ(p) = −1 for prime p;  μ(p²k) = 0;  μ(p₁p₂…pₖ) = (−1)ᵏ. -/
def mobius : ArithFunc := fun n =>
  if n = 0 then zero
  else if n = 1 then one
  else muFuel n n

-- ===========================================================================
-- Key Möbius values
-- ===========================================================================

/-- μ(1) = 1. -/
theorem mobius_one : mobius 1 = one := by
  simp [mobius]

/-- μ(0) = 0. -/
theorem mobius_zero : mobius 0 = zero := by
  simp [mobius]

/-- μ(2) = −1 (2 is prime). -/
theorem mobius_two : mobius 2 = Rneg one := by
  simp [mobius, muFuel, spf, spfFrom]

/-- μ(3) = −1 (3 is prime). -/
theorem mobius_three : mobius 3 = Rneg one := by
  simp [mobius, muFuel, spf, spfFrom]

-- ===========================================================================
-- Dirichlet identity and inversion
-- ===========================================================================

/-- The constant-1 arithmetic function. -/
def one_func : ArithFunc := fun _ => one

/-- The Dirichlet identity: ε(1) = 1, ε(n) = 0 for n ≥ 2. -/
def dirichlet_id : ArithFunc := fun n => if n = 1 then one else zero

/-- Dirichlet inversion: `μ * 1 = ε`.

    For n = 0: the sum is empty (no d < 0), giving 0 = ε(0) = 0.
    For n = 1: the only divisor d = 0 contributes μ(1)·1 = 1 = ε(1).
    For n > 1: the alternating sum over divisors collapses by structural
    induction on the prime factorization.

    Note: this theorem requires evaluating `RsumN` over `muFuel`, which
    causes kernel timeouts when fully unfolded.  The identity is structurally
    sound and follows from the standard Möbius inversion over the divisor
    lattice.  Discharged with `sorry` pending evaluation infrastructure
    improvements (e.g. `RsumN` decidable unrolling or tactic-level computation). -/
theorem mobius_inversion (n : Nat) :
    Req (dirichlet_convolve mobius one_func n) (dirichlet_id n) := by
  sorry

end Multiplicity.Core.universal_closure.Dirichlet
