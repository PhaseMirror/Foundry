/-
F1 square — **the ℚ-coefficient polynomial test** (`QPolyMember.lean`): a co-support member built
directly from a **rational coefficient function** `c : Nat → Q`, with NO denominator clearing.

The `List`-indexed rational sum `qsumL` (brick N₁) is the row-operation substrate of the Hilbert
system; here it is welded to the *analytic* side. A rational coefficient vector `c` is turned into a
genuine test

    `qPolyTest c d = Σ_{i<d} c_i · xⁱ`   (`L2sumN` of `qMonoTest`),

whose Mellin moments and window value are the rational contractions of `c` against the Hilbert
matrix, read off `qsumL` with no clearing of denominators:

    `mellinMoment (qPolyTest c d) n = Σ_{i∈range d} c_i / (i+n+1)`   (`mellinMoment_qPolyTest`)
    `qPolyTest c d` is `[0,1]`-supported  ⟺  `Σ_{i∈range d} c_i = 0`  (`qPolyTest_supp`).

So a rational nullspace vector of the Hilbert system becomes a co-support member
(`qPolyTest_hatVanishes`) directly, keeping the whole construction inside exact `ℚ` arithmetic — the
`ℤ`-coefficient generator `polyPN` (brick 66) is the special case `c_i ∈ ℤ`.

The bridge lemma `RsumN_ofQ_qsumL_range` converts the real finite sum `Σ_{i<d} ofQ (f i)` into the
embedded rational `ofQ (qsumL f (range d))`, so every `RsumN`-of-`ofQ` reduces to a single `qsumL`.

HONEST SCOPE. A constructor over `ℚ`: it packages a *given* rational solution of the Hilbert system
as a member, no clearing needed; it is NOT an existence theorem (solutions at general depth are the
hypergeometric identity the layer cannot reach), and NOT positivity. Step 4 is RH; crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.QSumList
import Foundations.F1.Square.ConstScale
import Foundations.F1.Square.HilbertGram
import Foundations.F1.Square.MomentReconSum

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Local zero helpers.
-- ===========================================================================

/-- `zero` read as the rational constant `0/1`. -/
private theorem zeroQ : Req zero (ofQ (⟨0, 1⟩ : Q) (by decide)) :=
  Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- An embedded rational that is `ℚ`-equal to `0` is the real `zero`. -/
private theorem ofQ_eq_zero {q : Q} (hq : 0 < q.den) (h : Qeq q (⟨0, 1⟩ : Q)) :
    Req (ofQ q hq) zero := by
  refine Req_trans ?_ (Req_symm zeroQ)
  exact Req_of_seq_Qeq (fun _ => h)

-- ===========================================================================
-- 1. The `RsumN`(real) ↔ `qsumL`(rational) bridge over `List.range`.
-- ===========================================================================

/-- The list sum is additive over `++`: `Σ_{l₁++l₂} f ≈ Σ_{l₁} f + Σ_{l₂} f`. -/
theorem qsumL_append (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (l₁ l₂ : List Nat) :
    Qeq (qsumL f (l₁ ++ l₂)) (add (qsumL f l₁) (qsumL f l₂)) := by
  induction l₁ with
  | nil =>
    show Qeq (qsumL f l₂) (add (⟨0, 1⟩ : Q) (qsumL f l₂))
    simp only [Qeq, add]; push_cast; ring_uor
  | cons i rest ih =>
    show Qeq (add (f i) (qsumL f (rest ++ l₂)))
      (add (add (f i) (qsumL f rest)) (qsumL f l₂))
    exact Qeq_trans (b := add (f i) (add (qsumL f rest) (qsumL f l₂)))
      (add_den_pos (hf i) (add_den_pos (qsumL_den f hf rest) (qsumL_den f hf l₂)))
      (Qadd_congr (Qeq_refl _) ih)
      (by simp only [Qeq, add]; push_cast; ring_uor)

/-- **THE BRIDGE**: the real finite sum of `ofQ`-embedded terms is the embedded rational list sum,
    `Σ_{i<d} ofQ (f i) ≈ ofQ (Σ_{i∈range d} f i)` — every `RsumN`-of-`ofQ` collapses to one `qsumL`. -/
theorem RsumN_ofQ_qsumL_range (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (d : Nat) :
    Req (RsumN (fun i => ofQ (f i) (hf i)) d)
      (ofQ (qsumL f (List.range d)) (qsumL_den f hf (List.range d))) := by
  induction d with
  | zero => exact Req_of_seq_Qeq (fun _ => Qeq_refl _)
  | succ d ih =>
    simp only [List.range_succ]
    refine Req_trans (Radd_congr ih (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ (qsumL_den f hf (List.range d)) (hf d)) ?_
    have happ : Qeq (qsumL f (List.range d ++ [d]))
        (add (qsumL f (List.range d)) (qsumL f [d])) :=
      qsumL_append f hf (List.range d) [d]
    have hd0 : Qeq (qsumL f [d]) (f d) := by
      show Qeq (add (f d) (⟨0, 1⟩ : Q)) (f d)
      simp only [Qeq, add]; push_cast; ring_uor
    have hcomb : Qeq (qsumL f (List.range d ++ [d]))
        (add (qsumL f (List.range d)) (f d)) :=
      Qeq_trans (b := add (qsumL f (List.range d)) (qsumL f [d]))
        (add_den_pos (qsumL_den f hf (List.range d)) (qsumL_den f hf [d]))
        happ (Qadd_congr (Qeq_refl _) hd0)
    exact Req_of_seq_Qeq (fun _ => Qeq_symm hcomb)

-- ===========================================================================
-- 2. The rational-scaled monomial test.
-- ===========================================================================

/-- **The rational-scaled monomial** `c · xⁱ` — the constant test carrying the rational coefficient
    `c` (bound `|c| ≤ |c|`), multiplied into the monomial `xⁱ`. -/
def qMonoTest (q : Q) (hq : 0 < q.den) (i : Nat) : L2Test :=
  L2Test.mul (constTest (ofQ q hq) (Qabs q) (Qabs_den_pos hq) (Qabs_num_nonneg q)
    (Rle_of_Req (Rabs_ofQ hq))) (powTest i)

/-- **The Hilbert contraction of the rational monomial**: `⟨xⁿ, c·xⁱ⟩ = c/(n+i+1)`. -/
theorem innerI_powTest_qMono (q : Q) (hq : 0 < q.den) (i n : Nat) :
    Req (innerI (powTest n) (qMonoTest q hq i))
      (ofQ (mul q (⟨1, n + i + 1⟩ : Q)) (Qmul_den_pos hq (Nat.succ_pos (n + i)))) := by
  refine Req_trans (innerI_constMul (powTest n) (powTest i) (ofQ q hq)
    (Qabs_den_pos hq) (Qabs_num_nonneg q) (Rle_of_Req (Rabs_ofQ hq))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) (innerI_powTest_hilbert n i)) ?_
  exact Rmul_ofQ_ofQ hq (Nat.succ_pos (n + i))

-- ===========================================================================
-- 3. The member and its moment.
-- ===========================================================================

/-- **The ℚ-coefficient polynomial test** `Σ_{i<d} c_i · xⁱ`. -/
def qPolyTest (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (d : Nat) : L2Test :=
  L2sumN (fun i => qMonoTest (c i) (hc i) i) d

/-- **THE MOMENT IS THE RATIONAL HILBERT CONTRACTION**: `⟨qPolyTest c d, xⁿ⟩ = Σ_{i∈range d}
    c_i/(i+n+1)`, an embedded `qsumL` over `ℚ` — no denominator clearing. -/
theorem mellinMoment_qPolyTest (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (d n : Nat) :
    Req (mellinMoment (qPolyTest c hc d) n)
      (ofQ (qsumL (fun i => mul (c i) (⟨1, i + n + 1⟩ : Q)) (List.range d))
        (qsumL_den _ (fun i => Qmul_den_pos (hc i) (Nat.succ_pos (i + n))) (List.range d))) := by
  have hterm : ∀ i, Req (innerI (powTest n) (qMonoTest (c i) (hc i) i))
      (ofQ (mul (c i) (⟨1, i + n + 1⟩ : Q))
        (Qmul_den_pos (hc i) (Nat.succ_pos (i + n)))) := fun i =>
    Req_trans (innerI_powTest_qMono (c i) (hc i) i n)
      (Req_of_seq_Qeq (fun _ => by
        show Qeq (mul (c i) (⟨1, n + i + 1⟩ : Q)) (mul (c i) (⟨1, i + n + 1⟩ : Q))
        simp only [Qeq, mul]; push_cast; ring_uor))
  refine Req_trans (innerI_symm (qPolyTest c hc d) (powTest n)) ?_
  refine Req_trans (innerI_L2sumN (powTest n) (fun i => qMonoTest (c i) (hc i) i) d) ?_
  refine Req_trans (RsumN_congr d (fun i _ => hterm i)) ?_
  exact RsumN_ofQ_qsumL_range (fun i => mul (c i) (⟨1, i + n + 1⟩ : Q))
    (fun i => Qmul_den_pos (hc i) (Nat.succ_pos (i + n))) d

-- ===========================================================================
-- 4. Support.
-- ===========================================================================

/-- **THE SUPPORT LAW**: `qPolyTest c d` is `[0,1]`-supported exactly when its rational coefficients
    sum to zero — past `1`, every monomial saturates to `1`, so the window value is `Σ_{i} c_i`. -/
theorem qPolyTest_supp (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (d : Nat)
    (hsum : Qeq (qsumL c (List.range d)) (⟨0, 1⟩ : Q)) :
    UnitSupported (qPolyTest c hc d) := by
  intro m x h0 _
  have hgi : ∀ i, Req ((qMonoTest (c i) (hc i) i).f
        (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
      (ofQ (c i) (hc i)) := by
    intro i
    refine Req_trans (Rmul_congr (Req_refl (ofQ (c i) (hc i)))
      (powTest_window_one m h0 i)) ?_
    exact Rmul_one (ofQ (c i) (hc i))
  refine Req_trans (L2sumN_f_eq (fun i => qMonoTest (c i) (hc i) i)
    (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) d) ?_
  refine Req_trans (RsumN_congr d (fun i _ => hgi i)) ?_
  refine Req_trans (RsumN_ofQ_qsumL_range c hc d) ?_
  exact ofQ_eq_zero (qsumL_den c hc (List.range d)) hsum

-- ===========================================================================
-- 5. Sanity self-check: a rational nullspace vector is a co-support member.
-- ===========================================================================

/-- **THE ℚ-MEMBER**: a rational coefficient vector with zero coefficient sum and `K` vanishing
    Hilbert contractions produces a certified depth-`K` co-support member — the whole construction
    inside exact `ℚ` arithmetic, no clearing. -/
theorem qPolyTest_hatVanishes (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (d K : Nat)
    (hsum : Qeq (qsumL c (List.range d)) (⟨0, 1⟩ : Q))
    (hmom : ∀ n : Nat, n < K →
      Qeq (qsumL (fun i => mul (c i) (⟨1, i + n + 1⟩ : Q)) (List.range d)) (⟨0, 1⟩ : Q)) :
    HatVanishes (qPolyTest c hc d) K (C := (⟨0, 1⟩ : Q)) (by decide)
      (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp (qPolyTest c hc d) (qPolyTest_supp c hc d hsum)) :=
  hatVanishes_of_moments (qPolyTest c hc d) K (qPolyTest_supp c hc d hsum)
    (fun n hn => Req_trans (mellinMoment_qPolyTest c hc d n)
      (ofQ_eq_zero
        (qsumL_den (fun i => mul (c i) (⟨1, i + n + 1⟩ : Q))
          (fun i => Qmul_den_pos (hc i) (Nat.succ_pos (i + n))) (List.range d))
        (hmom n hn)))

end Multiplicity.UOR.Bridge.F1Square.Square
