/-
F1 square — certified integration, **convergence layer**: the dyadic Riemann sums of a Lipschitz
integrand form a regular sequence, so the integral exists as a Bishop limit.

The dyadic sequence `D k = riemannSum f (2^k − 1)` uses `2^k` equal subintervals. The refinement
bound (`riemannSum_refine`) gives `|D_{k+1} − D_k| ≤ L/(4·2^k)` (doubling the partition: parameter
`2^k−1 → 2(2^k−1)+1 = 2^{k+1}−1`). The geometric increment `L/(4·2^k)` sits under the digamma
envelope `K/((k+1)k)` (with `K = L`, since `(k+1)k ≤ 4·2^k`), so the generic regularity engine
`genSum_RReg` applies verbatim: the `L`-reindexed partial sums of the increments are `RReg`, and
`Rlim` produces the integral.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RiemannConv
import Core.F1.Analysis.ComplexDigamma
import Core.F1.Analysis.RlimProps

namespace UOR.Bridge.F1Square.Analysis

/-- **The digamma envelope** `(m+1)·m ≤ 4·2^m` — the geometric increment `L/(4·2^m)` sits under the
    `K/((m+1)m)` term-bound shape `genSum_RReg` requires (with `K = L`). -/
theorem two_mul_env : ∀ m : Nat, (m + 1) * m ≤ 4 * 2 ^ m
  | 0 => by decide
  | (m + 1) => by
    have ih := two_mul_env m
    have hk : m + 1 ≤ 2 ^ (m + 1) := Nat.le_of_lt Nat.lt_two_pow_self
    have hp : (m + 1 + 1) * (m + 1) = (m + 1) * m + 2 * (m + 1) := by
      simp only [Nat.succ_mul, Nat.mul_succ]; omega
    have hpow : 2 ^ (m + 1) = 2 * 2 ^ m := by rw [Nat.pow_succ]; omega
    omega

/-- **Denominator-antitone scaling**: for `L ≥ 0`, a larger denominator gives a smaller scaled
    fraction, `L/d₁ ≤ L/d₂` when `d₂ ≤ d₁`. Proved at the `Int` level (avoids the `mul`-`whnf`
    blowup). -/
theorem qmul_den_anti {L : Q} (hLn : 0 ≤ L.num) {d1 d2 : Nat}
    (h : d2 ≤ d1) : Qle (mul L (⟨1, d1⟩ : Q)) (mul L (⟨1, d2⟩ : Q)) := by
  show (L.num * 1) * ((L.den * d2 : Nat) : Int) ≤ (L.num * 1) * ((L.den * d1 : Nat) : Int)
  refine Int.mul_le_mul_of_nonneg_left ?_ (by simpa using hLn)
  exact_mod_cast Nat.mul_le_mul_left L.den h

/-- The dyadic Riemann sum with `2^k` equal subintervals on `[0,1]`. -/
def dyadicR (f : Real → Real) (k : Nat) : Real := riemannSum f (2 ^ k - 1)

/-- The refinement increment `D_{k+1} − D_k`. -/
def dyadicTerm (f : Real → Real) (k : Nat) : Real :=
  Rsub (dyadicR f (k + 1)) (dyadicR f k)

/-- **The dyadic increment two-sided bound** `|D_{m+1} − D_m| ≤ L/((m+1)m)` for `m ≥ 1` — the exact
    shape `genSum_RReg` consumes (with `K = L`). Built from `riemannSum_refine` (giving `L/(4·2^m)`)
    transported under the envelope `(m+1)m ≤ 4·2^m`. -/
theorem dyadicTerm_bound {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (m : Nat) (hm : 1 ≤ m) :
    Rle (Rneg (ofQ (mul L (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hLd (digamma_succ_mul_pos hm))))
        (dyadicTerm f m)
    ∧ Rle (dyadicTerm f m)
          (ofQ (mul L (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hLd (digamma_succ_mul_pos hm))) := by
  have hpow1 : 1 ≤ 2 ^ m := Nat.one_le_two_pow
  -- index identity: `D_{m+1} = riemannSum f (2·(2^m−1)+1)`.
  have hidx : 2 ^ (m + 1) - 1 = 2 * (2 ^ m - 1) + 1 := by
    have hpow : 2 ^ (m + 1) = 2 * 2 ^ m := by rw [Nat.pow_succ]; omega
    omega
  have hEqTerm : Req (dyadicTerm f m)
      (Rsub (riemannSum f (2 * (2 ^ m - 1) + 1)) (riemannSum f (2 ^ m - 1))) := by
    show Req (Rsub (riemannSum f (2 ^ (m + 1) - 1)) (riemannSum f (2 ^ m - 1)))
             (Rsub (riemannSum f (2 * (2 ^ m - 1) + 1)) (riemannSum f (2 ^ m - 1)))
    rw [hidx]; exact Req_refl _
  obtain ⟨hlo, hhi⟩ := riemannSum_refine hLd hLn hlip hfc (2 ^ m - 1)
  -- the refinement denominator `4·((2^m−1)+1) = 4·2^m` dominates `(m+1)·m`.
  have hden : (m + 1) * m ≤ 4 * (2 ^ m - 1 + 1) := by
    have := two_mul_env m; omega
  have hQle : Qle (mul L (⟨1, 4 * (2 ^ m - 1 + 1)⟩ : Q)) (mul L (⟨1, (m + 1) * m⟩ : Q)) :=
    qmul_den_anti hLn hden
  have hbd : Rle (ofQ (mul L (⟨1, 4 * (2 ^ m - 1 + 1)⟩ : Q))
                  (Qmul_den_pos hLd (Nat.mul_pos (by decide) (Nat.succ_pos (2 ^ m - 1)))))
                (ofQ (mul L (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hLd (digamma_succ_mul_pos hm))) :=
    Rle_ofQ_ofQ _ _ hQle
  constructor
  · refine Rle_trans ?_ (Rle_of_Req (Req_symm hEqTerm))
    refine Rle_trans (Rle_Rneg hbd) hlo
  · exact Rle_trans (Rle_of_Req hEqTerm) (Rle_trans hhi hbd)

/-- **The dyadic Riemann sums are a regular sequence** (`RReg`) — the input to Bishop's `Rlim`. The
    `L`-reindexed partial sums of the refinement increments converge (`genSum_RReg`), so the integral
    of a Lipschitz integrand exists constructively. -/
theorem dyadicSum_RReg {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) :
    RReg (fun j => genSum (dyadicTerm f) (digammaMidx L j)) :=
  genSum_RReg (dyadicTerm f) hLd hLn (fun m hm => dyadicTerm_bound hLd hLn hlip hfc m hm)

/-- **The certified Riemann integral** `∫₀¹ f` of a Lipschitz integrand — the Bishop limit of the
    dyadic Riemann sums, anchored at `D_0 = f(0)` plus the limit of the telescoping increments. -/
def riemannIntegral {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) : Real :=
  Radd (dyadicR f 0)
    (Rlim (fun j => genSum (dyadicTerm f) (digammaMidx L j)) (dyadicSum_RReg hLd hLn hlip hfc))

/-- The telescoping rearrangement `(a − b) + (c − a) ≈ c − b`. -/
theorem Radd_Rsub_Rsub (a b c : Real) :
    Req (Radd (Rsub a b) (Rsub c a)) (Rsub c b) :=
  Req_trans (Radd_comm (Rsub a b) (Rsub c a))
    (Req_trans (Radd_assoc c (Rneg a) (Radd a (Rneg b)))
      (Radd_congr (Req_refl c)
        (Req_trans (Req_symm (Radd_assoc (Rneg a) a (Rneg b)))
          (Req_trans
            (Radd_congr (Req_trans (Radd_comm (Rneg a) a) (Radd_neg a)) (Req_refl (Rneg b)))
            (Req_trans (Radd_comm zero (Rneg b)) (Radd_zero (Rneg b)))))))

/-- **The dyadic increments telescope**: `Σ_{k<M}(D_{k+1} − D_k) ≈ D_M − D_0`. So the integral
    `riemannIntegral f = D_0 + lim Σ` is the Bishop limit of the dyadic Riemann sums `D_k`. -/
theorem genSum_telescope (f : Real → Real) :
    ∀ M, Req (genSum (dyadicTerm f) M) (Rsub (dyadicR f M) (dyadicR f 0))
  | 0 => Req_symm (Radd_neg (dyadicR f 0))
  | (M + 1) => by
      refine Req_trans (Radd_congr (genSum_telescope f M) (Req_refl _)) ?_
      exact Radd_Rsub_Rsub (dyadicR f M) (dyadicR f 0) (dyadicR f (M + 1))

/-- The Lipschitz witness for a constant integrand (constant `0`). -/
private theorem const_lip (c : Real) : ∀ x y,
    Rle (Rabs (Rsub c c)) (Rmul (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  have hL : Req (Rabs (Rsub c c)) zero := Req_trans (Rabs_congr (Radd_neg c)) Rabs_zero
  have hz0 : Req (ofQ (⟨0, 1⟩ : Q) (by decide)) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)
  have hR : Req (Rmul (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) zero :=
    Req_trans (Rmul_congr hz0 (Req_refl _))
      (Req_trans (Rmul_comm zero (Rabs (Rsub x y))) (Rmul_zero (Rabs (Rsub x y))))
  exact Rle_trans (Rle_of_Req hL) (Rle_of_Req (Req_symm hR))

/-- **`∫₀¹ c = c`** — the certified integral of a constant integrand is the constant. The dyadic
    sums are all `≈ c` (`riemannSum_const`), so every telescoped partial sum is `≈ 0` and the limit
    vanishes; the `D_0` anchor carries the value. -/
theorem riemannIntegral_const (c : Real) :
    Req (riemannIntegral (f := fun _ => c) (L := (⟨0, 1⟩ : Q)) (by decide) (by decide)
          (const_lip c) (fun _ _ _ => Req_refl c)) c := by
  have hz : ∀ j, Req (genSum (dyadicTerm (fun _ => c)) (digammaMidx (⟨0, 1⟩ : Q) j)) zero := by
    intro j
    refine Req_trans (genSum_telescope (fun _ => c) (digammaMidx (⟨0, 1⟩ : Q) j)) ?_
    exact Req_trans
      (Rsub_congr (riemannSum_const c (2 ^ digammaMidx (⟨0, 1⟩ : Q) j - 1))
        (riemannSum_const c (2 ^ 0 - 1)))
      (Radd_neg c)
  refine Req_trans (Radd_congr (Req_refl _) (Rlim_zero _ _ hz)) ?_
  exact Req_trans (Radd_zero _) (riemannSum_const c (2 ^ 0 - 1))

/-- **`∫₀¹ c = c`, general in the Lipschitz datum** — the constant integral is `c` for *any* valid
    `(L, hlip, hfc)` (the value depends only on `c`). Needed when the integrand is constant but its
    modulus is fixed by an outer construction (e.g. the affine pullback's `L·w`). -/
theorem riemannIntegral_const_gen (c : Real) {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub c c)) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req c c) :
    Req (riemannIntegral (f := fun _ => c) hLd hLn hlip hfc) c := by
  have hz : ∀ j, Req (genSum (dyadicTerm (fun _ => c)) (digammaMidx L j)) zero := by
    intro j
    refine Req_trans (genSum_telescope (fun _ => c) (digammaMidx L j)) ?_
    exact Req_trans
      (Rsub_congr (riemannSum_const c (2 ^ digammaMidx L j - 1)) (riemannSum_const c (2 ^ 0 - 1)))
      (Radd_neg c)
  refine Req_trans (Radd_congr (Req_refl _) (Rlim_zero _ _ hz)) ?_
  exact Req_trans (Radd_zero _) (riemannSum_const c (2 ^ 0 - 1))

-- ===========================================================================
-- Integral as the genuine limit of the dyadic Riemann sums, and positivity.
-- ===========================================================================

/-- Adding a fixed constant preserves regularity (`Radd` reindexes both terms identically, so the
    constant cancels in every pairwise difference). -/
theorem RReg_add_const (c : Real) (X : Nat → Real) (hX : RReg X) :
    RReg (fun j => Radd c (X j)) := by
  intro j k n
  show Qle (Qabs (Qsub (add (c.seq (2 * n + 1)) ((X j).seq (2 * n + 1)))
                       (add (c.seq (2 * n + 1)) ((X k).seq (2 * n + 1)))))
        (add (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) (⟨2, n + 1⟩ : Q))
  have hcancel : Qeq (Qsub (add (c.seq (2 * n + 1)) ((X j).seq (2 * n + 1)))
                          (add (c.seq (2 * n + 1)) ((X k).seq (2 * n + 1))))
                    (Qsub ((X j).seq (2 * n + 1)) ((X k).seq (2 * n + 1))) := by
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  refine Qle_congr_left (Qabs_den_pos (Qsub_den_pos ((X j).den_pos _) ((X k).den_pos _)))
    (Qabs_Qeq (Qeq_symm hcancel)) ?_
  refine Qle_trans (add_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
      (Nat.succ_pos (2 * n + 1))) (hX j k (2 * n + 1)) ?_
  refine Qadd_le_add (Qle_refl _) ?_
  show (2 : Int) * ((n + 1 : Nat) : Int) ≤ (2 : Int) * (((2 * n + 1) + 1 : Nat) : Int)
  push_cast; omega

/-- Adding a fixed constant commutes with convergence: `X k → L ⟹ c + X k → c + L`. -/
theorem RTendsTo_add_const (c : Real) (X : Nat → Real) (L : Real) (h : RTendsTo X L) :
    RTendsTo (fun j => Radd c (X j)) (Radd c L) := by
  intro k n
  show Qle (Qabs (Qsub (add (c.seq (2 * n + 1)) ((X k).seq (2 * n + 1)))
                       (add (c.seq (2 * n + 1)) (L.seq (2 * n + 1)))))
        (add (⟨2, k + 1⟩ : Q) (⟨2, n + 1⟩ : Q))
  have hcancel : Qeq (Qsub (add (c.seq (2 * n + 1)) ((X k).seq (2 * n + 1)))
                          (add (c.seq (2 * n + 1)) (L.seq (2 * n + 1))))
                    (Qsub ((X k).seq (2 * n + 1)) (L.seq (2 * n + 1))) := by
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  refine Qle_congr_left (Qabs_den_pos (Qsub_den_pos ((X k).den_pos _) (L.den_pos _)))
    (Qabs_Qeq (Qeq_symm hcancel)) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos k) (Nat.succ_pos (2 * n + 1)))
    (h k (2 * n + 1)) ?_
  refine Qadd_le_add (Qle_refl _) ?_
  show (2 : Int) * ((n + 1 : Nat) : Int) ≤ (2 : Int) * (((2 * n + 1) + 1 : Nat) : Int)
  push_cast; omega

/-- **`Rlim` commutes with adding a constant**: `lim (c + X) ≈ c + lim X` (by limit uniqueness). -/
theorem Rlim_add_const (c : Real) (X : Nat → Real) (hX : RReg X)
    (hcX : RReg (fun j => Radd c (X j))) :
    Req (Rlim (fun j => Radd c (X j)) hcX) (Radd c (Rlim X hX)) :=
  RTendsTo_unique (Rlim_tendsTo (fun j => Radd c (X j)) hcX)
    (RTendsTo_add_const c X (Rlim X hX) (Rlim_tendsTo X hX))

/-- Non-negativity passes to a Bishop limit (`∀k, X k ≥ 0 ⟹ lim X ≥ 0`). -/
theorem Rnonneg_Rlim_seq {X : Nat → Real} (h : RReg X) (hX : ∀ k, Rnonneg (X k)) :
    Rnonneg (Rlim X h) := by
  intro n
  have hab : Qle (neg (Qbound n)) (neg (Qbound (4 * n + 3))) := by
    simp only [Qle, neg, Qbound]; push_cast; omega
  rw [Rlim_seq]
  exact Qle_trans (by show 0 < 4 * n + 3 + 1; omega) hab (hX (4 * n + 3) (4 * n + 3))

/-- `c + (a − c) ≈ a` (the additive cancellation used to recover `D_M` from `D_0 + ΣΔ`). -/
theorem Radd_Rsub_cancel (a c : Real) : Req (Radd c (Rsub a c)) a :=
  Req_trans (Radd_congr (Req_refl c) (Radd_comm a (Rneg c)))
    (Req_trans (Req_symm (Radd_assoc c (Rneg c) a))
      (Req_trans (Radd_congr (Radd_neg c) (Req_refl a))
        (Req_trans (Radd_comm zero a) (Radd_zero a))))

/-- The dyadic Riemann sum recovered from the anchor plus telescoped increments:
    `D_M ≈ D_0 + Σ_{k<M}(D_{k+1} − D_k)`. -/
theorem dyadicR_eq (f : Real → Real) (M : Nat) :
    Req (dyadicR f M) (Radd (dyadicR f 0) (genSum (dyadicTerm f) M)) :=
  Req_symm (Req_trans (Radd_congr (Req_refl _) (genSum_telescope f M))
    (Radd_Rsub_cancel (dyadicR f M) (dyadicR f 0)))

/-- **`∫₀¹ f ≥ 0` for `f ≥ 0`** — the certified integral of a non-negative integrand is
    non-negative. The integral is the limit of the dyadic sums `D_{m} ≈ D_0 + ΣΔ`, each `≥ 0`
    (`riemannSum_nonneg`), so the limit is `≥ 0` (`Rnonneg_Rlim`). -/
theorem riemannIntegral_nonneg {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hfnn : ∀ x, Rnonneg (f x)) :
    Rnonneg (riemannIntegral hLd hLn hlip hfc) := by
  have hZReg : RReg (fun j => Radd (dyadicR f 0) (genSum (dyadicTerm f) (digammaMidx L j))) :=
    RReg_add_const (dyadicR f 0) _ (dyadicSum_RReg hLd hLn hlip hfc)
  have hZnn : ∀ j, Rnonneg (Radd (dyadicR f 0) (genSum (dyadicTerm f) (digammaMidx L j))) := fun j =>
    Rnonneg_congr (dyadicR_eq f (digammaMidx L j))
      (riemannSum_nonneg (2 ^ digammaMidx L j - 1) (fun i _ => hfnn _))
  have hEq : Req (Rlim (fun j => Radd (dyadicR f 0) (genSum (dyadicTerm f) (digammaMidx L j))) hZReg)
      (riemannIntegral hLd hLn hlip hfc) :=
    Rlim_add_const (dyadicR f 0) _ (dyadicSum_RReg hLd hLn hlip hfc) hZReg
  exact Rnonneg_congr hEq (Rnonneg_Rlim_seq hZReg hZnn)

/-- Monotonicity passes to a Bishop limit (`∀k, X k ≤ Y k ⟹ lim X ≤ lim Y`). -/
theorem Rlim_le_seq {X Y : Nat → Real} (hX : RReg X) (hY : RReg Y) (h : ∀ k, Rle (X k) (Y k)) :
    Rle (Rlim X hX) (Rlim Y hY) := by
  intro n
  rw [Rlim_seq, Rlim_seq]
  refine Qle_trans
    (add_den_pos ((Y (4 * n + 3)).den_pos (4 * n + 3)) (by show 0 < 4 * n + 3 + 1; omega))
    (h (4 * n + 3) (4 * n + 3)) (Qadd_le_add (Qle_refl _) ?_)
  simp only [Qle]; push_cast; omega

/-- **`∫₀¹ f ≤ ∫₀¹ g` for `f ≤ g`** (with a shared Lipschitz modulus `L`, so both integrals sample
    the same dyadic schedule). Monotonicity of the certified integral: each dyadic sum is monotone
    (`riemannSum_le`), so the limits compare (`Rlim_le_seq`). -/
theorem riemannIntegral_le {f g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y)) (hfg : ∀ x, Rle (f x) (g x)) :
    Rle (riemannIntegral hLd hLn hlipf hfcf) (riemannIntegral hLd hLn hlipg hfcg) := by
  have hZfReg : RReg (fun j => Radd (dyadicR f 0) (genSum (dyadicTerm f) (digammaMidx L j))) :=
    RReg_add_const (dyadicR f 0) _ (dyadicSum_RReg hLd hLn hlipf hfcf)
  have hZgReg : RReg (fun j => Radd (dyadicR g 0) (genSum (dyadicTerm g) (digammaMidx L j))) :=
    RReg_add_const (dyadicR g 0) _ (dyadicSum_RReg hLd hLn hlipg hfcg)
  have hZle : ∀ j, Rle (Radd (dyadicR f 0) (genSum (dyadicTerm f) (digammaMidx L j)))
      (Radd (dyadicR g 0) (genSum (dyadicTerm g) (digammaMidx L j))) := fun j =>
    Rle_trans (Rle_of_Req (Req_symm (dyadicR_eq f (digammaMidx L j))))
      (Rle_trans (riemannSum_le (2 ^ digammaMidx L j - 1) (fun i _ => hfg _))
        (Rle_of_Req (dyadicR_eq g (digammaMidx L j))))
  refine Rle_trans (Rle_of_Req (Req_symm
      (Rlim_add_const (dyadicR f 0) _ (dyadicSum_RReg hLd hLn hlipf hfcf) hZfReg))) ?_
  exact Rle_trans (Rlim_le_seq hZfReg hZgReg hZle)
    (Rle_of_Req (Rlim_add_const (dyadicR g 0) _ (dyadicSum_RReg hLd hLn hlipg hfcg) hZgReg))

/-- **`genSum` distributes over a termwise sum**: if `Tₖ ≈ Tfₖ + Tgₖ` then
    `Σ_{k<M} Tₖ ≈ Σ_{k<M} Tfₖ + Σ_{k<M} Tgₖ`. `genSum_congr` + finite-additivity combined, by
    induction over the `Radd` middle-four swap. -/
theorem genSum_Radd_of_termwise {T Tf Tg : Nat → Real} (h : ∀ k, Req (T k) (Radd (Tf k) (Tg k))) :
    ∀ M, Req (genSum T M) (Radd (genSum Tf M) (genSum Tg M))
  | 0 => Req_symm (Radd_zero zero)
  | (M + 1) =>
      Req_trans (Radd_congr (genSum_Radd_of_termwise h M) (h M))
        (Radd_swap (genSum Tf M) (genSum Tg M) (Tf M) (Tg M))

/-- **The certified Riemann integral is additive in the integrand** `∫₀¹ (f+g) = ∫₀¹ f + ∫₀¹ g` —
    linearity (additive part) of the Bishop-limit integral, and the first genuine consumer of
    `Rlim_add_of_approx`. The three integrals are taken at a SHARED Lipschitz constant `L` (so they use
    the same dyadic reindex `digammaMidx L`, aligning the limits); the caller supplies `L ≥ L_f + L_g`
    with all three Lipschitz proofs at `L`.

    The dyadic sums add at every finite level — `riemannSum_add` ⟹ `dyadicR` additive ⟹ `dyadicTerm`
    additive (`Rsub_Radd_Radd`) ⟹ `genSum` additive (`genSum_Radd_of_termwise`) — so the integral
    sequences `Zₕ j = D₀(h) + Σ(dyadicTerm h)` satisfy `Z_{f+g} ≈ Z_f + Z_g` pointwise. The
    convergence of `Z_{f+g}` is GIVEN (its own `dyadicSum_RReg`), so `Rlim_add_of_approx` combines the
    limits without a (non-derivable) combined regularity. -/
theorem riemannIntegral_add {f g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y))
    (hlipfg : ∀ x y, Rle (Rabs (Rsub (Radd (f x) (g x)) (Radd (f y) (g y))))
        (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcfg : ∀ x y, Req x y → Req (Radd (f x) (g x)) (Radd (f y) (g y))) :
    Req (riemannIntegral hLd hLn hlipfg hfcfg)
        (Radd (riemannIntegral hLd hLn hlipf hfcf) (riemannIntegral hLd hLn hlipg hfcg)) := by
  -- dyadic sums add at every finite level
  have hdR : ∀ m, Req (dyadicR (fun x => Radd (f x) (g x)) m)
      (Radd (dyadicR f m) (dyadicR g m)) := fun m => riemannSum_add f g (2 ^ m - 1)
  have hdT : ∀ k, Req (dyadicTerm (fun x => Radd (f x) (g x)) k)
      (Radd (dyadicTerm f k) (dyadicTerm g k)) := fun k =>
    Req_trans (Rsub_congr (hdR (k + 1)) (hdR k))
      (Rsub_Radd_Radd (dyadicR f (k + 1)) (dyadicR g (k + 1)) (dyadicR f k) (dyadicR g k))
  have hgS : ∀ j, Req (genSum (dyadicTerm (fun x => Radd (f x) (g x))) (digammaMidx L j))
      (Radd (genSum (dyadicTerm f) (digammaMidx L j)) (genSum (dyadicTerm g) (digammaMidx L j))) :=
    fun j => genSum_Radd_of_termwise hdT (digammaMidx L j)
  -- the three integral sequences `Zₕ` are regular (`D₀ + Σ`)
  have hZfReg : RReg (fun j => Radd (dyadicR f 0) (genSum (dyadicTerm f) (digammaMidx L j))) :=
    RReg_add_const (dyadicR f 0) _ (dyadicSum_RReg hLd hLn hlipf hfcf)
  have hZgReg : RReg (fun j => Radd (dyadicR g 0) (genSum (dyadicTerm g) (digammaMidx L j))) :=
    RReg_add_const (dyadicR g 0) _ (dyadicSum_RReg hLd hLn hlipg hfcg)
  have hZfgReg : RReg (fun j => Radd (dyadicR (fun x => Radd (f x) (g x)) 0)
      (genSum (dyadicTerm (fun x => Radd (f x) (g x))) (digammaMidx L j))) :=
    RReg_add_const _ _ (dyadicSum_RReg hLd hLn hlipfg hfcfg)
  -- `Z_{f+g} ≈ Z_f + Z_g` pointwise
  have happZ : ∀ j, Req (Radd (dyadicR (fun x => Radd (f x) (g x)) 0)
        (genSum (dyadicTerm (fun x => Radd (f x) (g x))) (digammaMidx L j)))
      (Radd (Radd (dyadicR f 0) (genSum (dyadicTerm f) (digammaMidx L j)))
            (Radd (dyadicR g 0) (genSum (dyadicTerm g) (digammaMidx L j)))) := fun j =>
    Req_trans (Radd_congr (hdR 0) (hgS j))
      (Radd_swap (dyadicR f 0) (dyadicR g 0)
        (genSum (dyadicTerm f) (digammaMidx L j)) (genSum (dyadicTerm g) (digammaMidx L j)))
  -- assemble: ∫(f+g) ≈ lim Z_{f+g} ≈ lim Z_f + lim Z_g ≈ ∫f + ∫g
  refine Req_trans (Req_symm (Rlim_add_const _ _ (dyadicSum_RReg hLd hLn hlipfg hfcfg) hZfgReg)) ?_
  refine Req_trans (Rlim_add_of_approx _ _ _ hZfReg hZgReg hZfgReg happZ) ?_
  exact Radd_congr
    (Rlim_add_const (dyadicR f 0) _ (dyadicSum_RReg hLd hLn hlipf hfcf) hZfReg)
    (Rlim_add_const (dyadicR g 0) _ (dyadicSum_RReg hLd hLn hlipg hfcg) hZgReg)

/-- **`∫₀¹ f ≈ ∫₀¹ g` for `f ≈ g` pointwise** (shared `L`) — the certified integral respects `≈` of the
    integrand, by antisymmetry of `riemannIntegral_le` (the base-integral companion of
    `improperIntegral1_congr`/`halfLineIntegral_congr`). -/
theorem riemannIntegral_congr {f g : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y)) (hfg : ∀ x, Req (f x) (g x)) :
    Req (riemannIntegral hLd hLn hlipf hfcf) (riemannIntegral hLd hLn hlipg hfcg) :=
  Rle_antisymm
    (riemannIntegral_le hLd hLn hlipf hfcf hlipg hfcg (fun x => Rle_of_Req (hfg x)))
    (riemannIntegral_le hLd hLn hlipg hfcg hlipf hfcf (fun x => Rle_of_Req (Req_symm (hfg x))))

/-- `(−x) − (−y) ≈ −(x − y)` (local copy; the general lemma lives in a higher file). -/
private theorem Rsub_Rneg_Rneg_loc (x y : Real) : Req (Rsub (Rneg x) (Rneg y)) (Rneg (Rsub x y)) := by
  apply Req_of_seq_Qeq; intro n; simp only [Qeq, Rsub, Radd, Rneg, neg, add]; push_cast; ring_uor

/-- Regularity is preserved under pointwise negation (modulus-safe; local copy). -/
theorem RReg_Rneg (X : Nat → Real) (h : RReg X) : RReg (fun j => Rneg (X j)) := by
  intro j k n
  have he : Qeq (Qsub ((X k).seq n) ((X j).seq n))
      (Qsub ((Rneg (X j)).seq n) ((Rneg (X k)).seq n)) := by
    show Qeq (Qsub ((X k).seq n) ((X j).seq n)) (Qsub (neg ((X j).seq n)) (neg ((X k).seq n)))
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  refine Qle_congr_left (Qabs_den_pos (Qsub_den_pos ((X k).den_pos n) ((X j).den_pos n)))
    (Qabs_Qeq he) ?_
  rw [Qabs_Qsub_comm]
  exact h j k n

/-- **`genSum` respects a termwise negation**: if `Tₖ ≈ −Uₖ` then `Σ_{k<M} Tₖ ≈ −Σ_{k<M} Uₖ`. -/
theorem genSum_Rneg_of_termwise {T U : Nat → Real} (h : ∀ k, Req (T k) (Rneg (U k))) :
    ∀ M, Req (genSum T M) (Rneg (genSum U M))
  | 0 => Req_of_seq_Qeq (fun _ => Qeq_refl _)
  | (M + 1) =>
      Req_trans (Radd_congr (genSum_Rneg_of_termwise h M) (h M))
        (Req_symm (Rneg_Radd (genSum U M) (U M)))

/-- **The certified integral respects negation** `∫₀¹ (−f) = −∫₀¹ f` — the `−1`-scalar case of
    linearity (with `riemannIntegral_add`, the additive-group structure: `∫(f−g) = ∫f − ∫g`). The
    dyadic sums negate at every finite level (`riemannSum_neg` ⟹ `dyadicR` ⟹ `dyadicTerm` via
    `Rsub_Rneg_Rneg` ⟹ `genSum` via `genSum_Rneg_of_termwise`), and `Rlim_neg` (with `RReg_neg`)
    carries it through the limit. -/
theorem riemannIntegral_neg {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipnf : ∀ x y, Rle (Rabs (Rsub (Rneg (f x)) (Rneg (f y)))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcnf : ∀ x y, Req x y → Req (Rneg (f x)) (Rneg (f y))) :
    Req (riemannIntegral hLd hLn hlipnf hfcnf) (Rneg (riemannIntegral hLd hLn hlipf hfcf)) := by
  have hdR : ∀ m, Req (dyadicR (fun x => Rneg (f x)) m) (Rneg (dyadicR f m)) :=
    fun m => riemannSum_neg f (2 ^ m - 1)
  have hdT : ∀ k, Req (dyadicTerm (fun x => Rneg (f x)) k) (Rneg (dyadicTerm f k)) := fun k =>
    Req_trans (Rsub_congr (hdR (k + 1)) (hdR k))
      (Rsub_Rneg_Rneg_loc (dyadicR f (k + 1)) (dyadicR f k))
  have hgS : ∀ j, Req (genSum (dyadicTerm (fun x => Rneg (f x))) (digammaMidx L j))
      (Rneg (genSum (dyadicTerm f) (digammaMidx L j))) := fun j =>
    genSum_Rneg_of_termwise hdT (digammaMidx L j)
  have hSf := dyadicSum_RReg hLd hLn hlipf hfcf
  have hNegSf := RReg_Rneg _ hSf
  refine Req_trans (Radd_congr (hdR 0)
    (Req_trans (Rlim_congr _ _ (dyadicSum_RReg hLd hLn hlipnf hfcnf) hNegSf hgS)
      (Rlim_neg _ hSf hNegSf))) ?_
  exact Req_symm (Rneg_Radd (dyadicR f 0)
    (Rlim (fun j => genSum (dyadicTerm f) (digammaMidx L j)) hSf))

/-- **`genSum` respects a termwise constant scalar**: if `Tₖ ≈ c·Uₖ` then `Σ Tₖ ≈ c·Σ Uₖ`. -/
theorem genSum_Rmul_of_termwise {c : Real} {T U : Nat → Real} (h : ∀ k, Req (T k) (Rmul c (U k))) :
    ∀ M, Req (genSum T M) (Rmul c (genSum U M))
  | 0 => Req_symm (Rmul_zero c)
  | (M + 1) =>
      Req_trans (Radd_congr (genSum_Rmul_of_termwise h M) (h M))
        (Req_symm (Rmul_distrib c (genSum U M) (U M)))

/-- `c·(a − b) ≈ c·a − c·b` (left scalar distributes over subtraction; local). -/
private theorem Rmul_Rsub_distrib_loc (c a b : Real) :
    Req (Rmul c (Rsub a b)) (Rsub (Rmul c a) (Rmul c b)) :=
  Req_trans (Rmul_distrib c a (Rneg b)) (Radd_congr (Req_refl _) (Rmul_neg_right c b))

/-- **The certified integral respects a constant scalar** `∫₀¹ (q·f) = q·∫₀¹ f` for `q : ℚ` — the
    scalar half of integral linearity (with `riemannIntegral_add`/`_neg`, the full linear-functional
    structure). The three pieces share the Lipschitz constant `L` (caller picks `L ≥ |q|·L_f`, so
    `q·f` is `L`-Lipschitz). Dyadic sums scale at every finite level (`riemannSum_smul` ⟹ `dyadicR` ⟹
    `dyadicTerm` via `Rmul_Rsub_distrib_loc` ⟹ `genSum` via `genSum_Rmul_of_termwise`), and the hard
    `Rlim_ofQ_mul_of_approx` carries the scalar through the limit. -/
theorem riemannIntegral_smul {f : Real → Real} {L : Q} (q : Q) (hq : 0 < q.den)
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hlipqf : ∀ x y, Rle (Rabs (Rsub (Rmul (ofQ q hq) (f x)) (Rmul (ofQ q hq) (f y))))
        (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcqf : ∀ x y, Req x y → Req (Rmul (ofQ q hq) (f x)) (Rmul (ofQ q hq) (f y))) :
    Req (riemannIntegral hLd hLn hlipqf hfcqf)
        (Rmul (ofQ q hq) (riemannIntegral hLd hLn hlipf hfcf)) := by
  have hdR : ∀ m, Req (dyadicR (fun x => Rmul (ofQ q hq) (f x)) m)
      (Rmul (ofQ q hq) (dyadicR f m)) := fun m => riemannSum_smul (ofQ q hq) f (2 ^ m - 1)
  have hdT : ∀ k, Req (dyadicTerm (fun x => Rmul (ofQ q hq) (f x)) k)
      (Rmul (ofQ q hq) (dyadicTerm f k)) := fun k =>
    Req_trans (Rsub_congr (hdR (k + 1)) (hdR k))
      (Req_symm (Rmul_Rsub_distrib_loc (ofQ q hq) (dyadicR f (k + 1)) (dyadicR f k)))
  have hgS : ∀ j, Req (genSum (dyadicTerm (fun x => Rmul (ofQ q hq) (f x))) (digammaMidx L j))
      (Rmul (ofQ q hq) (genSum (dyadicTerm f) (digammaMidx L j))) := fun j =>
    genSum_Rmul_of_termwise hdT (digammaMidx L j)
  have hSf := dyadicSum_RReg hLd hLn hlipf hfcf
  refine Req_trans (Radd_congr (hdR 0)
    (Rlim_ofQ_mul_of_approx q hq _ _ hSf (dyadicSum_RReg hLd hLn hlipqf hfcqf) hgS)) ?_
  exact Req_symm (Rmul_distrib (ofQ q hq) (dyadicR f 0)
    (Rlim (fun j => genSum (dyadicTerm f) (digammaMidx L j)) hSf))

end UOR.Bridge.F1Square.Analysis
