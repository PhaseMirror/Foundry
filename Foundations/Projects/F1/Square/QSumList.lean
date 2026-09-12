/-
F1 square — **rational sums over a variable list** (`QSumList.lean`), co-support depth-existence
sub-brick N₁. The generic co-support member generator (`polyPN`, brick 66) reduced "a member exists at
depth `K`" to "the homogeneous `ℚ`-linear system `Σᵢ cᵢ = 0`, `Σᵢ cᵢ/(i+n+1) = 0` (`n < K`) has a
nonzero solution" — a Gaussian-elimination fact the layer never had. This brick is its substrate: the
sum of a rational-valued function over a `List` of variable indices,

  `qsumL f vars = Σ_{i ∈ vars} f i`,

with the linearity laws (`qsumL_add`, `qsumL_smul`, `qsumL_neg`, `qsumL_congr`, `qsumL_zero`) and the
pivot split `qsumL f vars ≈ f p + qsumL f (vars.erase p)` for `p ∈ vars` — the row operation
elimination performs. Working over a `List` (not a `Nat` range) is what makes "eliminate variable `p`"
clean: `vars.erase p` drops exactly that variable with no reindexing.

HONEST SCOPE. Pure finite rational arithmetic — a `List`-indexed sum and its linear-algebra laws.
No members, no co-support, no positivity yet. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.QOrder

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The sum `Σ_{i ∈ vars} f i` of a rational-valued function over a list of variable indices. -/
def qsumL (f : Nat → Q) : List Nat → Q
  | [] => (⟨0, 1⟩ : Q)
  | i :: rest => add (f i) (qsumL f rest)

/-- The list sum keeps a positive denominator. -/
theorem qsumL_den (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) :
    ∀ vars : List Nat, 0 < (qsumL f vars).den
  | [] => Nat.one_pos
  | i :: rest => add_den_pos (hf i) (qsumL_den f hf rest)

/-- Congruence: pointwise `Qeq` on the members gives `Qeq` of the sums. -/
theorem qsumL_congr {f g : Nat → Q} (h : ∀ i, Qeq (f i) (g i)) :
    ∀ vars : List Nat, Qeq (qsumL f vars) (qsumL g vars)
  | [] => Qeq_refl _
  | i :: rest => Qadd_congr (h i) (qsumL_congr h rest)

/-- The sum of a pointwise-zero function is `0`. -/
theorem qsumL_zero {f : Nat → Q} (h : ∀ i, Qeq (f i) (⟨0, 1⟩ : Q)) :
    ∀ vars : List Nat, Qeq (qsumL f vars) (⟨0, 1⟩ : Q)
  | [] => Qeq_refl _
  | i :: rest =>
      Qeq_trans (b := add (⟨0, 1⟩ : Q) (⟨0, 1⟩ : Q)) (by decide)
        (Qadd_congr (h i) (qsumL_zero h rest)) (by decide)

/-- Additivity: `Σ (f + g) = Σ f + Σ g`. -/
theorem qsumL_add (f g : Nat → Q) (hf : ∀ i, 0 < (f i).den) (hg : ∀ i, 0 < (g i).den)
    (vars : List Nat) :
    Qeq (qsumL (fun i => add (f i) (g i)) vars) (add (qsumL f vars) (qsumL g vars)) := by
  induction vars with
  | nil => show Qeq (⟨0, 1⟩ : Q) (add (⟨0, 1⟩ : Q) (⟨0, 1⟩ : Q)); decide
  | cons i rest ih =>
    show Qeq (add (add (f i) (g i)) (qsumL (fun j => add (f j) (g j)) rest))
      (add (add (f i) (qsumL f rest)) (add (g i) (qsumL g rest)))
    exact Qeq_trans (b := add (add (f i) (g i)) (add (qsumL f rest) (qsumL g rest)))
      (add_den_pos (add_den_pos (hf i) (hg i))
        (add_den_pos (qsumL_den f hf rest) (qsumL_den g hg rest)))
      (Qadd_congr (Qeq_refl _) ih)
      (by simp only [Qeq, add]; push_cast; ring_uor)

/-- Negation commutes with the sum. -/
theorem qsumL_neg (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (vars : List Nat) :
    Qeq (qsumL (fun i => neg (f i)) vars) (neg (qsumL f vars)) := by
  induction vars with
  | nil => show Qeq (⟨0, 1⟩ : Q) (neg (⟨0, 1⟩ : Q)); decide
  | cons i rest ih =>
    show Qeq (add (neg (f i)) (qsumL (fun j => neg (f j)) rest)) (neg (add (f i) (qsumL f rest)))
    exact Qeq_trans (b := add (neg (f i)) (neg (qsumL f rest)))
      (add_den_pos (neg_den_pos (hf i)) (neg_den_pos (qsumL_den f hf rest)))
      (Qadd_congr (Qeq_refl _) ih)
      (by simp only [Qeq, add, neg]; push_cast; ring_uor)

/-- Scalar multiplication (by a constant `c`) commutes with the sum. -/
theorem qsumL_smul (c : Q) (f : Nat → Q) (hc : 0 < c.den) (hf : ∀ i, 0 < (f i).den)
    (vars : List Nat) :
    Qeq (qsumL (fun i => mul c (f i)) vars) (mul c (qsumL f vars)) := by
  induction vars with
  | nil => show Qeq (⟨0, 1⟩ : Q) (mul c (⟨0, 1⟩ : Q)); simp only [Qeq, mul]; ring_uor
  | cons i rest ih =>
    show Qeq (add (mul c (f i)) (qsumL (fun j => mul c (f j)) rest)) (mul c (add (f i) (qsumL f rest)))
    exact Qeq_trans (b := add (mul c (f i)) (mul c (qsumL f rest)))
      (add_den_pos (Qmul_den_pos hc (hf i)) (Qmul_den_pos hc (qsumL_den f hf rest)))
      (Qadd_congr (Qeq_refl _) ih)
      (by simp only [Qeq, add, mul]; push_cast; ring_uor)

/-- **THE PIVOT SPLIT**: a member `p ∈ vars` may be split off, `Σ_{vars} f ≈ f p + Σ_{vars.erase p} f`
    — the row-operation identity Gaussian elimination performs. -/
theorem qsumL_erase (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (p : Nat) (vars : List Nat)
    (hp : p ∈ vars) :
    Qeq (qsumL f vars) (add (f p) (qsumL f (vars.erase p))) := by
  induction vars with
  | nil => simp at hp
  | cons i rest ih =>
    by_cases hip : i = p
    · subst hip
      have herase : (i :: rest).erase i = rest := by simp [List.erase_cons]
      rw [herase]
      exact Qeq_refl _
    · have hprest : p ∈ rest := by
        rcases List.mem_cons.mp hp with h | h
        · exact absurd h.symm hip
        · exact h
      have herase : (i :: rest).erase p = i :: rest.erase p := by
        simp [List.erase_cons, hip]
      rw [herase]
      show Qeq (add (f i) (qsumL f rest))
        (add (f p) (add (f i) (qsumL f (rest.erase p))))
      exact Qeq_trans (b := add (f i) (add (f p) (qsumL f (rest.erase p))))
        (add_den_pos (hf i) (add_den_pos (hf p) (qsumL_den f hf (rest.erase p))))
        (Qadd_congr (Qeq_refl _) (ih hprest))
        (by simp only [Qeq, add]; push_cast; ring_uor)

end Multiplicity.UOR.Bridge.F1Square.Square
