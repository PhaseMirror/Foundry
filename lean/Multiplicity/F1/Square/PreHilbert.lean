/-
F1 square — **the pre-Hilbert layer, brick 1** (`PreHilbert.lean`): the truncated inner product
`⟨f,g⟩_N = Σ_{i<N} fᵢ·gᵢ` on test families over the constructive reals — the four inner-product
laws (symmetry, additivity, scaling, positivity), norm-growth monotonicity in the truncation, and
the **sqrt-free Cauchy–Schwarz inequality** via the LAGRANGE IDENTITY:

    `⟨f,f⟩_N·⟨g,g⟩_N − ⟨f,g⟩_N² ≈ Σ_{j<N} Σ_{i<j} (fᵢgⱼ − fⱼgᵢ)²`    (`lagrange_identity`)

The Cauchy–Schwarz defect is an EXPLICIT sum of squares, so `⟨f,g⟩² ≤ ⟨f,f⟩·⟨g,g⟩`
(`cauchy_schwarz`) follows with no discriminant argument, no division, no square root (the
substrate has none): the certificate IS the SOS. This is the intrinsic-certificate shape the
discharge form (`RealizesDiag`/Gate A) asks about, realized unconditionally at the pre-Hilbert
level — where the SOS exists because the form `⟨f,f⟩⟨g,g⟩ − ⟨f,g⟩²` is a Gram determinant, the
2×2 minor sum of the pair `(f,g)`.

WHY (the Sonine route, step 3). The crux-closing route needs "a Hilbert/inner-product layer that
does not exist (no L², no completeness, no self-adjoint operators)". This brick starts that layer
on the finite-truncation substrate the discrete Sonine skeleton (`SonineProjection`) already lives
on: `innerN` is the inner product whose direct limit (`∀ N`, exactly as in `WeilPSD`) is the
pre-L² pairing, and Cauchy–Schwarz is the first structural theorem every Hilbert-space argument
consumes.

HONEST SCOPE. Finite truncations of the sequence inner product; no completion, no L², no operator
theory, no spectral claim. Nothing here touches the crux fields; they stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.WeilPSD
import Multiplicity.F1.Analysis.CosSinBound
import Multiplicity.F1.Analysis.RMulNF

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Finite-sum plumbing the layer needs: negation and subtraction pass through
-- `RsumN`, and prefix monotonicity for nonnegative terms.
-- ===========================================================================

/-- Negation passes through a finite sum: `Σ (−F) ≈ −(Σ F)`. -/
theorem RsumN_neg (F : Nat → Real) (N : Nat) :
    Req (RsumN (fun i => Rneg (F i)) N) (Rneg (RsumN F N)) := by
  induction N with
  | zero =>
    have h1 : Req (Radd zero (Rneg zero)) zero := Radd_neg zero
    have h2 : Req (Radd zero (Rneg zero)) (Rneg zero) :=
      Req_trans (Radd_comm zero (Rneg zero)) (Radd_zero (Rneg zero))
    exact Req_trans (Req_symm h1) h2
  | succ n ih =>
    exact Req_trans (Radd_congr ih (Req_refl _)) (Req_symm (Rneg_Radd (RsumN F n) (F n)))

/-- Finite sums split over `Rsub`: `Σ (F − G) ≈ (Σ F) − (Σ G)`. -/
theorem RsumN_sub (F G : Nat → Real) (N : Nat) :
    Req (RsumN (fun i => Rsub (F i) (G i)) N) (Rsub (RsumN F N) (RsumN G N)) :=
  Req_trans (RsumN_add F (fun i => Rneg (G i)) N)
    (Radd_congr (Req_refl _) (RsumN_neg G N))

/-- A sum of nonnegative terms grows with the truncation: `Σ_{i<n} F ≤ Σ_{i<N} F` for `n ≤ N`. -/
theorem RsumN_le_prefix {F : Nat → Real} (hF : ∀ i, Rnonneg (F i)) {n N : Nat} (h : n ≤ N) :
    Rle (RsumN F n) (RsumN F N) := by
  induction h with
  | refl => exact Rle_refl _
  | step _ ih => exact Rle_trans ih (Rle_self_Radd_right (hF _))

/-- Right-constant pull-out `Σ (F i · M) ≈ (Σ F) · M`, derived from the left pull by
    commutativity. -/
theorem RsumN_mul_const (F : Nat → Real) (M : Real) (N : Nat) :
    Req (RsumN (fun i => Rmul (F i) M) N) (Rmul (RsumN F N) M) :=
  Req_trans (RsumN_congr N (fun i _ => Rmul_comm (F i) M))
    (Req_trans (Req_symm (Rmul_RsumN_left M F N)) (Rmul_comm M (RsumN F N)))

-- ===========================================================================
-- The truncated inner product and the inner-product laws.
-- ===========================================================================

/-- The **truncated inner product** `⟨f,g⟩_N = Σ_{i<N} fᵢ·gᵢ` of two test families. Its direct
    limit over `N` (the `∀ N` reading, as in `WeilPSD`) is the pre-L² pairing of the Sonine
    route's step 3. -/
def innerN (f g : Nat → Real) (N : Nat) : Real :=
  RsumN (fun i => Rmul (f i) (g i)) N

/-- The inner product respects `≈` termwise in both slots. -/
theorem innerN_congr {f f' g g' : Nat → Real} (N : Nat)
    (hf : ∀ i, i < N → Req (f i) (f' i)) (hg : ∀ i, i < N → Req (g i) (g' i)) :
    Req (innerN f g N) (innerN f' g' N) :=
  RsumN_congr N (fun i hi => Rmul_congr (hf i hi) (hg i hi))

/-- **Symmetry**: `⟨f,g⟩_N ≈ ⟨g,f⟩_N`. -/
theorem innerN_symm (f g : Nat → Real) (N : Nat) :
    Req (innerN f g N) (innerN g f N) :=
  RsumN_congr N (fun i _ => Rmul_comm (f i) (g i))

/-- **Additivity in the first slot**: `⟨f + f', g⟩_N ≈ ⟨f,g⟩_N + ⟨f',g⟩_N`. -/
theorem innerN_add_left (f f' g : Nat → Real) (N : Nat) :
    Req (innerN (fun i => Radd (f i) (f' i)) g N) (Radd (innerN f g N) (innerN f' g N)) :=
  Req_trans (RsumN_congr N (fun i _ => Rmul_distrib_right (f i) (f' i) (g i)))
    (RsumN_add (fun i => Rmul (f i) (g i)) (fun i => Rmul (f' i) (g i)) N)

/-- **Homogeneity in the first slot**: `⟨t·f, g⟩_N ≈ t·⟨f,g⟩_N`. -/
theorem innerN_smul_left (t : Real) (f g : Nat → Real) (N : Nat) :
    Req (innerN (fun i => Rmul t (f i)) g N) (Rmul t (innerN f g N)) :=
  Req_trans (RsumN_congr N (fun i _ => Rmul_assoc t (f i) (g i)))
    (Req_symm (Rmul_RsumN_left t (fun i => Rmul (f i) (g i)) N))

/-- **Positivity**: `⟨f,f⟩_N ≥ 0` — the squared norm is a sum of squares. -/
theorem innerN_self_nonneg (f : Nat → Real) (N : Nat) : Rnonneg (innerN f f N) :=
  Rnonneg_RsumN N (fun i _ => Rnonneg_Rmul_self (f i))

/-- **Norm growth**: the squared norm is monotone in the truncation, `⟨f,f⟩_n ≤ ⟨f,f⟩_N` for
    `n ≤ N` — the directed structure the completion-free layer works with. -/
theorem innerN_self_mono (f : Nat → Real) {n N : Nat} (h : n ≤ N) :
    Rle (innerN f f n) (innerN f f N) :=
  RsumN_le_prefix (fun i => Rnonneg_Rmul_self (f i)) h

-- ===========================================================================
-- The Lagrange identity: the Cauchy–Schwarz defect as an explicit SOS.
-- ===========================================================================

/-- The **cross difference** `fᵢgⱼ − fⱼgᵢ` — the 2×2 minor of the pair `(f,g)` at `(i,j)`. -/
def crossD (f g : Nat → Real) (i j : Nat) : Real :=
  Rsub (Rmul (f i) (g j)) (Rmul (f j) (g i))

/-- The **Lagrange sum of squares** `Σ_{j<N} Σ_{i<j} (fᵢgⱼ − fⱼgᵢ)²` — the explicit SOS that
    the Cauchy–Schwarz defect equals. -/
def lagSOS (f g : Nat → Real) (N : Nat) : Real :=
  RsumN (fun j => RsumN (fun i => Rmul (crossD f g i j) (crossD f g i j)) j) N

/-- The Lagrange SOS is nonnegative — it is manifestly a sum of squares. -/
theorem lagSOS_nonneg (f g : Nat → Real) (N : Nat) : Rnonneg (lagSOS f g N) :=
  Rnonneg_RsumN N (fun j _ => Rnonneg_RsumN j (fun i _ => Rnonneg_Rmul_self (crossD f g i j)))

/-- `(a−b) − (c−d) ≈ (a+d) − (b+c)` — pointwise (same additive depth on both sides, exact ℚ
    identity at each index; the `Rsub_Radd_Radd` pattern). -/
private theorem Rsub_Rsub_Rsub (a b c d : Real) :
    Req (Rsub (Rsub a b) (Rsub c d)) (Rsub (Radd a d) (Radd b c)) := by
  apply Req_of_seq_Qeq
  intro n
  simp only [Rsub, Radd, Rneg, Qeq, add, neg]; push_cast; ring_uor

/-- **The square of a difference**: `(x−y)² ≈ (x² + y²) − (xy + xy)` — distributivity plus the
    additive rearrangement; no `2` literal is introduced (the doubled term is kept as a sum). -/
theorem Rsub_sq_expand (x y : Real) :
    Req (Rmul (Rsub x y) (Rsub x y))
        (Rsub (Radd (Rmul x x) (Rmul y y)) (Radd (Rmul x y) (Rmul x y))) := by
  refine Req_trans (Rmul_sub_distrib_right x y (Rsub x y)) ?_
  refine Req_trans (Rsub_congr (Rmul_sub_distrib x x y) (Rmul_sub_distrib y x y)) ?_
  refine Req_trans (Rsub_Rsub_Rsub (Rmul x x) (Rmul x y) (Rmul y x) (Rmul y y)) ?_
  exact Rsub_congr (Req_refl _) (Radd_congr (Req_refl _) (Rmul_comm y x))

/-- Binomial product `(a+b)(c+d) ≈ (ac + ad) + (bc + bd)`. -/
private theorem Rmul_add_add (a b c d : Real) :
    Req (Rmul (Radd a b) (Radd c d))
        (Radd (Radd (Rmul a c) (Rmul a d)) (Radd (Rmul b c) (Rmul b d))) :=
  Req_trans (Rmul_distrib_right a b (Radd c d))
    (Radd_congr (Rmul_distrib a c d) (Rmul_distrib b c d))

/-- The cross-square expanded to monomials: `(fᵢgₙ − fₙgᵢ)² ≈ (fᵢ²gₙ² + fₙ²gᵢ²) −
    (fᵢgᵢ·fₙgₙ + fᵢgᵢ·fₙgₙ)` — `Rsub_sq_expand` plus the `RprodL` monomial reassociations. -/
private theorem crossSq_expand (f g : Nat → Real) (i n : Nat) :
    Req (Rmul (crossD f g i n) (crossD f g i n))
        (Rsub (Radd (Rmul (Rmul (f i) (f i)) (Rmul (g n) (g n)))
                    (Rmul (Rmul (f n) (f n)) (Rmul (g i) (g i))))
              (Radd (Rmul (Rmul (f i) (g i)) (Rmul (f n) (g n)))
                    (Rmul (Rmul (f i) (g i)) (Rmul (f n) (g n))))) := by
  refine Req_trans (Rsub_sq_expand (Rmul (f i) (g n)) (Rmul (f n) (g i))) ?_
  exact Rsub_congr
    (Radd_congr (prod_sq_reassoc (f i) (g n)) (prod_sq_reassoc (f n) (g i)))
    (Radd_congr (prod_cross_reassoc (f i) (f n) (g n) (g i))
                (prod_cross_reassoc (f i) (f n) (g n) (g i)))

/-- The row sum of cross-squares at outer index `n`: `Σ_{i<n} (fᵢgₙ − fₙgᵢ)² ≈
    (⟨f,f⟩ₙ·gₙ² + fₙ²·⟨g,g⟩ₙ) − (⟨f,g⟩ₙ·fₙgₙ + ⟨f,g⟩ₙ·fₙgₙ)` — the exact increment the
    Lagrange induction consumes. -/
private theorem cross_row (f g : Nat → Real) (n : Nat) :
    Req (RsumN (fun i => Rmul (crossD f g i n) (crossD f g i n)) n)
        (Rsub (Radd (Rmul (innerN f f n) (Rmul (g n) (g n)))
                    (Rmul (Rmul (f n) (f n)) (innerN g g n)))
              (Radd (Rmul (innerN f g n) (Rmul (f n) (g n)))
                    (Rmul (innerN f g n) (Rmul (f n) (g n))))) := by
  refine Req_trans (RsumN_congr n (fun i _ => crossSq_expand f g i n)) ?_
  refine Req_trans (RsumN_sub
    (fun i => Radd (Rmul (Rmul (f i) (f i)) (Rmul (g n) (g n)))
                   (Rmul (Rmul (f n) (f n)) (Rmul (g i) (g i))))
    (fun i => Radd (Rmul (Rmul (f i) (g i)) (Rmul (f n) (g n)))
                   (Rmul (Rmul (f i) (g i)) (Rmul (f n) (g n)))) n) ?_
  refine Rsub_congr ?_ ?_
  · refine Req_trans (RsumN_add
      (fun i => Rmul (Rmul (f i) (f i)) (Rmul (g n) (g n)))
      (fun i => Rmul (Rmul (f n) (f n)) (Rmul (g i) (g i))) n) ?_
    exact Radd_congr
      (RsumN_mul_const (fun i => Rmul (f i) (f i)) (Rmul (g n) (g n)) n)
      (Req_symm (Rmul_RsumN_left (Rmul (f n) (f n)) (fun i => Rmul (g i) (g i)) n))
  · refine Req_trans (RsumN_add
      (fun i => Rmul (Rmul (f i) (g i)) (Rmul (f n) (g n)))
      (fun i => Rmul (Rmul (f i) (g i)) (Rmul (f n) (g n))) n) ?_
    exact Radd_congr
      (RsumN_mul_const (fun i => Rmul (f i) (g i)) (Rmul (f n) (g n)) n)
      (RsumN_mul_const (fun i => Rmul (f i) (g i)) (Rmul (f n) (g n)) n)

/-- The abelian shuffle of the Lagrange induction step: `((AB+AQ)+(PB+PQ)) − ((CC+CR)+(CR+PQ))
    ≈ (AB−CC) + ((AQ+PB) − (CR+CR))` — pairwise `Rsub_Radd_Radd` splits plus the `PQ` pair
    cancelling. -/
private theorem lag_shuffle (AB AQ PB PQ CC CR : Real) :
    Req (Rsub (Radd (Radd AB AQ) (Radd PB PQ)) (Radd (Radd CC CR) (Radd CR PQ)))
        (Radd (Rsub AB CC) (Rsub (Radd AQ PB) (Radd CR CR))) := by
  refine Req_trans (Rsub_Radd_Radd (Radd AB AQ) (Radd PB PQ) (Radd CC CR) (Radd CR PQ)) ?_
  refine Req_trans (Radd_congr (Rsub_Radd_Radd AB AQ CC CR) (Rsub_Radd_Radd PB PQ CR PQ)) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Req_trans (Radd_congr (Req_refl _) (Radd_neg PQ)) (Radd_zero (Rsub PB CR)))) ?_
  refine Req_trans (Radd_assoc (Rsub AB CC) (Rsub AQ CR) (Rsub PB CR)) ?_
  exact Radd_congr (Req_refl _) (Req_symm (Rsub_Radd_Radd AQ PB CR CR))

/-- **THE LAGRANGE IDENTITY**: the Cauchy–Schwarz defect is an EXPLICIT sum of squares —

    `⟨f,f⟩_N·⟨g,g⟩_N − ⟨f,g⟩_N² ≈ Σ_{j<N} Σ_{i<j} (fᵢgⱼ − fⱼgᵢ)²`.

    Induction on the truncation: the new outer index `n` contributes exactly the row
    `Σ_{i<n} (fᵢgₙ − fₙgᵢ)²` (`cross_row`), and the binomial cross terms cancel pairwise
    (`lag_shuffle`). The identity is the 2×2-minor (Gram) structure of the defect — the
    intrinsic SOS certificate, existing unconditionally at the pre-Hilbert level. -/
theorem lagrange_identity (f g : Nat → Real) (N : Nat) :
    Req (Rsub (Rmul (innerN f f N) (innerN g g N)) (Rmul (innerN f g N) (innerN f g N)))
        (lagSOS f g N) := by
  induction N with
  | zero =>
    show Req (Rsub (Rmul zero zero) (Rmul zero zero)) zero
    exact Radd_neg (Rmul zero zero)
  | succ n ih =>
    show Req (Rsub (Rmul (Radd (innerN f f n) (Rmul (f n) (f n)))
                         (Radd (innerN g g n) (Rmul (g n) (g n))))
                   (Rmul (Radd (innerN f g n) (Rmul (f n) (g n)))
                         (Radd (innerN f g n) (Rmul (f n) (g n)))))
             (Radd (lagSOS f g n)
                   (RsumN (fun i => Rmul (crossD f g i n) (crossD f g i n)) n))
    have h1 : Req (Rmul (Radd (innerN f f n) (Rmul (f n) (f n)))
                        (Radd (innerN g g n) (Rmul (g n) (g n))))
                  (Radd (Radd (Rmul (innerN f f n) (innerN g g n))
                              (Rmul (innerN f f n) (Rmul (g n) (g n))))
                        (Radd (Rmul (Rmul (f n) (f n)) (innerN g g n))
                              (Rmul (Rmul (f n) (f n)) (Rmul (g n) (g n))))) :=
      Rmul_add_add (innerN f f n) (Rmul (f n) (f n)) (innerN g g n) (Rmul (g n) (g n))
    have h2 : Req (Rmul (Radd (innerN f g n) (Rmul (f n) (g n)))
                        (Radd (innerN f g n) (Rmul (f n) (g n))))
                  (Radd (Radd (Rmul (innerN f g n) (innerN f g n))
                              (Rmul (innerN f g n) (Rmul (f n) (g n))))
                        (Radd (Rmul (innerN f g n) (Rmul (f n) (g n)))
                              (Rmul (Rmul (f n) (f n)) (Rmul (g n) (g n))))) := by
      refine Req_trans (Rmul_add_add (innerN f g n) (Rmul (f n) (g n))
        (innerN f g n) (Rmul (f n) (g n))) ?_
      exact Radd_congr (Req_refl _)
        (Radd_congr (Rmul_comm (Rmul (f n) (g n)) (innerN f g n))
                    (prod_sq_reassoc (f n) (g n)))
    refine Req_trans (Rsub_congr h1 h2) ?_
    refine Req_trans (lag_shuffle
      (Rmul (innerN f f n) (innerN g g n))
      (Rmul (innerN f f n) (Rmul (g n) (g n)))
      (Rmul (Rmul (f n) (f n)) (innerN g g n))
      (Rmul (Rmul (f n) (f n)) (Rmul (g n) (g n)))
      (Rmul (innerN f g n) (innerN f g n))
      (Rmul (innerN f g n) (Rmul (f n) (g n)))) ?_
    exact Radd_congr ih (Req_symm (cross_row f g n))

/-- **CAUCHY–SCHWARZ, sqrt-free**: `⟨f,g⟩_N² ≤ ⟨f,f⟩_N·⟨g,g⟩_N`. The defect is the Lagrange
    SOS (`lagrange_identity`), which is nonnegative (`lagSOS_nonneg`); no discriminant, no
    division, no square root. The first structural theorem of the step-3 Hilbert layer. -/
theorem cauchy_schwarz (f g : Nat → Real) (N : Nat) :
    Rle (Rmul (innerN f g N) (innerN f g N)) (Rmul (innerN f f N) (innerN g g N)) :=
  Rle_of_Rnonneg_Rsub (Rnonneg_congr (Req_symm (lagrange_identity f g N)) (lagSOS_nonneg f g N))

end Multiplicity.UOR.Bridge.F1Square.Square
