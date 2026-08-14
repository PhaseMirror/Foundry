/-
F1 square — **the monotone dyadic bracket**: for a sample-antitone integrand the dyadic Riemann
sums decrease with the level and their total drop telescopes, so ONE finite dyadic sum brackets
the certified integral two-sidedly:

    `D_M − V/2^M  ≤  ∫₀¹ f  ≤  D_M`,   `V ≥ f(0) − f(1)` rational, `D_M = riemannSum f (2^M − 1)`.

Mechanism: the refinement regroup (`riemannSum_refine_regroup`, the pure-algebra core of
`riemannSum_refine`) writes `R_{2N+1} − R_N = w·Σ(f(odd) − f(even))`; antitone samples make every
pair term `≤ 0` (level-antitone) and `≥ f((j+1)/(N+1)) − f(j/(N+1))` (the interleave), which
telescopes to `f(1) − f(0)` (level gap `≤ V/2^{m+1}` per step, geometric sum `≤ V/2^M`). The limit
inherits both bounds (`Rlim_le_const` / `const_le_Rlim`) once the schedule keeps every partial sum
at level `≥ M` (`M ≤ digammaMidx L j`, arranged by weakening the Lipschitz modulus `L`).

This is the bracket engine for integrals with NO closed form (the `t4` dilog `∫₁⁴ log x/(x−1) dx`):
the bracket needs only the finite sum `D_M`, whose samples are exact built objects.

HONEST SCOPE. A bracket engine, general in the integrand; no integral is evaluated and no slot
field is touched. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.IntegralLocal
import Multiplicity.F1Square.Analysis.SqrtRealSq
import Multiplicity.F1Square.Analysis.HarmonicLog

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **Sample-antitone on `[0,1]`**: `f` is decreasing at the rational points of the unit interval.
    This is the hypothesis the dyadic sums see (they only sample rationals). -/
def SampleAnti (f : Real → Real) : Prop :=
  ∀ (a b : Q) (had : 0 < a.den) (hbd : 0 < b.den),
    Qle (⟨0, 1⟩ : Q) a → Qle a b → Qle b (⟨1, 1⟩ : Q) →
    Rle (f (ofQ b hbd)) (f (ofQ a had))

/-- **A constant real below every term is below the limit**: `(∀k, B ≤ X k) ⟹ B ≤ lim X` — the
    mirror of `Rlim_le_const`, via the convergence rate `X k − lim X ≤ 2/(k+1)`. -/
theorem const_le_Rlim {X : Nat → Real} (hX : RReg X) {B : Real} (h : ∀ k, Rle B (X k)) :
    Rle B (Rlim X hX) := by
  refine Rle_of_Rsub_le_eps (C := 2) (fun k => ?_)
  refine Rle_trans (Radd_le_add (h k) (Rle_refl (Rneg (Rlim X hX)))) ?_
  exact RTendsTo_Rsub_le (Rlim_tendsTo X hX) k

/-- **Finite difference sums telescope**: `Σ_{j<N}(G(j+1) − G(j)) ≈ G(N) − G(0)`. -/
theorem RsumN_telescope (G : Nat → Real) :
    ∀ N, Req (RsumN (fun j => Rsub (G (j + 1)) (G j)) N) (Rsub (G N) (G 0))
  | 0 => Req_symm (Radd_neg (G 0))
  | (N + 1) =>
      Req_trans (Radd_congr (RsumN_telescope G N) (Req_refl (Rsub (G (N + 1)) (G N))))
        (Radd_Rsub_Rsub (G N) (G 0) (G (N + 1)))

/-- `−(a − b) ≈ b − a` (negated difference flips). -/
theorem Rneg_Rsub_flip (a b : Real) : Req (Rneg (Rsub a b)) (Rsub b a) :=
  Req_trans (Rneg_Radd a (Rneg b))
    (Req_trans (Radd_congr (Req_refl (Rneg a)) (Rneg_neg b)) (Radd_comm (Rneg a) b))

/-- `x − y ≤ c ⟹ x ≤ y + c` (difference bound unshuffles). -/
theorem Rle_Radd_of_Rsub_le {x y c : Real} (h : Rle (Rsub x y) c) : Rle x (Radd y c) :=
  Rle_trans (Rle_of_Req (Req_symm (Radd_Rsub_cancel x y)))
    (Radd_le_add (Rle_refl y) h)

/-- `x ≤ y ⟹ x − y ≤ 0` (local difference form). -/
private theorem msub_nonpos {x y : Real} (h : Rle x y) : Rle (Rsub x y) zero :=
  Rle_trans (Radd_le_add h (Rle_refl (Rneg y))) (Rle_of_Req (Radd_neg y))

/-- **`∫₀¹ f ≤ ∫₀¹ g` from `f ≤ g` at the dyadic sample points only** (shared modulus `L`) — the
    sample-level sharpening of `riemannIntegral_le_unit`: the dyadic sums only ever evaluate the
    integrands at `i/(N+1)`, so the comparison is only needed there. This is the comparison form
    for integrands whose sample values are exact built objects (e.g. rational `clampedInv` folds). -/
theorem riemannIntegral_le_sample {f g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y))
    (hfg : ∀ (N i : Nat), i < N + 1 →
      Rle (f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
          (g (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N)))) :
    Rle (riemannIntegral hLd hLn hlipf hfcf) (riemannIntegral hLd hLn hlipg hfcg) := by
  have hZfReg : RReg (fun j => Radd (dyadicR f 0) (genSum (dyadicTerm f) (digammaMidx L j))) :=
    RReg_add_const (dyadicR f 0) _ (dyadicSum_RReg hLd hLn hlipf hfcf)
  have hZgReg : RReg (fun j => Radd (dyadicR g 0) (genSum (dyadicTerm g) (digammaMidx L j))) :=
    RReg_add_const (dyadicR g 0) _ (dyadicSum_RReg hLd hLn hlipg hfcg)
  have hZle : ∀ j, Rle (Radd (dyadicR f 0) (genSum (dyadicTerm f) (digammaMidx L j)))
      (Radd (dyadicR g 0) (genSum (dyadicTerm g) (digammaMidx L j))) := fun j =>
    Rle_trans (Rle_of_Req (Req_symm (dyadicR_eq f (digammaMidx L j))))
      (Rle_trans (riemannSum_le (2 ^ digammaMidx L j - 1)
          (fun i hi => hfg _ i hi))
        (Rle_of_Req (dyadicR_eq g (digammaMidx L j))))
  refine Rle_trans (Rle_of_Req (Req_symm
      (Rlim_add_const (dyadicR f 0) _ (dyadicSum_RReg hLd hLn hlipf hfcf) hZfReg))) ?_
  exact Rle_trans (Rlim_le_seq hZfReg hZgReg hZle)
    (Rle_of_Req (Rlim_add_const (dyadicR g 0) _ (dyadicSum_RReg hLd hLn hlipg hfcg) hZgReg))

/-- **The refinement regroup** — the pure-algebra core of `riemannSum_refine`, no Lipschitz data:
    `R_{2N+1} − R_N ≈ (1/(2(N+1)))·Σ_{j<N+1}(f((2j+1)/(2(N+1))) − f(2j/(2(N+1))))` (even fine points
    coincide with the coarse points; the coarse weight splits in two). -/
theorem riemannSum_refine_regroup {f : Real → Real}
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (N : Nat) :
    Req (Rsub (riemannSum f (2 * N + 1)) (riemannSum f N))
        (Rmul (ofQ (⟨1, 2 * (N + 1)⟩ : Q) (Nat.mul_pos (by decide) (Nat.succ_pos N)))
          (RsumN (fun j =>
            Rsub (f (ofQ (⟨((2 * j + 1 : Nat) : Int), 2 * (N + 1)⟩ : Q)
                    (Nat.mul_pos (by decide) (Nat.succ_pos N))))
                 (f (ofQ (⟨((2 * j : Nat) : Int), 2 * (N + 1)⟩ : Q)
                    (Nat.mul_pos (by decide) (Nat.succ_pos N))))) (N + 1))) := by
  have hMpos : 0 < N + 1 := Nat.succ_pos N
  have d2 : 0 < 2 * (N + 1) := Nat.mul_pos (by decide) hMpos
  let w2 := ofQ (⟨1, 2 * (N + 1)⟩ : Q) d2
  let w1 := ofQ (⟨1, N + 1⟩ : Q) hMpos
  let F : Nat → Real := fun i => f (ofQ (⟨(i : Int), 2 * (N + 1)⟩ : Q) d2)
  let G : Nat → Real := fun j => f (ofQ (⟨(j : Int), N + 1⟩ : Q) hMpos)
  have hR1 : Req (riemannSum f (2 * N + 1)) (Rmul w2 (RsumN F (2 * (N + 1)))) := Req_refl _
  have hR0 : Req (riemannSum f N) (Rmul w1 (RsumN G (N + 1))) := Req_refl _
  have hsplit : Req (RsumN F (2 * (N + 1)))
      (Radd (RsumN (fun j => F (2 * j)) (N + 1)) (RsumN (fun j => F (2 * j + 1)) (N + 1))) :=
    RsumN_split2 F (N + 1)
  have heven : Req (RsumN (fun j => F (2 * j)) (N + 1)) (RsumN G (N + 1)) :=
    RsumN_congr (N + 1) (fun j _ =>
      hfc _ _ (ofQ_congr d2 hMpos (by simp only [Qeq]; push_cast; ring_uor)))
  have hw1split : Req w1 (Radd w2 w2) :=
    Req_symm (Req_trans (Radd_ofQ_ofQ d2 d2)
      (ofQ_congr (add_den_pos d2 d2) hMpos (by simp only [Qeq, add]; push_cast; ring_uor)))
  have hA : Req (Rmul w2 (RsumN F (2 * (N + 1))))
      (Radd (Rmul w2 (RsumN (fun j => F (2 * j)) (N + 1)))
            (Rmul w2 (RsumN (fun j => F (2 * j + 1)) (N + 1)))) :=
    Req_trans (Rmul_congr (Req_refl w2) hsplit) (Rmul_distrib w2 _ _)
  have hBb : Req (Rmul w1 (RsumN G (N + 1)))
      (Radd (Rmul w2 (RsumN (fun j => F (2 * j)) (N + 1)))
            (Rmul w2 (RsumN (fun j => F (2 * j)) (N + 1)))) := by
    refine Req_trans (Rmul_congr hw1split (Req_refl _)) ?_
    refine Req_trans (Rmul_distrib_right w2 w2 (RsumN G (N + 1))) ?_
    exact Radd_congr (Rmul_congr (Req_refl w2) (Req_symm heven))
      (Rmul_congr (Req_refl w2) (Req_symm heven))
  refine Req_trans (Rsub_congr (Req_trans hR1 hA) (Req_trans hR0 hBb)) ?_
  refine Req_trans (Rsub_Radd_Radd _ _ _ _) ?_
  refine Req_trans (Radd_congr (Radd_neg _) (Req_refl _)) ?_
  refine Req_trans (Req_trans (Radd_comm zero _) (Radd_zero _)) ?_
  refine Req_trans (Req_symm (Rmul_sub_distrib w2 _ _)) ?_
  exact Rmul_congr (Req_refl w2) (Req_symm (RsumN_Rsub _ _ (N + 1)))

/-- **Refinement is antitone for antitone samples**: `R_{2N+1} ≤ R_N` (each odd fine point sits
    right of its even partner, so every regrouped pair term is `≤ 0`). -/
theorem riemannSum_refine_anti {f : Real → Real}
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hanti : SampleAnti f) (N : Nat) :
    Rle (riemannSum f (2 * N + 1)) (riemannSum f N) := by
  have hMpos : 0 < N + 1 := Nat.succ_pos N
  have d2 : 0 < 2 * (N + 1) := Nat.mul_pos (by decide) hMpos
  have hpair : ∀ j, j < N + 1 →
      Rle (Rsub (f (ofQ (⟨((2 * j + 1 : Nat) : Int), 2 * (N + 1)⟩ : Q) d2))
                (f (ofQ (⟨((2 * j : Nat) : Int), 2 * (N + 1)⟩ : Q) d2))) zero := by
    intro j hj
    refine msub_nonpos (hanti _ _ d2 d2 ?_ ?_ ?_)
    · show Qle (⟨0, 1⟩ : Q) (⟨((2 * j : Nat) : Int), 2 * (N + 1)⟩ : Q)
      simp only [Qle]; push_cast; omega
    · show Qle (⟨((2 * j : Nat) : Int), 2 * (N + 1)⟩ : Q)
          (⟨((2 * j + 1 : Nat) : Int), 2 * (N + 1)⟩ : Q)
      simp only [Qle]; push_cast
      exact Int.mul_le_mul_of_nonneg_right (by omega) (by omega)
    · show Qle (⟨((2 * j + 1 : Nat) : Int), 2 * (N + 1)⟩ : Q) (⟨1, 1⟩ : Q)
      simp only [Qle]; push_cast; omega
  have hzero : Req (RsumN (fun _ : Nat => zero) (N + 1)) zero :=
    Req_trans (RsumN_const zero (N + 1)) (Rmul_zero (RofNat (N + 1)))
  have hsum : Rle (RsumN (fun j =>
      Rsub (f (ofQ (⟨((2 * j + 1 : Nat) : Int), 2 * (N + 1)⟩ : Q) d2))
           (f (ofQ (⟨((2 * j : Nat) : Int), 2 * (N + 1)⟩ : Q) d2))) (N + 1)) zero :=
    Rle_trans (RsumN_le (N + 1) (fun j hj => hpair j hj)) (Rle_of_Req hzero)
  have hw2 : Rnonneg (ofQ (⟨1, 2 * (N + 1)⟩ : Q) d2) :=
    Rnonneg_ofQ d2 (show (0 : Int) ≤ 1 by decide)
  have hmz : Req (Rmul (ofQ (⟨1, 2 * (N + 1)⟩ : Q) d2) zero) zero :=
    Rmul_zero (ofQ (⟨1, 2 * (N + 1)⟩ : Q) d2)
  have hdiff : Rle (Rsub (riemannSum f (2 * N + 1)) (riemannSum f N)) zero :=
    Rle_trans (Rle_of_Req (riemannSum_refine_regroup hfc N))
      (Rle_trans (Rmul_le_Rmul_left hw2 hsum) (Rle_of_Req hmz))
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_Rsub_cancel (riemannSum f (2 * N + 1))
    (riemannSum f N)))) ?_
  exact Rle_trans (Radd_le_add (Rle_refl (riemannSum f N)) hdiff)
    (Rle_of_Req (Radd_zero (riemannSum f N)))

/-- **The refinement drop is capped by the total variation**: for antitone samples,
    `R_N ≤ R_{2N+1} + V/(2(N+1))` whenever `f(0) − f(1) ≤ V` (the pair drops interleave into the
    coarse telescope, which collapses to the endpoint difference). -/
theorem riemannSum_refine_gap {f : Real → Real}
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hanti : SampleAnti f)
    {V : Q} (hVd : 0 < V.den)
    (hV : Rle (Rsub (f (ofQ (⟨0, 1⟩ : Q) Nat.one_pos)) (f (ofQ (⟨1, 1⟩ : Q) Nat.one_pos)))
              (ofQ V hVd)) (N : Nat) :
    Rle (riemannSum f N)
        (Radd (riemannSum f (2 * N + 1))
          (ofQ (mul (⟨1, 2 * (N + 1)⟩ : Q) V)
            (Qmul_den_pos (Nat.mul_pos (by decide) (Nat.succ_pos N)) hVd))) := by
  have hMpos : 0 < N + 1 := Nat.succ_pos N
  have d2 : 0 < 2 * (N + 1) := Nat.mul_pos (by decide) hMpos
  -- each pair term dominates the coarse difference: `G(j+1) − G(j) ≤ F(2j+1) − F(2j)`.
  have hpair : ∀ j, j < N + 1 →
      Rle (Rsub (f (ofQ (⟨(((j + 1) : Nat) : Int), N + 1⟩ : Q) hMpos))
                (f (ofQ (⟨((j : Nat) : Int), N + 1⟩ : Q) hMpos)))
          (Rsub (f (ofQ (⟨((2 * j + 1 : Nat) : Int), 2 * (N + 1)⟩ : Q) d2))
                (f (ofQ (⟨((2 * j : Nat) : Int), 2 * (N + 1)⟩ : Q) d2))) := by
    intro j hj
    have hcross : Rle (f (ofQ (⟨(((j + 1) : Nat) : Int), N + 1⟩ : Q) hMpos))
        (f (ofQ (⟨((2 * j + 1 : Nat) : Int), 2 * (N + 1)⟩ : Q) d2)) := by
      refine hanti _ _ d2 hMpos ?_ ?_ ?_
      · show Qle (⟨0, 1⟩ : Q) (⟨((2 * j + 1 : Nat) : Int), 2 * (N + 1)⟩ : Q)
        simp only [Qle]; push_cast; omega
      · show Qle (⟨((2 * j + 1 : Nat) : Int), 2 * (N + 1)⟩ : Q)
            (⟨(((j + 1) : Nat) : Int), N + 1⟩ : Q)
        simp only [Qle]; push_cast
        have hm := Int.mul_le_mul_of_nonneg_right
          (show ((2 : Int) * j + 1) ≤ 2 * ((j : Int) + 1) by omega)
          (show (0 : Int) ≤ ((N : Int) + 1) by omega)
        rw [show ((j : Int) + 1) * (2 * ((N : Int) + 1)) = (2 * ((j : Int) + 1)) * ((N : Int) + 1)
          from by rw [Int.mul_comm 2 ((j : Int) + 1), Int.mul_assoc]]
        exact hm
      · show Qle (⟨(((j + 1) : Nat) : Int), N + 1⟩ : Q) (⟨1, 1⟩ : Q)
        simp only [Qle]; push_cast; omega
    have heven : Req (f (ofQ (⟨((2 * j : Nat) : Int), 2 * (N + 1)⟩ : Q) d2))
        (f (ofQ (⟨((j : Nat) : Int), N + 1⟩ : Q) hMpos)) :=
      hfc _ _ (ofQ_congr d2 hMpos (by simp only [Qeq]; push_cast; ring_uor))
    exact Radd_le_add hcross (Rle_Rneg (Rle_of_Req heven))
  -- fold: `Σ pair terms ≥ Σ coarse diffs ≈ G(N+1) − G(0) ≥ −V`.
  have htele : Req (RsumN (fun j =>
      Rsub (f (ofQ (⟨(((j + 1) : Nat) : Int), N + 1⟩ : Q) hMpos))
           (f (ofQ (⟨((j : Nat) : Int), N + 1⟩ : Q) hMpos))) (N + 1))
      (Rsub (f (ofQ (⟨(((N + 1) : Nat) : Int), N + 1⟩ : Q) hMpos))
            (f (ofQ (⟨((0 : Nat) : Int), N + 1⟩ : Q) hMpos))) :=
    RsumN_telescope (fun j => f (ofQ (⟨((j : Nat) : Int), N + 1⟩ : Q) hMpos)) (N + 1)
  have hsum : Rle (Rsub (f (ofQ (⟨(((N + 1) : Nat) : Int), N + 1⟩ : Q) hMpos))
                        (f (ofQ (⟨((0 : Nat) : Int), N + 1⟩ : Q) hMpos)))
      (RsumN (fun j =>
        Rsub (f (ofQ (⟨((2 * j + 1 : Nat) : Int), 2 * (N + 1)⟩ : Q) d2))
             (f (ofQ (⟨((2 * j : Nat) : Int), 2 * (N + 1)⟩ : Q) d2))) (N + 1)) :=
    Rle_trans (Rle_of_Req (Req_symm htele)) (RsumN_le (N + 1) (fun j hj => hpair j hj))
  have hends : Rle (Rneg (ofQ V hVd))
      (Rsub (f (ofQ (⟨(((N + 1) : Nat) : Int), N + 1⟩ : Q) hMpos))
            (f (ofQ (⟨((0 : Nat) : Int), N + 1⟩ : Q) hMpos))) := by
    have hG0 : Req (f (ofQ (⟨((0 : Nat) : Int), N + 1⟩ : Q) hMpos))
        (f (ofQ (⟨0, 1⟩ : Q) Nat.one_pos)) :=
      hfc _ _ (ofQ_congr hMpos Nat.one_pos (by simp only [Qeq]; push_cast; ring_uor))
    have hG1 : Req (f (ofQ (⟨(((N + 1) : Nat) : Int), N + 1⟩ : Q) hMpos))
        (f (ofQ (⟨1, 1⟩ : Q) Nat.one_pos)) :=
      hfc _ _ (ofQ_congr hMpos Nat.one_pos (by simp only [Qeq]; push_cast; ring_uor))
    have hflip : Req (Rneg (Rsub (f (ofQ (⟨0, 1⟩ : Q) Nat.one_pos))
        (f (ofQ (⟨1, 1⟩ : Q) Nat.one_pos))))
        (Rsub (f (ofQ (⟨1, 1⟩ : Q) Nat.one_pos)) (f (ofQ (⟨0, 1⟩ : Q) Nat.one_pos))) :=
      Rneg_Rsub_flip (f (ofQ (⟨0, 1⟩ : Q) Nat.one_pos)) (f (ofQ (⟨1, 1⟩ : Q) Nat.one_pos))
    refine Rle_trans (Rle_Rneg hV) ?_
    refine Rle_trans (Rle_of_Req hflip) ?_
    exact Rle_of_Req (Rsub_congr (Req_symm hG1) (Req_symm hG0))
  -- assemble: `R_N − R_{2N+1} ≈ −(w·Σ) ≤ −(w·(−V)) ≈ w·V`.
  have hw2 : Rnonneg (ofQ (⟨1, 2 * (N + 1)⟩ : Q) d2) :=
    Rnonneg_ofQ d2 (show (0 : Int) ≤ 1 by decide)
  have hge : Rle (Rmul (ofQ (⟨1, 2 * (N + 1)⟩ : Q) d2) (Rneg (ofQ V hVd)))
      (Rsub (riemannSum f (2 * N + 1)) (riemannSum f N)) :=
    Rle_trans (Rmul_le_Rmul_left hw2 (Rle_trans hends hsum))
      (Rle_of_Req (Req_symm (riemannSum_refine_regroup hfc N)))
  have hneg : Rle (Rsub (riemannSum f N) (riemannSum f (2 * N + 1)))
      (Rneg (Rmul (ofQ (⟨1, 2 * (N + 1)⟩ : Q) d2) (Rneg (ofQ V hVd)))) :=
    Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub_flip (riemannSum f (2 * N + 1))
      (riemannSum f N)))) (Rle_Rneg hge)
  have hcollapse : Req (Rneg (Rmul (ofQ (⟨1, 2 * (N + 1)⟩ : Q) d2) (Rneg (ofQ V hVd))))
      (ofQ (mul (⟨1, 2 * (N + 1)⟩ : Q) V) (Qmul_den_pos d2 hVd)) :=
    Req_trans (Rneg_congr (Rmul_neg_right (ofQ (⟨1, 2 * (N + 1)⟩ : Q) d2) (ofQ V hVd)))
      (Req_trans (Rneg_neg (Rmul (ofQ (⟨1, 2 * (N + 1)⟩ : Q) d2) (ofQ V hVd)))
        (Rmul_ofQ_ofQ d2 hVd))
  exact Rle_Radd_of_Rsub_le (Rle_trans hneg (Rle_of_Req hcollapse))

/-- Dyadic transport of `riemannSum_refine_anti`: `D_{m+1} ≤ D_m`. -/
theorem dyadicR_anti_step {f : Real → Real}
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hanti : SampleAnti f) (m : Nat) :
    Rle (dyadicR f (m + 1)) (dyadicR f m) := by
  have hidx : 2 ^ (m + 1) - 1 = 2 * (2 ^ m - 1) + 1 := by
    have hpow : 2 ^ (m + 1) = 2 * 2 ^ m := by rw [Nat.pow_succ]; omega
    have h1 : 1 ≤ 2 ^ m := Nat.one_le_two_pow
    omega
  show Rle (riemannSum f (2 ^ (m + 1) - 1)) (riemannSum f (2 ^ m - 1))
  rw [hidx]
  exact riemannSum_refine_anti hfc hanti (2 ^ m - 1)

/-- Dyadic transport of `riemannSum_refine_gap`: `D_m ≤ D_{m+1} + V/(2·2^m)`. -/
theorem dyadicR_gap_step {f : Real → Real}
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hanti : SampleAnti f)
    {V : Q} (hVd : 0 < V.den)
    (hV : Rle (Rsub (f (ofQ (⟨0, 1⟩ : Q) Nat.one_pos)) (f (ofQ (⟨1, 1⟩ : Q) Nat.one_pos)))
              (ofQ V hVd)) (m : Nat) :
    Rle (dyadicR f m)
        (Radd (dyadicR f (m + 1))
          (ofQ (mul (⟨1, 2 * 2 ^ m⟩ : Q) V)
            (Qmul_den_pos (Nat.mul_pos (by decide) (Nat.pos_pow_of_pos m (by decide))) hVd))) := by
  have h1 : 1 ≤ 2 ^ m := Nat.one_le_two_pow
  have hidx : 2 ^ (m + 1) - 1 = 2 * (2 ^ m - 1) + 1 := by
    have hpow : 2 ^ (m + 1) = 2 * 2 ^ m := by rw [Nat.pow_succ]; omega
    omega
  have hstep := riemannSum_refine_gap hfc hanti hVd hV (2 ^ m - 1)
  show Rle (riemannSum f (2 ^ m - 1)) _
  refine Rle_trans hstep (Rle_of_Req (Radd_congr ?_ ?_))
  · show Req (riemannSum f (2 * (2 ^ m - 1) + 1)) (riemannSum f (2 ^ (m + 1) - 1))
    rw [hidx]
    exact Req_refl _
  · refine ofQ_congr _ _ ?_
    show Qeq (mul (⟨1, 2 * (2 ^ m - 1 + 1)⟩ : Q) V) (mul (⟨1, 2 * 2 ^ m⟩ : Q) V)
    have hden : 2 ^ m - 1 + 1 = 2 ^ m := by omega
    rw [hden]
    exact Qeq_refl _

/-- **Levels are antitone**: `D_{M+d} ≤ D_M` for antitone samples. -/
theorem dyadicR_level_anti {f : Real → Real}
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hanti : SampleAnti f) (M : Nat) :
    ∀ d, Rle (dyadicR f (M + d)) (dyadicR f M)
  | 0 => Rle_refl _
  | (d + 1) =>
      Rle_trans (dyadicR_anti_step hfc hanti (M + d)) (dyadicR_level_anti hfc hanti M d)

/-- The geometric gap fold: `V/(2A) + ((B−1)/A)·V = ((2B−1)/(2A))·V` (rational identity). -/
private theorem gap_fold_q (V : Q) (A B : Nat) (hB : 1 ≤ B) :
    Qeq (add (mul (⟨1, 2 * A⟩ : Q) V) (mul (⟨((B - 1 : Nat) : Int), A⟩ : Q) V))
        (mul (⟨((2 * B - 1 : Nat) : Int), 2 * A⟩ : Q) V) := by
  simp only [Qeq, add, mul]
  push_cast [Int.ofNat_sub hB, Int.ofNat_sub (show 1 ≤ 2 * B by omega)]
  ring_uor

/-- The geometric gap cap: `((B−1)/(A·B))·V ≤ (1/A)·V` for `V ≥ 0` (rational weakening). -/
private theorem gap_cap_q (V : Q) (hVn : 0 ≤ V.num) (A B : Nat) (_hB : 1 ≤ B) :
    Qle (mul (⟨((B - 1 : Nat) : Int), A * B⟩ : Q) V) (mul (⟨1, A⟩ : Q) V) := by
  simp only [Qle, mul]
  have hnat : (B - 1) * (A * V.den) ≤ (A * B) * V.den := by
    calc (B - 1) * (A * V.den) ≤ B * (A * V.den) :=
          Nat.mul_le_mul_right _ (Nat.sub_le B 1)
      _ = (A * B) * V.den := by rw [Nat.mul_left_comm, Nat.mul_assoc]
  calc (((B - 1 : Nat) : Int) * V.num) * ((A * V.den : Nat) : Int)
      = V.num * (((B - 1 : Nat) : Int) * ((A * V.den : Nat) : Int)) := by
        rw [Int.mul_comm ((B - 1 : Nat) : Int) V.num, Int.mul_assoc]
    _ = V.num * (((B - 1) * (A * V.den) : Nat) : Int) := by
        push_cast; ring_uor
    _ ≤ V.num * (((A * B) * V.den : Nat) : Int) :=
        Int.mul_le_mul_of_nonneg_left (Int.ofNat_le.mpr hnat) hVn
    _ = (1 * V.num) * (((A * B) * V.den : Nat) : Int) := by
        rw [Int.one_mul]

/-- **The accumulated level gap**: `D_M ≤ D_{M+d} + ((2^d−1)/2^{M+d})·V` — the per-step geometric
    drops sum to strictly less than `V/2^M`. -/
theorem dyadicR_level_gap {f : Real → Real}
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hanti : SampleAnti f)
    {V : Q} (hVd : 0 < V.den)
    (hV : Rle (Rsub (f (ofQ (⟨0, 1⟩ : Q) Nat.one_pos)) (f (ofQ (⟨1, 1⟩ : Q) Nat.one_pos)))
              (ofQ V hVd)) (M : Nat) :
    ∀ d, Rle (dyadicR f M)
        (Radd (dyadicR f (M + d))
          (ofQ (mul (⟨((2 ^ d - 1 : Nat) : Int), 2 ^ (M + d)⟩ : Q) V)
            (Qmul_den_pos (Nat.pos_pow_of_pos (M + d) (by decide)) hVd)))
  | 0 => by
      have hzeroQ : Req (ofQ (mul (⟨((2 ^ 0 - 1 : Nat) : Int), 2 ^ (M + 0)⟩ : Q) V)
          (Qmul_den_pos (Nat.pos_pow_of_pos (M + 0) (by decide)) hVd)) zero := by
        refine Req_of_seq_Qeq (fun _ => ?_)
        show Qeq (mul (⟨((2 ^ 0 - 1 : Nat) : Int), 2 ^ (M + 0)⟩ : Q) V) (⟨0, 1⟩ : Q)
        simp only [Qeq, mul]; push_cast; ring_uor
      refine Rle_of_Req (Req_symm ?_)
      exact Req_trans (Radd_congr (Req_refl _) hzeroQ) (Radd_zero _)
  | (d + 1) => by
      have hB : 1 ≤ 2 ^ d := Nat.one_le_two_pow
      have dA : 0 < 2 ^ (M + d) := Nat.pos_pow_of_pos (M + d) (by decide)
      have d2A : 0 < 2 * 2 ^ (M + d) := Nat.mul_pos (by decide) dA
      have hstep := dyadicR_gap_step hfc hanti hVd hV (M + d)
      have hIH := dyadicR_level_gap hfc hanti hVd hV M d
      have hfold : Req (Radd (ofQ (mul (⟨1, 2 * 2 ^ (M + d)⟩ : Q) V) (Qmul_den_pos d2A hVd))
          (ofQ (mul (⟨((2 ^ d - 1 : Nat) : Int), 2 ^ (M + d)⟩ : Q) V) (Qmul_den_pos dA hVd)))
          (ofQ (mul (⟨((2 * 2 ^ d - 1 : Nat) : Int), 2 * 2 ^ (M + d)⟩ : Q) V)
            (Qmul_den_pos d2A hVd)) :=
        Req_trans (Radd_ofQ_ofQ (Qmul_den_pos d2A hVd) (Qmul_den_pos dA hVd))
          (ofQ_congr (add_den_pos (Qmul_den_pos d2A hVd) (Qmul_den_pos dA hVd))
            (Qmul_den_pos d2A hVd) (gap_fold_q V (2 ^ (M + d)) (2 ^ d) hB))
      have hident : Req (ofQ (mul (⟨((2 * 2 ^ d - 1 : Nat) : Int), 2 * 2 ^ (M + d)⟩ : Q) V)
          (Qmul_den_pos d2A hVd))
          (ofQ (mul (⟨((2 ^ (d + 1) - 1 : Nat) : Int), 2 ^ (M + (d + 1))⟩ : Q) V)
            (Qmul_den_pos (Nat.pos_pow_of_pos (M + (d + 1)) (by decide)) hVd)) := by
        refine ofQ_congr _ _ ?_
        rw [show (2 : Nat) ^ (d + 1) - 1 = 2 * 2 ^ d - 1 from by rw [Nat.pow_succ]; omega,
            show (2 : Nat) ^ (M + (d + 1)) = 2 * 2 ^ (M + d) from by
              rw [show M + (d + 1) = (M + d) + 1 from rfl, Nat.pow_succ]; omega]
        exact Qeq_refl _
      refine Rle_trans hIH ?_
      refine Rle_trans (Radd_le_add hstep (Rle_refl _)) ?_
      refine Rle_trans (Rle_of_Req (Radd_assoc (dyadicR f (M + d + 1)) _ _)) ?_
      exact Radd_le_add (Rle_refl (dyadicR f (M + d + 1)))
        (Rle_of_Req (Req_trans hfold hident))

/-- **The upper monotone bracket**: for an antitone integrand, `∫₀¹ f ≤ D_M` at every level the
    schedule reaches (`M ≤ digammaMidx L j` for all `j`; arrange by weakening `L`). -/
theorem riemannIntegral_anti_upper {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hanti : SampleAnti f) (M : Nat)
    (hM : ∀ j, M ≤ digammaMidx L j) :
    Rle (riemannIntegral hLd hLn hlip hfc) (dyadicR f M) := by
  have hreg : RReg (fun j => genSum (dyadicTerm f) (digammaMidx L j)) :=
    dyadicSum_RReg hLd hLn hlip hfc
  have hbound : ∀ k, Rle (genSum (dyadicTerm f) (digammaMidx L k))
      (Rsub (dyadicR f M) (dyadicR f 0)) := by
    intro k
    have hd : digammaMidx L k = M + (digammaMidx L k - M) := by
      have := hM k; omega
    have hlvl : Rle (dyadicR f (digammaMidx L k)) (dyadicR f M) := by
      rw [hd]; exact dyadicR_level_anti hfc hanti M _
    refine Rle_trans (Rle_of_Req (genSum_telescope f (digammaMidx L k))) ?_
    exact Radd_le_add hlvl (Rle_refl (Rneg (dyadicR f 0)))
  show Rle (Radd (dyadicR f 0)
    (Rlim (fun j => genSum (dyadicTerm f) (digammaMidx L j)) (dyadicSum_RReg hLd hLn hlip hfc)))
    (dyadicR f M)
  refine Rle_trans (Radd_le_add (Rle_refl (dyadicR f 0)) (Rlim_le_const hreg hbound)) ?_
  exact Rle_of_Req (Radd_Rsub_cancel (dyadicR f M) (dyadicR f 0))

/-- **The lower monotone bracket**: for an antitone integrand with endpoint variation `≤ V`,
    `D_M ≤ ∫₀¹ f + V/2^M` at every level the schedule reaches. Together with
    `riemannIntegral_anti_upper` this brackets the integral by ONE finite dyadic sum. -/
theorem riemannIntegral_anti_lower {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hanti : SampleAnti f)
    {V : Q} (hVd : 0 < V.den) (hVn : 0 ≤ V.num)
    (hV : Rle (Rsub (f (ofQ (⟨0, 1⟩ : Q) Nat.one_pos)) (f (ofQ (⟨1, 1⟩ : Q) Nat.one_pos)))
              (ofQ V hVd)) (M : Nat)
    (hM : ∀ j, M ≤ digammaMidx L j) :
    Rle (dyadicR f M)
        (Radd (riemannIntegral hLd hLn hlip hfc)
          (ofQ (mul (⟨1, 2 ^ M⟩ : Q) V)
            (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) hVd))) := by
  have hreg : RReg (fun j => genSum (dyadicTerm f) (digammaMidx L j)) :=
    dyadicSum_RReg hLd hLn hlip hfc
  have hbound : ∀ k, Rle (Rsub (Rsub (dyadicR f M)
      (ofQ (mul (⟨1, 2 ^ M⟩ : Q) V) (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) hVd)))
      (dyadicR f 0)) (genSum (dyadicTerm f) (digammaMidx L k)) := by
    intro k
    have hd : digammaMidx L k = M + (digammaMidx L k - M) := by
      have := hM k; omega
    have hcap : Qle (mul (⟨((2 ^ (digammaMidx L k - M) - 1 : Nat) : Int),
        2 ^ (M + (digammaMidx L k - M))⟩ : Q) V) (mul (⟨1, 2 ^ M⟩ : Q) V) := by
      rw [show (2 : Nat) ^ (M + (digammaMidx L k - M)) = 2 ^ M * 2 ^ (digammaMidx L k - M)
        from Nat.pow_add 2 M (digammaMidx L k - M)]
      exact gap_cap_q V hVn (2 ^ M) (2 ^ (digammaMidx L k - M)) Nat.one_le_two_pow
    have hDM : Rle (dyadicR f M)
        (Radd (dyadicR f (M + (digammaMidx L k - M)))
          (ofQ (mul (⟨1, 2 ^ M⟩ : Q) V)
            (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) hVd))) :=
      Rle_trans (dyadicR_level_gap hfc hanti hVd hV M (digammaMidx L k - M))
        (Radd_le_add (Rle_refl _) (Rle_ofQ_ofQ _ _ hcap))
    have h2 : Rle (Rsub (dyadicR f M)
        (ofQ (mul (⟨1, 2 ^ M⟩ : Q) V) (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) hVd)))
        (dyadicR f (M + (digammaMidx L k - M))) :=
      Rsub_le_of_le_Radd (Rle_trans hDM (Rle_of_Req (Radd_comm _ _)))
    have hb : Rle (Rsub (Rsub (dyadicR f M)
        (ofQ (mul (⟨1, 2 ^ M⟩ : Q) V) (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) hVd)))
        (dyadicR f 0)) (genSum (dyadicTerm f) (M + (digammaMidx L k - M))) :=
      Rle_trans (Radd_le_add h2 (Rle_refl (Rneg (dyadicR f 0))))
        (Rle_of_Req (Req_symm (genSum_telescope f (M + (digammaMidx L k - M)))))
    rw [← hd] at hb
    exact hb
  have hlim : Rle (Rsub (Rsub (dyadicR f M)
      (ofQ (mul (⟨1, 2 ^ M⟩ : Q) V) (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) hVd)))
      (dyadicR f 0))
      (Rlim (fun j => genSum (dyadicTerm f) (digammaMidx L j))
        (dyadicSum_RReg hLd hLn hlip hfc)) :=
    const_le_Rlim hreg hbound
  have hint : Rle (Rsub (dyadicR f M)
      (ofQ (mul (⟨1, 2 ^ M⟩ : Q) V) (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) hVd)))
      (riemannIntegral hLd hLn hlip hfc) := by
    show Rle _ (Radd (dyadicR f 0)
      (Rlim (fun j => genSum (dyadicTerm f) (digammaMidx L j)) (dyadicSum_RReg hLd hLn hlip hfc)))
    refine Rle_trans (Rle_of_Req (Req_symm (Radd_Rsub_cancel (Rsub (dyadicR f M)
      (ofQ (mul (⟨1, 2 ^ M⟩ : Q) V) (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) hVd)))
      (dyadicR f 0)))) ?_
    exact Radd_le_add (Rle_refl (dyadicR f 0)) hlim
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_Rsub_cancel (dyadicR f M)
    (ofQ (mul (⟨1, 2 ^ M⟩ : Q) V) (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) hVd))))) ?_
  refine Rle_trans (Radd_le_add (Rle_refl _) hint) ?_
  exact Rle_of_Req (Radd_comm _ _)

end Multiplicity.UOR.Bridge.F1Square.Analysis
