/-
F1 square — **the pre-Hilbert layer, brick 74** (`L2Definite.lean`): **THE L² INNER PRODUCT IS
DEFINITE AT DYADIC POINTS** —

    `φ(p)² > 0`  ⟹  `∫₀¹ φ² > 0`            (`innerI_self_pos_of_dyadic`, the primary form)
    `∫₀¹ φ² ≈ 0`  ⟹  `φ(j/2^m) ≈ 0`         (`innerI_self_zero_imp_dyadic_zero`)

for every dyadic point of `[0,1)`. The second is **not** a mere restatement of the first: passing
between them classically would be a contraposition, which is unavailable here. It is derived
constructively instead, through `¬Pos x → Rle x zero` (valid because `¬Pos` already says every
approximant sits below `1/(n+1)`). Both are proven separately below.
This is what the locality chain of bricks 68–73 was built for, and it is the step that upgrades
"moment-null" to "the zero function" on the polynomial class (`polyPN_dyadic_zero`).

**The constructive point.** A pointwise-definiteness argument classically picks a neighbourhood of
a point where `|φ|` is large. Constructively one may not *locate* a real: given `x₀ : Real` there
is no deciding whether `x₀ ≤ 1/2`, so the enclosing dyadic piece cannot be chosen. Restricting the
statement to **dyadic** points dissolves this entirely — `p = j/2^m` already *is* a dyadic interval
endpoint, so the piece is `[p, p + 1/2^M]` with index `j·2^{M−m}`, computed in `ℕ` with no real
comparison anywhere. No order on reals is decided at any step.

The rest is arithmetic on the square `g = φ·φ`, which the test algebra already certifies with
modulus `l2L φ φ`:

- `Pos (g p)` gives a rational `a > 0` below it (`Pos_imp_ofQ_le`);
- on the piece, `g ≥ g(p) − Lg/2^M` by the Lipschitz certificate, so choosing the depth `M` with
  `Lg/2^M ≤ a/2` — possible since `2^M` outruns any rational, via `Nat.lt_two_pow_self` — leaves
  `g ≥ a/2` there;
- brick 73's `riemannIntegral_pos_of_piece` converts that into `Pos (∫₀¹ g)`.

HONEST SCOPE. Definiteness **at dyadic points**, for the bounded-Lipschitz class on `[0,1]`.
Extending to every real point is a density argument (the Lipschitz modulus makes it routine) and
is **not** performed here; nor is the moment-problem statement — this says nothing about whether a
nonzero test can have all *moments* vanishing, which is the determinacy question and still needs
Bernstein. Nothing here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.IntervalMinorant
import Multiplicity.F1Square.Square.PolyDeterminacy

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The squared test, as an integrand: non-negative, and certified by the product modulus. -/
theorem sq_nonneg_pt (φ : L2Test) (x : Real) : Rnonneg (Rmul (φ.f x) (φ.f x)) :=
  Rnonneg_Rmul_self (φ.f x)

/-- **A depth at which the Lipschitz drop is below a target**: `2^M` outruns any rational. -/
theorem exists_depth (Lg a : Q) (hLd : 0 < Lg.den) (had : 0 < a.den) (han : 0 < a.num) :
    ∃ M : Nat, Qle (mul Lg (⟨1, 2 ^ M⟩ : Q)) a := by
  -- `M := (Lg.num.toNat + 1) * (a.den + 1) * (Lg.den + 1)` is generous; `n < 2^n` finishes.
  refine ⟨Lg.num.toNat * a.den + 1, ?_⟩
  show Lg.num * 1 * ((a.den : Nat) : Int)
      ≤ a.num * (((Lg.den * 2 ^ (Lg.num.toNat * a.den + 1) : Nat)) : Int)
  have hbig : (Lg.num.toNat * a.den + 1 : Nat) < 2 ^ (Lg.num.toNat * a.den + 1) :=
    Nat.lt_two_pow_self
  have hLnum : Lg.num ≤ ((Lg.num.toNat : Nat) : Int) := Int.self_le_toNat _
  have ha1 : (1 : Int) ≤ a.num := han
  have hd1 : (1 : Int) ≤ ((Lg.den : Nat) : Int) := by omega
  have hpow : ((Lg.num.toNat * a.den + 1 : Nat) : Int)
      ≤ ((2 ^ (Lg.num.toNat * a.den + 1) : Nat) : Int) := by exact_mod_cast Nat.le_of_lt hbig
  have hstep : Lg.num * ((a.den : Nat) : Int)
      ≤ ((Lg.num.toNat * a.den : Nat) : Int) := by
    push_cast
    have := Int.mul_le_mul_of_nonneg_right hLnum (Int.ofNat_nonneg a.den)
    push_cast at this
    exact this
  have hchain : ((Lg.num.toNat * a.den : Nat) : Int)
      ≤ a.num * ((Lg.den : Nat) : Int) * ((2 ^ (Lg.num.toNat * a.den + 1) : Nat) : Int) := by
    have h1 : ((Lg.num.toNat * a.den : Nat) : Int)
        ≤ ((2 ^ (Lg.num.toNat * a.den + 1) : Nat) : Int) := by
      refine Int.le_trans ?_ hpow
      push_cast; omega
    have h2 : (1 : Int) ≤ a.num * ((Lg.den : Nat) : Int) := by
      have := Int.mul_le_mul_of_nonneg_right ha1 (by omega : (0 : Int) ≤ ((Lg.den : Nat) : Int))
      omega
    have hnn : (0 : Int) ≤ ((2 ^ (Lg.num.toNat * a.den + 1) : Nat) : Int) := Int.ofNat_nonneg _
    have := Int.mul_le_mul_of_nonneg_right h2 hnn
    omega
  have e : Lg.num * 1 * ((a.den : Nat) : Int) = Lg.num * ((a.den : Nat) : Int) := by ring_uor
  have e2 : a.num * (((Lg.den * 2 ^ (Lg.num.toNat * a.den + 1) : Nat)) : Int)
      = a.num * ((Lg.den : Nat) : Int) * ((2 ^ (Lg.num.toNat * a.den + 1) : Nat) : Int) := by
    push_cast; ring_uor
  rw [e, e2]
  omega

-- ===========================================================================
-- The piece around a dyadic point.
-- ===========================================================================

/-- On the unit parameter range the affine image stays within the width of the left endpoint. -/
theorem affineMap_dist_le (A W : Q) (hA : 0 < A.den) (hW : 0 < W.den) (hWn : 0 ≤ W.num)
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Rle (Rabs (Rsub (affineMap A W hA hW x) (ofQ A hA))) (ofQ W hW) := by
  have hz1 : Rle zero one := Rle_trans h0 h1
  have hxabs : Rle (Rabs x) one :=
    Rabs_le_of_both h1 (Rle_trans (Rle_Rneg h0) (Rle_trans (Rle_of_Req Rneg_zero) hz1))
  have hshift : Req (Rsub (affineMap A W hA hW x) (ofQ A hA)) (Rmul (ofQ W hW) x) := by
    show Req (Radd (Radd (ofQ A hA) (Rmul (ofQ W hW) x)) (Rneg (ofQ A hA))) _
    refine Req_trans (Radd_comm _ _) ?_
    refine Req_trans (Req_symm (Radd_assoc _ _ _)) ?_
    exact Req_trans (Radd_congr (Req_trans (Radd_comm _ _) (Radd_neg (ofQ A hA)))
      (Req_refl _)) (Req_trans (Radd_comm zero _) (Radd_zero _))
  refine Rle_trans (Rle_of_Req (Rabs_congr hshift)) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul_ofQ_nonneg hW hWn x)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hW hWn) hxabs) ?_
  exact Rle_of_Req (Rmul_one _)

/-- `|a − c| ≤ |a − b| + |b − c|` (local copy). -/
private theorem abs_sub_tri3 (a b c : Real) :
    Rle (Rabs (Rsub a c)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b c))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Radd_Rsub_Rsub b c a)))) ?_
  refine Rle_trans (Rabs_Radd (Rsub b c) (Rsub a b)) ?_
  exact Rle_of_Req (Radd_comm (Rabs (Rsub b c)) (Rabs (Rsub a b)))

/-- `c − (a − y) ≈ RsumL [c, −a, y]` — flattening, so the swap below is a permutation.
    (The pointwise route is NOT available: the two sides put `c` and `y` at different
    reindexing depths, so `Req_of_seq_Qeq` would be comparing different approximants.) -/
private theorem sub_sub_flat (a y c : Real) :
    Req (Rsub c (Rsub a y)) (RsumL [c, Rneg a, y]) := by
  show Req (Radd c (Rneg (Radd a (Rneg y)))) (Radd c (Radd (Rneg a) (Radd y zero)))
  refine Radd_congr (Req_refl c) ?_
  refine Req_trans (Rneg_Radd a (Rneg y)) ?_
  exact Radd_congr (Req_refl _) (Req_trans (Rneg_neg y) (Req_symm (Radd_zero y)))

/-- Rearrangement: `a − y ≤ c` gives `a − c ≤ y`, via the additive normalizer. -/
private theorem Rle_sub_swap {a y c : Real} (h : Rle (Rsub a y) c) : Rle (Rsub a c) y := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ (Rnonneg_Rsub_of_Rle h))
  refine Req_trans (sub_sub_flat a y c) ?_
  refine Req_trans ?_ (Req_symm (sub_sub_flat a c y))
  -- `[c, −a, y] → [y, −a, c]` by three ADJACENT swaps. (`decide` on `List.Perm` is banned:
  -- its `Decidable` instance pulls `Classical.choice`, which the honesty gate rejects.)
  refine Req_trans (RsumL_swap_head c (Rneg a) [y]) ?_
  refine Req_trans (Radd_congr (Req_refl (Rneg a)) (RsumL_swap_head c y [])) ?_
  exact RsumL_swap_head (Rneg a) y [c]

-- ===========================================================================
-- The pointwise bound on the piece.
-- ===========================================================================

set_option maxHeartbeats 1000000 in
/-- **THE PIECE CARRIES A CONSTANT**: if `a ≤ φ(p)²` and the Lipschitz drop across the piece is
    at most `a/2`, then `φ² ≥ a/2` everywhere on the piece. -/
theorem sq_ge_on_piece (φ : L2Test) (A W : Q) (hAd : 0 < A.den) (hWd : 0 < W.den)
    (hWn : 0 ≤ W.num) (p : Real) (hAp : Req (ofQ A hAd) p)
    (a : Q) (had : 0 < a.den)
    (hale : Rle (ofQ a had) (Rmul (φ.f p) (φ.f p)))
    (hLW : Qle (mul (l2L φ φ) W) (mul a (⟨1, 2⟩ : Q)))
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Rle (ofQ (mul a (⟨1, 2⟩ : Q)) (Qmul_den_pos had (by decide)))
      (Rmul (φ.f (affineMap A W hAd hWd x)) (φ.f (affineMap A W hAd hWd x))) := by
  have hhd : 0 < (mul a (⟨1, 2⟩ : Q)).den := Qmul_den_pos had (by decide)
  have hdrop : Rle (Rabs (Rsub (Rmul (φ.f p) (φ.f p))
        (Rmul (φ.f (affineMap A W hAd hWd x)) (φ.f (affineMap A W hAd hWd x)))))
      (ofQ (mul (l2L φ φ) W) (Qmul_den_pos (l2L_den φ φ) hWd)) := by
    have hdist : Rle (Rabs (Rsub p (affineMap A W hAd hWd x))) (ofQ W hWd) := by
      refine Rle_trans (Rle_of_Req (Req_symm (Rabs_Rneg _))) ?_
      refine Rle_trans (Rle_of_Req (Rabs_congr (Rneg_Rsub_flip _ _))) ?_
      exact Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_refl _) (Req_symm hAp))))
        (affineMap_dist_le A W hAd hWd hWn x h0 h1)
    refine Rle_trans (l2lip φ φ p (affineMap A W hAd hWd x)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (l2L_den φ φ) (l2L_num φ φ)) hdist) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ (l2L_den φ φ) hWd)
  have hsub : Rle (Rsub (Rmul (φ.f p) (φ.f p))
      (Rmul (φ.f (affineMap A W hAd hWd x)) (φ.f (affineMap A W hAd hWd x))))
      (ofQ (mul a (⟨1, 2⟩ : Q)) hhd) :=
    Rle_trans (Rle_Rabs_self _) (Rle_trans hdrop (Rle_ofQ_ofQ _ hhd hLW))
  have h1' : Rle (Rsub (ofQ a had)
      (Rmul (φ.f (affineMap A W hAd hWd x)) (φ.f (affineMap A W hAd hWd x))))
      (ofQ (mul a (⟨1, 2⟩ : Q)) hhd) :=
    Rle_trans (Rsub_le_mono hale (Rle_refl _)) hsub
  -- `a − g(y) ≤ a/2` rearranges to `a − a/2 ≤ g(y)`
  have hkey : Rle (Rsub (ofQ a had) (ofQ (mul a (⟨1, 2⟩ : Q)) hhd))
      (Rmul (φ.f (affineMap A W hAd hWd x)) (φ.f (affineMap A W hAd hWd x))) :=
    Rle_sub_swap h1'
  refine Rle_trans (Rle_of_Req ?_) hkey
  refine Req_symm (sub_ofQ_val had hhd hhd ?_)
  show Qeq (add a (neg (mul a (⟨1, 2⟩ : Q)))) (mul a (⟨1, 2⟩ : Q))
  simp only [Qeq, add, neg, mul]; push_cast; ring_uor

-- ===========================================================================
-- The definiteness theorem.
-- ===========================================================================

set_option maxHeartbeats 4000000 in
/-- **THE L² INNER PRODUCT IS DEFINITE AT DYADIC POINTS**: `φ(j/2^m)² > 0 ⟹ ∫₀¹ φ² > 0`.

    No order on reals is decided anywhere: the point IS a dyadic endpoint, so the enclosing piece
    is the depth-`(M+m)` interval at index `j·2^M`, computed entirely in `ℕ`. -/
theorem innerI_self_pos_of_dyadic (φ : L2Test) (m j : Nat) (hj : j < 2 ^ m)
    (hpos : Pos (Rmul (φ.f (ofQ (⟨(j : Int), 2 ^ m⟩ : Q) (two_pow_pos m)))
                      (φ.f (ofQ (⟨(j : Int), 2 ^ m⟩ : Q) (two_pow_pos m))))) :
    Pos (innerI φ φ) := by
  obtain ⟨a, had, han, hale⟩ := Pos_imp_ofQ_le hpos
  have hhd : 0 < (mul a (⟨1, 2⟩ : Q)).den := Qmul_den_pos had (by decide)
  have hhn : 0 < (mul a (⟨1, 2⟩ : Q)).num := by show (0 : Int) < a.num * 1; omega
  obtain ⟨M0, hM0⟩ := exists_depth (l2L φ φ) (mul a (⟨1, 2⟩ : Q)) (l2L_den φ φ) hhd hhn
  refine riemannIntegral_pos_of_piece (l2L_den φ φ) (l2L_num φ φ) (l2lip φ φ) (l2fc φ φ)
    (fun x => sq_nonneg_pt φ x) (M0 + m) (j * 2 ^ M0) ?_ (ofQ (mul a (⟨1, 2⟩ : Q)) hhd)
    (Pos_of_Rle_ofQ hhn hhd (Rle_refl _)) (fun x h0 h1 => ?_)
  · -- the index fits: `j·2^{M0} < 2^m·2^{M0} = 2^{M0+m}`
    have hlt : j * 2 ^ M0 < 2 ^ m * 2 ^ M0 :=
      Nat.mul_lt_mul_of_lt_of_le hj (Nat.le_refl _) (Nat.pos_pow_of_pos _ (by decide))
    have he : 2 ^ m * 2 ^ M0 = 2 ^ (M0 + m) := by rw [Nat.pow_add, Nat.mul_comm]
    rw [← he]; exact hlt
  · -- the piece's left endpoint IS the dyadic point, and the drop across it is at most `a/2`
    refine sq_ge_on_piece φ _ _ (dyadA_den (by decide) (by decide) (M0 + m) (j * 2 ^ M0))
      (dyadW_den (by decide) (M0 + m)) (dyadW_num (by decide) (M0 + m)) _ ?_ a had hale ?_ x h0 h1
    · refine ofQ_congr _ (two_pow_pos m) ?_
      show Qeq (add (⟨0, 1⟩ : Q)
          (mul (⟨((j * 2 ^ M0 : Nat) : Int), 2 ^ (M0 + m)⟩ : Q) (⟨1, 1⟩ : Q)))
        (⟨(j : Int), 2 ^ m⟩ : Q)
      simp only [Qeq, add, mul, Nat.pow_add]
      push_cast
      ring_uor
    · -- `Lg·(1/2^{M0+m}) ≤ Lg·(1/2^{M0}) ≤ a/2`
      refine Qle_trans (Qmul_den_pos (l2L_den φ φ) (two_pow_pos M0)) ?_ hM0
      refine Qmul_le_mul_left (l2L_num φ φ) ?_
      show (1 : Int) * ((2 ^ M0 : Nat) : Int)
          ≤ (1 * 1 : Int) * (((2 ^ (M0 + m) * 1 : Nat)) : Int)
      have hle : (2 : Nat) ^ M0 ≤ 2 ^ (M0 + m) := Nat.pow_le_pow_right (by decide) (by omega)
      have hI := Int.ofNat_le.mpr hle
      push_cast at hI ⊢
      omega

/-- Not strictly positive gives `≤ 0` — constructively valid and choice-free: `¬Pos x` says every
    approximant is below `1/(n+1)`, which is already the `Rle x 0` inequality. -/
private theorem Rle_zero_of_not_Pos {x : Real} (h : ¬ Pos x) : Rle x zero := by
  intro n
  have hn : ¬ Qlt (Qbound n) (x.seq n) := fun hlt => h ⟨n, hlt⟩
  have hd : 0 < (x.seq n).den := x.den_pos n
  show Qle (x.seq n) (add (zero.seq n) (⟨2, n + 1⟩ : Q))
  simp only [Qlt, Qbound] at hn
  simp only [Qle, add, zero_seq]
  push_cast at hn ⊢
  have hd' : (0 : Int) < ((x.seq n).den : Int) := by exact_mod_cast hd
  have e : (x.seq n).num * (1 * ((n : Int) + 1)) = (x.seq n).num * ((n : Int) + 1) := by ring_uor
  rw [e]
  omega

/-- `0` is not strictly positive (local copy). -/
private theorem zero_not_Pos' : ¬ Pos zero := by
  intro ⟨n, hn⟩
  simp only [Qlt, Qbound, zero_seq] at hn
  omega

/-- **DEFINITENESS, CONTRAPOSITIVE**: a null L² energy kills the test at every dyadic point. -/
theorem innerI_self_zero_imp_dyadic_zero (φ : L2Test) (h : Req (innerI φ φ) zero)
    (m j : Nat) (hj : j < 2 ^ m) :
    Req (φ.f (ofQ (⟨(j : Int), 2 ^ m⟩ : Q) (two_pow_pos m))) zero := by
  refine Req_zero_of_sq_zero _ (Rle_antisymm ?_ (Rle_zero_of_Rnonneg (sq_nonneg_pt φ _)))
  refine Rle_zero_of_not_Pos (fun hp => zero_not_Pos' ?_)
  exact Pos_congr h (innerI_self_pos_of_dyadic φ m j hj hp)

/-- **THE POLYNOMIAL CLASS, UPGRADED**: a `d`-coefficient polynomial test whose first `d` moments
    vanish is zero at every dyadic point — brick 64's determinacy, now at the level of the
    FUNCTION and not only its moments. -/
theorem polyPN_dyadic_zero (a b : Nat → Nat) (d : Nat)
    (h : ∀ i : Nat, i < d → Req (mellinMoment (polyPN a b d) i) zero)
    (m j : Nat) (hj : j < 2 ^ m) :
    Req ((polyPN a b d).f (ofQ (⟨(j : Int), 2 ^ m⟩ : Q) (two_pow_pos m))) zero :=
  innerI_self_zero_imp_dyadic_zero (polyPN a b d) (innerI_polyPN_self_zero a b d h) m j hj

-- ===========================================================================
-- Toward density: the piece lemma with the point only NEAR the endpoint.
-- ===========================================================================

set_option maxHeartbeats 1000000 in
/-- **THE PIECE CARRIES A CONSTANT, FOR A NEARBY POINT**: `sq_ge_on_piece` with the hypothesis
    `ofQ A ≈ p` weakened to `|ofQ A − p| ≤ W`. The drop across the piece is then at most `2·Lg·W`
    rather than `Lg·W`, since the point may sit a full width away from the endpoint.

    This is the reusable half of the density extension: for a general real `x` one cannot ask for
    a dyadic endpoint EQUAL to `x`, only for one within a chosen width. -/
theorem sq_ge_on_piece_near (φ : L2Test) (A W : Q) (hAd : 0 < A.den) (hWd : 0 < W.den)
    (hWn : 0 ≤ W.num) (p : Real)
    (hnear : Rle (Rabs (Rsub (ofQ A hAd) p)) (ofQ W hWd))
    (a : Q) (had : 0 < a.den)
    (hale : Rle (ofQ a had) (Rmul (φ.f p) (φ.f p)))
    (hLW : Qle (mul (l2L φ φ) (mul (⟨2, 1⟩ : Q) W)) (mul a (⟨1, 2⟩ : Q)))
    (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    Rle (ofQ (mul a (⟨1, 2⟩ : Q)) (Qmul_den_pos had (by decide)))
      (Rmul (φ.f (affineMap A W hAd hWd x)) (φ.f (affineMap A W hAd hWd x))) := by
  have hhd : 0 < (mul a (⟨1, 2⟩ : Q)).den := Qmul_den_pos had (by decide)
  have h2Wd : 0 < (mul (⟨2, 1⟩ : Q) W).den := Qmul_den_pos (by decide) hWd
  -- distance from `p` to the running point: through the endpoint, so two widths
  have hdist : Rle (Rabs (Rsub p (affineMap A W hAd hWd x))) (ofQ (mul (⟨2, 1⟩ : Q) W) h2Wd) := by
    have hb1 : Rle (Rabs (Rsub p (ofQ A hAd))) (ofQ W hWd) :=
      Rle_trans (Rle_of_Req (Req_symm (Rabs_Rneg _)))
        (Rle_trans (Rle_of_Req (Rabs_congr (Rneg_Rsub_flip _ _))) hnear)
    have hb2 : Rle (Rabs (Rsub (ofQ A hAd) (affineMap A W hAd hWd x))) (ofQ W hWd) :=
      Rle_trans (Rle_of_Req (Req_symm (Rabs_Rneg _)))
        (Rle_trans (Rle_of_Req (Rabs_congr (Rneg_Rsub_flip _ _)))
          (affineMap_dist_le A W hAd hWd hWn x h0 h1))
    refine Rle_trans (abs_sub_tri3 p (ofQ A hAd) (affineMap A W hAd hWd x)) ?_
    refine Rle_trans (Radd_le_add hb1 hb2) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hWd hWd)) ?_
    exact Rle_ofQ_ofQ _ h2Wd (Qeq_le (by simp only [Qeq, add, mul]; push_cast; ring_uor))
  have hdrop : Rle (Rabs (Rsub (Rmul (φ.f p) (φ.f p))
        (Rmul (φ.f (affineMap A W hAd hWd x)) (φ.f (affineMap A W hAd hWd x)))))
      (ofQ (mul (l2L φ φ) (mul (⟨2, 1⟩ : Q) W)) (Qmul_den_pos (l2L_den φ φ) h2Wd)) := by
    refine Rle_trans (l2lip φ φ p (affineMap A W hAd hWd x)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (l2L_den φ φ) (l2L_num φ φ)) hdist) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ (l2L_den φ φ) h2Wd)
  have hsub : Rle (Rsub (Rmul (φ.f p) (φ.f p))
      (Rmul (φ.f (affineMap A W hAd hWd x)) (φ.f (affineMap A W hAd hWd x))))
      (ofQ (mul a (⟨1, 2⟩ : Q)) hhd) :=
    Rle_trans (Rle_Rabs_self _) (Rle_trans hdrop (Rle_ofQ_ofQ _ hhd hLW))
  have h1' : Rle (Rsub (ofQ a had)
      (Rmul (φ.f (affineMap A W hAd hWd x)) (φ.f (affineMap A W hAd hWd x))))
      (ofQ (mul a (⟨1, 2⟩ : Q)) hhd) :=
    Rle_trans (Rsub_le_mono hale (Rle_refl _)) hsub
  refine Rle_trans (Rle_of_Req ?_) (Rle_sub_swap h1')
  refine Req_symm (sub_ofQ_val had hhd hhd ?_)
  show Qeq (add a (neg (mul a (⟨1, 2⟩ : Q)))) (mul a (⟨1, 2⟩ : Q))
  simp only [Qeq, add, neg, mul]; push_cast; ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
