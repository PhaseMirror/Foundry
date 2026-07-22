/-
F1 square — certified integration, **convergence layer**: the per-pair Lipschitz estimate for the
dyadic Riemann-sum refinement.

For a Lipschitz integrand `f` (constant `L`), consecutive dyadic partition points `2j/(2M)` and
`(2j+1)/(2M)` are spaced `1/(2M)`, so `|f((2j+1)/(2M)) − f(2j/(2M))| ≤ L/(2M)`. This is the per-term
bound that, summed over the `M` even/odd pairs (`RsumN_split2`/`RsumN_Rabs_le`) and scaled by the
width `1/(2M)`, yields the geometric refinement `|R_M − R_{2M}| ≤ L/(4M)` → `RReg` → the `Rlim`
integral (the next step).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RiemannSum
import Core.F1.Analysis.RabsLemmas

namespace UOR.Bridge.F1Square.Analysis

/-- **The consecutive dyadic points are spaced `1/(2M)`**: `(2j+1)/(2M) − 2j/(2M) = 1/(2M)`. -/
theorem dyadic_pair_spacing (j M : Nat) (hM : 0 < M) :
    Req (Rsub (ofQ (⟨2 * j + 1, 2 * M⟩ : Q) (Nat.mul_pos (by decide) hM))
              (ofQ (⟨2 * j, 2 * M⟩ : Q) (Nat.mul_pos (by decide) hM)))
        (ofQ (⟨1, 2 * M⟩ : Q) (Nat.mul_pos (by decide) hM)) :=
  Req_of_seq_Qeq (fun _ => by
    show Qeq (add (⟨2 * j + 1, 2 * M⟩ : Q) (neg (⟨2 * j, 2 * M⟩ : Q))) (⟨1, 2 * M⟩ : Q)
    simp only [Qeq, add, neg]; push_cast; ring_uor)

/-- **The per-pair Lipschitz bound** `|f((2j+1)/(2M)) − f(2j/(2M))| ≤ L/(2M)`. From the Lipschitz
    hypothesis and the `1/(2M)` spacing (`dyadic_pair_spacing`, `Rabs_ofQ_nonneg`). -/
theorem dyadic_pair_lip {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (j M : Nat) (hM : 0 < M) :
    Rle (Rabs (Rsub (f (ofQ (⟨2 * j + 1, 2 * M⟩ : Q) (Nat.mul_pos (by decide) hM)))
                    (f (ofQ (⟨2 * j, 2 * M⟩ : Q) (Nat.mul_pos (by decide) hM)))))
        (ofQ (mul L (⟨1, 2 * M⟩ : Q)) (Qmul_den_pos hLd (Nat.mul_pos (by decide) hM))) := by
  refine Rle_trans (hlip _ _) ?_
  -- L·|p₂−p₁| ≤ L·(1/(2M)) = L/(2M)
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hLd hLn) ?_)
    (Rle_of_Req (Rmul_ofQ_ofQ hLd (Nat.mul_pos (by decide) hM)))
  -- |p₂ − p₁| ≤ 1/(2M)
  exact Rle_of_Req
    (Req_trans (Rabs_congr (dyadic_pair_spacing j M hM))
      (Rabs_ofQ_nonneg (Nat.mul_pos (by decide) hM) (show (0 : Int) ≤ 1 by decide)))

/-- `Radd zero x ≈ x` (left additive unit), via commutativity and the right unit. -/
private theorem Rzero_add (x : Real) : Req (Radd zero x) x :=
  Req_trans (Radd_comm zero x) (Radd_zero x)

/-- **The dyadic refinement bound** for a Lipschitz integrand: doubling the partition (from `N+1` to
    `2(N+1)` subintervals, i.e. parameter `N → 2N+1`) changes the Riemann sum by at most `L/(4(N+1))`,
    two-sided. This is the geometric per-step estimate that telescopes to convergence (`RReg → Rlim`).

    The proof regroups `R_{2N+1} − R_N` into `w·Σ_{j<N+1}(f((2j+1)/d) − f(2j/d))` with `w = 1/d`,
    `d = 2(N+1)` (even fine points coincide with the coarse points; the coarse weight `1/(N+1)` splits
    as `w + w`), then bounds each of the `N+1` pairs by `L/d` (`dyadic_pair_lip`), giving
    `w·(N+1)·(L/d) = L/(4(N+1))`. -/
theorem riemannSum_refine {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (N : Nat) :
    Rle (Rneg (ofQ (mul L (⟨1, 4 * (N + 1)⟩ : Q))
              (Qmul_den_pos hLd (Nat.mul_pos (by decide) (Nat.succ_pos N)))))
        (Rsub (riemannSum f (2 * N + 1)) (riemannSum f N))
    ∧ Rle (Rsub (riemannSum f (2 * N + 1)) (riemannSum f N))
          (ofQ (mul L (⟨1, 4 * (N + 1)⟩ : Q))
            (Qmul_den_pos hLd (Nat.mul_pos (by decide) (Nat.succ_pos N)))) := by
  have hMpos : 0 < N + 1 := Nat.succ_pos N
  have d2 : 0 < 2 * (N + 1) := Nat.mul_pos (by decide) hMpos
  have hL2 : 0 < (mul L (⟨1, 2 * (N + 1)⟩ : Q)).den := Qmul_den_pos hLd d2
  have hB : 0 < (mul L (⟨1, 4 * (N + 1)⟩ : Q)).den :=
    Qmul_den_pos hLd (Nat.mul_pos (by decide) hMpos)
  let w2 := ofQ (⟨1, 2 * (N + 1)⟩ : Q) d2
  let w1 := ofQ (⟨1, N + 1⟩ : Q) hMpos
  let F : Nat → Real := fun i => f (ofQ (⟨(i : Int), 2 * (N + 1)⟩ : Q) d2)
  let G : Nat → Real := fun j => f (ofQ (⟨(j : Int), N + 1⟩ : Q) hMpos)
  let c := ofQ (mul L (⟨1, 2 * (N + 1)⟩ : Q)) hL2
  -- `R_{2N+1}` and `R_N` in the `w·Σ` form (definitional: `(2N+1)+1 = 2(N+1)`).
  have hR1 : Req (riemannSum f (2 * N + 1)) (Rmul w2 (RsumN F (2 * (N + 1)))) := Req_refl _
  have hR0 : Req (riemannSum f N) (Rmul w1 (RsumN G (N + 1))) := Req_refl _
  -- even–odd split of the fine sum, even points coincide with the coarse points.
  have hsplit : Req (RsumN F (2 * (N + 1)))
      (Radd (RsumN (fun j => F (2 * j)) (N + 1)) (RsumN (fun j => F (2 * j + 1)) (N + 1))) :=
    RsumN_split2 F (N + 1)
  have heven : Req (RsumN (fun j => F (2 * j)) (N + 1)) (RsumN G (N + 1)) :=
    RsumN_congr (N + 1) (fun j _ =>
      hfc _ _ (ofQ_congr d2 hMpos (by simp only [Qeq]; push_cast; ring_uor)))
  -- `1/(N+1) = 1/(2(N+1)) + 1/(2(N+1))`.
  have hw1split : Req w1 (Radd w2 w2) :=
    Req_symm (Req_trans (Radd_ofQ_ofQ d2 d2)
      (ofQ_congr (add_den_pos d2 d2) hMpos (by simp only [Qeq, add]; push_cast; ring_uor)))
  -- regroup the difference into `w2·(S_odd − S_even)`.
  have hregroup : Req (Rsub (riemannSum f (2 * N + 1)) (riemannSum f N))
      (Rmul w2 (RsumN (fun j => Rsub (F (2 * j + 1)) (F (2 * j))) (N + 1))) := by
    have hA : Req (Rmul w2 (RsumN F (2 * (N + 1))))
        (Radd (Rmul w2 (RsumN (fun j => F (2 * j)) (N + 1)))
              (Rmul w2 (RsumN (fun j => F (2 * j + 1)) (N + 1)))) :=
      Req_trans (Rmul_congr (Req_refl w2) hsplit)
        (Rmul_distrib w2 _ _)
    have hBb : Req (Rmul w1 (RsumN G (N + 1)))
        (Radd (Rmul w2 (RsumN (fun j => F (2 * j)) (N + 1)))
              (Rmul w2 (RsumN (fun j => F (2 * j)) (N + 1)))) := by
      refine Req_trans (Rmul_congr hw1split (Req_refl _)) ?_
      refine Req_trans (Rmul_distrib_right w2 w2 (RsumN G (N + 1))) ?_
      exact Radd_congr (Rmul_congr (Req_refl w2) (Req_symm heven))
        (Rmul_congr (Req_refl w2) (Req_symm heven))
    -- assemble: (P+Q) − (P+P) ≈ Q − P, then fold `Σ(odd) − Σ(even) = Σ(odd − even)`.
    refine Req_trans (Rsub_congr (Req_trans hR1 hA) (Req_trans hR0 hBb)) ?_
    refine Req_trans (Rsub_Radd_Radd _ _ _ _) ?_
    refine Req_trans (Radd_congr (Radd_neg _) (Req_refl _)) ?_
    refine Req_trans (Rzero_add _) ?_
    refine Req_trans (Req_symm (Rmul_sub_distrib w2 _ _)) ?_
    exact Rmul_congr (Req_refl w2) (Req_symm (RsumN_Rsub _ _ (N + 1)))
  -- per-pair two-sided bound `|f((2j+1)/d) − f(2j/d)| ≤ L/d`, bridged to `F`-form.
  have hpairUp : ∀ j, Rle (Rsub (F (2 * j + 1)) (F (2 * j))) c := by
    intro j
    have hl := dyadic_pair_lip hLd hLn hlip j (N + 1) hMpos
    have hbr : Req (Rsub (F (2 * j + 1)) (F (2 * j)))
        (Rsub (f (ofQ (⟨2 * j + 1, 2 * (N + 1)⟩ : Q) (Nat.mul_pos (by decide) hMpos)))
              (f (ofQ (⟨2 * j, 2 * (N + 1)⟩ : Q) (Nat.mul_pos (by decide) hMpos)))) :=
      Rsub_congr (hfc _ _ (ofQ_congr d2 (Nat.mul_pos (by decide) hMpos)
                  (by simp only [Qeq]; push_cast; ring_uor)))
                 (hfc _ _ (ofQ_congr d2 (Nat.mul_pos (by decide) hMpos)
                  (by simp only [Qeq]; push_cast; ring_uor)))
    exact Rle_trans (Rle_of_Req hbr) (Rle_of_Rabs_le hl)
  have hpairLo : ∀ j, Rle (Rneg c) (Rsub (F (2 * j + 1)) (F (2 * j))) := by
    intro j
    have hl := dyadic_pair_lip hLd hLn hlip j (N + 1) hMpos
    have hbr : Req (Rsub (f (ofQ (⟨2 * j + 1, 2 * (N + 1)⟩ : Q) (Nat.mul_pos (by decide) hMpos)))
              (f (ofQ (⟨2 * j, 2 * (N + 1)⟩ : Q) (Nat.mul_pos (by decide) hMpos))))
        (Rsub (F (2 * j + 1)) (F (2 * j))) :=
      Rsub_congr (hfc _ _ (ofQ_congr (Nat.mul_pos (by decide) hMpos) d2
                  (by simp only [Qeq]; push_cast; ring_uor)))
                 (hfc _ _ (ofQ_congr (Nat.mul_pos (by decide) hMpos) d2
                  (by simp only [Qeq]; push_cast; ring_uor)))
    exact Rle_trans (Rneg_le_of_Rabs_le hl) (Rle_of_Req hbr)
  -- the constant-sum collapse `w2·((N+1)·(L/d)) = L/(4(N+1))`.
  have hval : Req (Rmul w2 (Rmul (RofNat (N + 1)) c))
      (ofQ (mul L (⟨1, 4 * (N + 1)⟩ : Q)) hB) := by
    refine Req_trans (Rmul_congr (Req_refl w2)
      (Rmul_ofQ_ofQ Nat.one_pos hL2)) ?_
    refine Req_trans (Rmul_ofQ_ofQ d2 (Qmul_den_pos Nat.one_pos hL2)) ?_
    exact ofQ_congr (Qmul_den_pos d2 (Qmul_den_pos Nat.one_pos hL2)) hB
      (by simp only [Qeq, mul]; push_cast; ring_uor)
  have hsumUp : Rle (RsumN (fun j => Rsub (F (2 * j + 1)) (F (2 * j))) (N + 1))
      (Rmul (RofNat (N + 1)) c) :=
    Rle_trans (RsumN_le (N + 1) (fun j _ => hpairUp j))
      (Rle_of_Req (RsumN_const c (N + 1)))
  have hsumLo : Rle (Rmul (RofNat (N + 1)) (Rneg c))
      (RsumN (fun j => Rsub (F (2 * j + 1)) (F (2 * j))) (N + 1)) :=
    Rle_trans (Rle_of_Req (Req_symm (RsumN_const (Rneg c) (N + 1))))
      (RsumN_le (N + 1) (fun j _ => hpairLo j))
  have hw2nn : Rnonneg w2 := Rnonneg_ofQ d2 (by show (0 : Int) ≤ 1; decide)
  constructor
  · -- lower bound
    refine Rle_trans ?_ (Rle_of_Req (Req_symm hregroup))
    refine Rle_trans (Rle_of_Req ?_) (Rmul_le_Rmul_left hw2nn hsumLo)
    -- −(L/(4(N+1))) ≈ w2·((N+1)·(−c))
    refine Req_trans (Rneg_congr (Req_symm hval)) ?_
    refine Req_trans (Req_symm (Rmul_neg_right w2 _)) ?_
    exact Rmul_congr (Req_refl w2) (Req_symm (Rmul_neg_right (RofNat (N + 1)) c))
  · -- upper bound
    refine Rle_trans (Rle_of_Req hregroup) ?_
    exact Rle_trans (Rmul_le_Rmul_left hw2nn hsumUp) (Rle_of_Req hval)

end UOR.Bridge.F1Square.Analysis
