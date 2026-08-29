/-
F1 square — the complex Riemann zeta function `ζ(s) = Σ_{n≥1} n⁻ˢ` for `Re s > 1`, built on the
dyadic-geometric tail. The per-term modulus `|n⁻ˢ| = exp(−Re s · log n)` decays geometrically across
dyadic blocks `B_k = [2ᵏ, 2ᵏ⁺¹)`, giving a rational regularity modulus for each (real, imaginary)
component — the honest route for *real* `σ = Re s > 1` (the integer-`s` telescoping of `Zeta.lean`
fails for `1 < σ < 2`). This brick: the per-term component bounds `−exp(Re z) ≤ Re/Im(eᶻ) ≤ exp(Re z)`.
-/
import Foundations.F1.Analysis.RealPow
import Foundations.F1.Analysis.ComplexPow

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- `Re(eᶻ) ≤ exp(Re z)` (`Re(eᶻ) = exp(Re z)·cos(Im z)` and `cos ≤ 1`, `exp ≥ 0`). -/
theorem Cexp_re_le (z : Complex) : Rle ((Cexp z).re) (RexpReal z.re) :=
  Rle_trans (Rmul_le_Rmul_left (RexpReal_nonneg z.re) (Rcos_le_one z.im))
    (Rle_of_Req (Rmul_one (RexpReal z.re)))

/-- `−exp(Re z) ≤ Re(eᶻ)` (`cos ≥ −1`). -/
theorem Cexp_re_ge (z : Complex) : Rle (Rneg (RexpReal z.re)) ((Cexp z).re) :=
  Rle_trans (Rle_of_Req (Req_symm (Req_trans (Rmul_neg_right (RexpReal z.re) one)
      (Rneg_congr (Rmul_one (RexpReal z.re))))))
    (Rmul_le_Rmul_left (RexpReal_nonneg z.re) (Rneg_one_le_Rcos z.im))

/-- `Im(eᶻ) ≤ exp(Re z)` (`Im(eᶻ) = exp(Re z)·sin(Im z)` and `sin ≤ 1`). -/
theorem Cexp_im_le (z : Complex) : Rle ((Cexp z).im) (RexpReal z.re) :=
  Rle_trans (Rmul_le_Rmul_left (RexpReal_nonneg z.re) (Rsin_le_one z.im))
    (Rle_of_Req (Rmul_one (RexpReal z.re)))

/-- `−exp(Re z) ≤ Im(eᶻ)` (`sin ≥ −1`). -/
theorem Cexp_im_ge (z : Complex) : Rle (Rneg (RexpReal z.re)) ((Cexp z).im) :=
  Rle_trans (Rle_of_Req (Req_symm (Req_trans (Rmul_neg_right (RexpReal z.re) one)
      (Rneg_congr (Rmul_one (RexpReal z.re))))))
    (Rmul_le_Rmul_left (RexpReal_nonneg z.re) (Rneg_one_le_Rsin z.im))

/-- **The `n`-th term `n⁻ˢ = exp(−s·log n)`** of `ζ(s)`, for `n ≥ 1` (`log 1 = 0`, so `1⁻ˢ = e⁰ = 1`).
    Built on `logN` (the natural-log of `ComplexZeta`/`RealPow`) so the dyadic bounds apply directly. -/
def czetaTerm (s : Complex) (n : Nat) (hn : 1 ≤ n) : Complex :=
  Cexp ⟨Rmul (Rneg s.re) (logN n hn), Rmul (Rneg s.im) (logN n hn)⟩

/-- The term's modulus exponent `−Re s · log n` (`= Re` of the `Cexp` argument). -/
def czetaExpArg (s : Complex) (n : Nat) (hn : 1 ≤ n) : Real := Rmul (Rneg s.re) (logN n hn)

theorem czetaTerm_re_le (s : Complex) (n : Nat) (hn : 1 ≤ n) :
    Rle ((czetaTerm s n hn).re) (RexpReal (czetaExpArg s n hn)) := Cexp_re_le _

theorem czetaTerm_re_ge (s : Complex) (n : Nat) (hn : 1 ≤ n) :
    Rle (Rneg (RexpReal (czetaExpArg s n hn))) ((czetaTerm s n hn).re) := Cexp_re_ge _

theorem czetaTerm_im_le (s : Complex) (n : Nat) (hn : 1 ≤ n) :
    Rle ((czetaTerm s n hn).im) (RexpReal (czetaExpArg s n hn)) := Cexp_im_le _

theorem czetaTerm_im_ge (s : Complex) (n : Nat) (hn : 1 ≤ n) :
    Rle (Rneg (RexpReal (czetaExpArg s n hn))) ((czetaTerm s n hn).im) := Cexp_im_ge _

/-- The real partial sum `Σ_{n=1}^N Re(n⁻ˢ)`. -/
def czetaReSum (s : Complex) : Nat → Real
  | 0 => zero
  | (n + 1) => Radd (czetaReSum s n) ((czetaTerm s (n + 1) (by omega)).re)

/-- The imaginary partial sum `Σ_{n=1}^N Im(n⁻ˢ)`. -/
def czetaImSum (s : Complex) : Nat → Real
  | 0 => zero
  | (n + 1) => Radd (czetaImSum s n) ((czetaTerm s (n + 1) (by omega)).im)

/-- The modulus partial sum `Σ_{n=1}^N exp(−Re s · log n)` (dominates both components' increments). -/
def czetaExpSum (s : Complex) : Nat → Real
  | 0 => zero
  | (n + 1) => Radd (czetaExpSum s n) (RexpReal (czetaExpArg s (n + 1) (by omega)))

/-- `(a+t) − b ≈ (a−b) + t`. -/
theorem Rsub_Radd_left (a t b : Real) : Req (Rsub (Radd a t) b) (Radd (Rsub a b) t) :=
  Req_trans (Radd_assoc a t (Rneg b))
    (Req_trans (Radd_congr (Req_refl a) (Radd_comm t (Rneg b)))
      (Req_symm (Radd_assoc a (Rneg b) t)))

/-- `−0 ≈ 0`. -/
theorem Rneg_zero : Req (Rneg zero) zero :=
  Req_of_seq_Qeq (fun _ => by show Qeq (neg (⟨0, 1⟩ : Q)) ⟨0, 1⟩; decide)

/-- **Upper tail bound (real part)**, `d`-form: `S_re(N+d) − S_re(N) ≤ E(N+d) − E(N)`. -/
theorem czeta_re_diff_le_aux (s : Complex) (N : Nat) : ∀ d,
    Rle (Rsub (czetaReSum s (N + d)) (czetaReSum s N))
        (Rsub (czetaExpSum s (N + d)) (czetaExpSum s N))
  | 0 => Rle_of_Req (Req_trans (Radd_neg _) (Req_symm (Radd_neg _)))
  | (d + 1) =>
      Rle_trans (Rle_of_Req (Rsub_Radd_left (czetaReSum s (N + d)) _ (czetaReSum s N)))
        (Rle_trans (Radd_le_add (czeta_re_diff_le_aux s N d) (czetaTerm_re_le s (N + d + 1) (by omega)))
          (Rle_of_Req (Req_symm (Rsub_Radd_left (czetaExpSum s (N + d)) _ (czetaExpSum s N)))))

/-- **Upper tail bound (real part)**: for `N ≤ M`, `S_re(M) − S_re(N) ≤ E(M) − E(N)`. -/
theorem czeta_re_diff_le (s : Complex) {N M : Nat} (hNM : N ≤ M) :
    Rle (Rsub (czetaReSum s M) (czetaReSum s N)) (Rsub (czetaExpSum s M) (czetaExpSum s N)) := by
  obtain ⟨d, rfl⟩ := Nat.le.dest hNM; exact czeta_re_diff_le_aux s N d

/-- **Lower tail bound (real part)**, `d`-form: `−(E(N+d) − E(N)) ≤ S_re(N+d) − S_re(N)`. -/
theorem czeta_re_diff_ge_aux (s : Complex) (N : Nat) : ∀ d,
    Rle (Rneg (Rsub (czetaExpSum s (N + d)) (czetaExpSum s N)))
        (Rsub (czetaReSum s (N + d)) (czetaReSum s N))
  | 0 => Rle_of_Req (Req_trans (Rneg_congr (Radd_neg _)) (Req_trans Rneg_zero (Req_symm (Radd_neg _))))
  | (d + 1) =>
      Rle_trans (Rle_of_Req (Req_trans
          (Rneg_congr (Rsub_Radd_left (czetaExpSum s (N + d)) _ (czetaExpSum s N)))
          (Rneg_Radd (Rsub (czetaExpSum s (N + d)) (czetaExpSum s N)) _)))
        (Rle_trans (Radd_le_add (czeta_re_diff_ge_aux s N d) (czetaTerm_re_ge s (N + d + 1) (by omega)))
          (Rle_of_Req (Req_symm (Rsub_Radd_left (czetaReSum s (N + d)) _ (czetaReSum s N)))))

/-- **Lower tail bound (real part)**: for `N ≤ M`, `−(E(M) − E(N)) ≤ S_re(M) − S_re(N)`. -/
theorem czeta_re_diff_ge (s : Complex) {N M : Nat} (hNM : N ≤ M) :
    Rle (Rneg (Rsub (czetaExpSum s M) (czetaExpSum s N))) (Rsub (czetaReSum s M) (czetaReSum s N)) := by
  obtain ⟨d, rfl⟩ := Nat.le.dest hNM; exact czeta_re_diff_ge_aux s N d

/-- **Upper tail bound (imaginary part)**, `d`-form. -/
theorem czeta_im_diff_le_aux (s : Complex) (N : Nat) : ∀ d,
    Rle (Rsub (czetaImSum s (N + d)) (czetaImSum s N))
        (Rsub (czetaExpSum s (N + d)) (czetaExpSum s N))
  | 0 => Rle_of_Req (Req_trans (Radd_neg _) (Req_symm (Radd_neg _)))
  | (d + 1) =>
      Rle_trans (Rle_of_Req (Rsub_Radd_left (czetaImSum s (N + d)) _ (czetaImSum s N)))
        (Rle_trans (Radd_le_add (czeta_im_diff_le_aux s N d) (czetaTerm_im_le s (N + d + 1) (by omega)))
          (Rle_of_Req (Req_symm (Rsub_Radd_left (czetaExpSum s (N + d)) _ (czetaExpSum s N)))))

theorem czeta_im_diff_le (s : Complex) {N M : Nat} (hNM : N ≤ M) :
    Rle (Rsub (czetaImSum s M) (czetaImSum s N)) (Rsub (czetaExpSum s M) (czetaExpSum s N)) := by
  obtain ⟨d, rfl⟩ := Nat.le.dest hNM; exact czeta_im_diff_le_aux s N d

/-- **Lower tail bound (imaginary part)**, `d`-form. -/
theorem czeta_im_diff_ge_aux (s : Complex) (N : Nat) : ∀ d,
    Rle (Rneg (Rsub (czetaExpSum s (N + d)) (czetaExpSum s N)))
        (Rsub (czetaImSum s (N + d)) (czetaImSum s N))
  | 0 => Rle_of_Req (Req_trans (Rneg_congr (Radd_neg _)) (Req_trans Rneg_zero (Req_symm (Radd_neg _))))
  | (d + 1) =>
      Rle_trans (Rle_of_Req (Req_trans
          (Rneg_congr (Rsub_Radd_left (czetaExpSum s (N + d)) _ (czetaExpSum s N)))
          (Rneg_Radd (Rsub (czetaExpSum s (N + d)) (czetaExpSum s N)) _)))
        (Rle_trans (Radd_le_add (czeta_im_diff_ge_aux s N d) (czetaTerm_im_ge s (N + d + 1) (by omega)))
          (Rle_of_Req (Req_symm (Rsub_Radd_left (czetaImSum s (N + d)) _ (czetaImSum s N)))))

theorem czeta_im_diff_ge (s : Complex) {N M : Nat} (hNM : N ≤ M) :
    Rle (Rneg (Rsub (czetaExpSum s M) (czetaExpSum s N))) (Rsub (czetaImSum s M) (czetaImSum s N)) := by
  obtain ⟨d, rfl⟩ := Nat.le.dest hNM; exact czeta_im_diff_ge_aux s N d

/-- **Block-sum bound**: if each of the `d` modulus terms over `(N, N+d]` is `≤ B`, then
    `E(N+d) − E(N) ≤ d·B` (the dyadic block's `2ᵏ` terms each `≤ exp(−σ·k·log 2)`). -/
theorem czetaExp_block_le (s : Complex) (N : Nat) (B : Real) : ∀ d,
    (∀ i, i < d → Rle (RexpReal (czetaExpArg s (N + i + 1) (by omega))) B) →
    Rle (Rsub (czetaExpSum s (N + d)) (czetaExpSum s N)) (Rnsmul d B)
  | 0 => fun _ => Rle_of_Req (Radd_neg _)
  | (d + 1) => fun h =>
      Rle_trans (Rle_of_Req (Rsub_Radd_left (czetaExpSum s (N + d)) _ (czetaExpSum s N)))
        (Rle_trans (Radd_le_add (czetaExp_block_le s N B d (fun i hi => h i (by omega)))
            (h d (by omega)))
          (Rle_of_Req (Radd_comm (Rnsmul d B) B)))

/-- **Per-term block bound**: for `n ≥ 2ᵏ` (and `Re s ≥ 0`), the `n`-th modulus term
    `exp(−Re s · log n) ≤ exp(−Re s · k · log 2)`. The bound `B` feeding `czetaExp_block_le`. -/
theorem czetaExp_term_le (s : Complex) (hσ : Rnonneg s.re) (k n : Nat) (hn : 1 ≤ n) (hkn : 2 ^ k ≤ n) :
    Rle (RexpReal (czetaExpArg s n hn))
        (RexpReal (Rneg (Rmul s.re (Rnsmul k (logN 2 (by omega)))))) :=
  Rle_trans (Rle_of_Req (RexpReal_congr (Rmul_neg_left s.re (logN n hn)))) (exp_block_bound hσ hkn)

/-- **The dyadic block bound**: `E(2ᵏ⁺¹) − E(2ᵏ) ≤ 2ᵏ · exp(−Re s · k · log 2)` (`2ᵏ` terms, each
    `≤ exp(−Re s · k · log 2)`). The `k`-th block of the modulus sum. -/
theorem czetaExp_block (s : Complex) (hσ : Rnonneg s.re) (k : Nat) :
    Rle (Rsub (czetaExpSum s (2 ^ (k + 1))) (czetaExpSum s (2 ^ k)))
        (Rnsmul (2 ^ k) (RexpReal (Rneg (Rmul s.re (Rnsmul k (logN 2 (by omega))))))) := by
  have he : 2 ^ k + 2 ^ k = 2 ^ (k + 1) := by rw [Nat.pow_succ]; omega
  rw [← he]
  exact czetaExp_block_le s (2 ^ k) _ (2 ^ k)
    (fun i _ => czetaExp_term_le s hσ k (2 ^ k + i + 1) (by omega) (by omega))

/-- The single-step modulus ratio `u = exp(−Re s · log 2)` (so `block(k) ≤ (2u)ᵏ`). -/
def czetaU (s : Complex) : Real := RexpReal (Rneg (Rmul s.re (logN 2 (by omega))))

/-- `exp(−Re s · k · log 2) ≈ uᵏ`. -/
theorem czetaExpB_eq_pow (s : Complex) (k : Nat) :
    Req (RexpReal (Rneg (Rmul s.re (Rnsmul k (logN 2 (by omega)))))) (Rpow (czetaU s) k) :=
  Req_trans (RexpReal_congr (Req_trans (Rneg_congr (Rmul_Rnsmul s.re (logN 2 (by omega)) k))
      (Rneg_Rnsmul (Rmul s.re (logN 2 (by omega))) k)))
    (RexpReal_nsmul (Rneg (Rmul s.re (logN 2 (by omega)))) k)

/-- **The dyadic block as a geometric power**: `E(2ᵏ⁺¹) − E(2ᵏ) ≤ (2u)ᵏ`, `u = exp(−Re s · log 2)`. -/
theorem czetaExp_block_pow (s : Complex) (hσ : Rnonneg s.re) (k : Nat) :
    Rle (Rsub (czetaExpSum s (2 ^ (k + 1))) (czetaExpSum s (2 ^ k)))
        (Rpow (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (czetaU s)) k) := by
  refine Rle_trans (czetaExp_block s hσ k) (Rle_of_Req ?_)
  -- Rnsmul(2^k) B ≈ Rmul(ofQ 2^k) B ≈ Rmul(Rpow(ofQ 2) k)(Rpow u k) ≈ Rpow(2u) k
  refine Req_trans (Rnsmul_eq_Rmul_ofQ _ (2 ^ k)) ?_
  refine Req_trans (Rmul_congr ?_ (czetaExpB_eq_pow s k)) (Req_symm (Rpow_mul_dist _ _ k))
  -- ofQ ⟨2^k,1⟩ ≈ Rpow(ofQ 2) k
  exact Req_symm (Req_trans (Rpow_ofQ (by decide) k)
    (ofQ_congr (qpow_den_pos (by decide) k) Nat.one_pos
      (Qeq_trans Nat.one_pos (qpow_two_eq k) (by simp only [Qeq]; push_cast; ring_uor))))

set_option maxHeartbeats 1000000 in
/-- `log2 − Re s · log2 ≈ −(Re s − 1)·log2` (the exponent of `2u = exp(−θ)`). -/
theorem czeta_theta_arg_eq (s : Complex) :
    Req (Radd (logN 2 (by omega)) (Rneg (Rmul s.re (logN 2 (by omega)))))
        (Rneg (Rmul (Rsub s.re one) (logN 2 (by omega)))) := by
  have hL : Req (Radd (logN 2 (by omega)) (Rneg (Rmul s.re (logN 2 (by omega)))))
      (Rmul (Rsub one s.re) (logN 2 (by omega))) :=
    Req_trans (Radd_congr (Req_symm (Rone_mul (logN 2 (by omega))))
        (Req_symm (Rmul_neg_left s.re (logN 2 (by omega)))))
      (Req_symm (Rmul_distrib_right one (Rneg s.re) (logN 2 (by omega))))
  have hR : Req (Rneg (Rmul (Rsub s.re one) (logN 2 (by omega))))
      (Rmul (Rsub one s.re) (logN 2 (by omega))) :=
    Req_trans (Req_symm (Rmul_neg_left (Rsub s.re one) (logN 2 (by omega))))
      (Rmul_congr (Rneg_Rsub s.re one) (Req_refl _))
  exact Req_trans hL (Req_symm hR)

/-- **`2u = exp(−θ)`** where `θ = (Re s − 1)·log 2`: the dyadic ratio as a single exp. -/
theorem czetaU_2u_eq (s : Complex) :
    Req (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (czetaU s))
        (RexpReal (Rneg (Rmul (Rsub s.re one) (logN 2 (by omega))))) :=
  Req_trans (Rmul_congr (Req_symm (Rexp_logN 2 (by omega))) (Req_refl _))
    (Req_trans (Req_symm (RexpReal_add (logN 2 (by omega)) (Rneg (Rmul s.re (logN 2 (by omega))))))
      (RexpReal_congr (czeta_theta_arg_eq s)))

/-- **`2u ≤ 1/(1+τ) < 1`** whenever `θ = (Re s−1)·log2 ≥ ofQ τ` (`τ > 0`): the dyadic ratio bound. -/
theorem czetaU_2u_le_of_theta (s : Complex) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) :
    Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (czetaU s))
        (ofQ (Qinv (add ⟨1, 1⟩ τ)) (Qinv_den_pos (by simp only [add]; push_cast; omega))) :=
  Rle_trans (Rle_of_Req (czetaU_2u_eq s)) (Rexp_neg_le_ratio hτn hτd hθ)

/-- **`θ ≥ ofQ(ε/2)`** from `Re s > 1` (`Pos(s.re−1)`): extracts the positive rational lower bound on the
    dyadic exponent (`σ−1 ≥ ε` via `Pos_imp_ofQ_le`, `log2 ≥ ½`). -/
theorem czeta_theta_ge (s : Complex) (hs : Pos (Rsub s.re one)) :
    ∃ (τ : Q) (hτd : 0 < τ.den), 0 < τ.num ∧
      Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega))) := by
  obtain ⟨ε, hεd, hεn, hε⟩ := Pos_imp_ofQ_le hs
  refine ⟨mul ε ⟨1, 2⟩, Qmul_den_pos hεd (by decide), by simp only [mul]; omega, ?_⟩
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ hεd (by decide)))) ?_
  exact Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hεd (Int.le_of_lt hεn)) logN_2_ge_half)
    (Rmul_le_Rmul_right (Rnonneg_logN 2 (by omega)) hε)

/-- **The dyadic block as a rational geometric term**: `E(2ᵏ⁺¹) − E(2ᵏ) ≤ ofQ(rᵏ)`, `r = 1/(1+τ) < 1`,
    for `θ = (Re s−1)·log2 ≥ ofQ τ` (`τ > 0`) and `Re s ≥ 0`. -/
theorem czetaExp_block_geo (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (k : Nat) :
    Rle (Rsub (czetaExpSum s (2 ^ (k + 1))) (czetaExpSum s (2 ^ k)))
        (ofQ (qpow (Qinv (add ⟨1, 1⟩ τ)) k)
          (qpow_den_pos (Qinv_den_pos (by simp only [add]; push_cast; omega)) k)) := by
  have hrd : 0 < (Qinv (add (⟨1, 1⟩ : Q) τ)).den := Qinv_den_pos (by simp only [add]; push_cast; omega)
  have hrn : 0 ≤ (Qinv (add (⟨1, 1⟩ : Q) τ)).num := by
    show (0 : Int) ≤ ((add (⟨1, 1⟩ : Q) τ).den : Int); exact_mod_cast Nat.zero_le _
  refine Rle_trans (czetaExp_block_pow s hσ k) ?_
  refine Rle_trans (Rpow_mono
      (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) (RexpReal_nonneg _))
      (Rnonneg_ofQ hrd hrn) (czetaU_2u_le_of_theta s hτn hτd hθ) k) ?_
  exact Rle_of_Req (Rpow_ofQ hrd k)

/-- The rational geometric partial sum `Σ_{k=j}^{j+d−1} rᵏ` (block-first ordering). -/
def geoFrom (r : Q) (j : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (d + 1) => add (qpow r (j + d)) (geoFrom r j d)

theorem geoFrom_den_pos (r : Q) (hrd : 0 < r.den) (j : Nat) : ∀ d, 0 < (geoFrom r j d).den
  | 0 => Nat.one_pos
  | (d + 1) => add_den_pos (qpow_den_pos hrd (j + d)) (geoFrom_den_pos r hrd j d)

private theorem geo_step_id (X Y r : Q) :
    Qeq (add (mul X (Qsub ⟨1, 1⟩ r)) (Qsub Y X)) (Qsub Y (mul r X)) := by
  simp only [Qeq, mul, Qsub, add, neg]; push_cast; ring_uor

/-- **Geometric telescoping**: `(Σ_{k=j}^{j+d−1} rᵏ)·(1−r) = rʲ − r^{j+d}`. -/
theorem geoFrom_telescope (r : Q) (hrd : 0 < r.den) (j d : Nat) :
    Qeq (mul (geoFrom r j d) (Qsub ⟨1, 1⟩ r)) (Qsub (qpow r j) (qpow r (j + d))) := by
  induction d with
  | zero => simp only [geoFrom, Nat.add_zero, Qeq, mul, Qsub, add, neg]; push_cast; ring_uor
  | succ d ih =>
      have e1 : Qeq (mul (geoFrom r j (d + 1)) (Qsub ⟨1, 1⟩ r))
          (add (mul (qpow r (j + d)) (Qsub ⟨1, 1⟩ r)) (mul (geoFrom r j d) (Qsub ⟨1, 1⟩ r))) :=
        Qmul_add_right _ _ _
      refine Qeq_trans (add_den_pos (Qmul_den_pos (qpow_den_pos hrd _) (Qsub_den_pos Nat.one_pos hrd))
          (Qmul_den_pos (geoFrom_den_pos r hrd j d) (Qsub_den_pos Nat.one_pos hrd))) e1 ?_
      refine Qeq_trans (add_den_pos (Qmul_den_pos (qpow_den_pos hrd _) (Qsub_den_pos Nat.one_pos hrd))
          (Qsub_den_pos (qpow_den_pos hrd j) (qpow_den_pos hrd (j + d))))
        (Qadd_congr (Qeq_refl _) ih) ?_
      have hjd : j + (d + 1) = (j + d) + 1 := by omega
      rw [hjd]
      exact geo_step_id (qpow r (j + d)) (qpow r j) r

/-- **The tail is bounded by a vanishing geometric**: `Σ_{k=j}^{j+d−1} rᵏ ≤ rʲ/(1−r)` (for `0 ≤ r`, `r < 1`). -/
theorem geoFrom_le (r : Q) (hrd : 0 < r.den) (hr0 : 0 ≤ r.num) (hr1 : 0 < (Qsub (⟨1, 1⟩ : Q) r).num)
    (j d : Nat) :
    Qle (geoFrom r j d) (mul (qpow r j) (Qinv (Qsub ⟨1, 1⟩ r))) := by
  have hwd : 0 < (Qsub (⟨1, 1⟩ : Q) r).den := Qsub_den_pos Nat.one_pos hrd
  refine Qmul_le_cancel_right hr1 hwd ?_
  refine Qle_trans (Qsub_den_pos (qpow_den_pos hrd j) (qpow_den_pos hrd (j + d)))
    (Qeq_le (geoFrom_telescope r hrd j d)) ?_
  -- r^j − r^{j+d} ≤ (r^j/(1−r))·(1−r) = r^j
  have hcancel : Qeq (mul (mul (qpow r j) (Qinv (Qsub ⟨1, 1⟩ r))) (Qsub ⟨1, 1⟩ r)) (qpow r j) :=
    Qeq_trans (Qmul_den_pos (qpow_den_pos hrd j) (Qmul_den_pos (Qinv_den_pos hr1) hwd))
      (Qmul_assoc (qpow r j) (Qinv (Qsub ⟨1, 1⟩ r)) (Qsub ⟨1, 1⟩ r))
      (Qeq_trans (Qmul_den_pos (qpow_den_pos hrd j) Nat.one_pos)
        (Qmul_congr (Qeq_refl _) (Qinv_mul hwd hr1)) (mul_one (qpow r j)))
  refine Qle_trans (qpow_den_pos hrd j) ?_ (Qeq_le (Qeq_symm hcancel))
  show Qle (Qsub (qpow r j) (qpow r (j + d))) (qpow r j)
  have hnn : 0 ≤ (qpow r (j + d)).num := qpow_nonneg hr0 (j + d)
  exact Qsub_le_of_le_add (qpow_den_pos hrd (j + d)) (qpow_den_pos hrd j)
    (Qle_trans (add_den_pos (qpow_den_pos hrd j) (qpow_den_pos hrd (j + d)))
      (Qle_self_add hnn) (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)))

/-- **The geometric reindex**: with `m = (j+1)·q²` (`q = r.den`), `rᵐ/(1−r) ≤ 1/(j+1)`. The Bernoulli
    `1/(linear)` decay `qpow_geom_bound` plus the quadratic index collapse the geometric tail to the
    canonical modulus — the bridge that lets the dyadic partial sums satisfy `RReg`. -/
theorem geom_reindex {r : Q} (hrd : 0 < r.den) (hrn : 0 ≤ r.num) (hple : r.num.toNat ≤ r.den)
    (hsub : 0 < (Qsub (⟨1, 1⟩ : Q) r).num) (j : Nat) :
    Qle (mul (qpow r ((j + 1) * (r.den * r.den))) (Qinv (Qsub ⟨1, 1⟩ r))) ⟨1, j + 1⟩ := by
  have hgb := qpow_geom_bound hrn hrd hple ((j + 1) * (r.den * r.den))
  have hinn : 0 ≤ (Qinv (Qsub ⟨1, 1⟩ r)).num := by
    show (0 : Int) ≤ ((Qsub ⟨1, 1⟩ r).den : Int); exact_mod_cast Nat.zero_le _
  have hstep : Qle (mul (qpow r ((j + 1) * (r.den * r.den))) (Qinv (Qsub ⟨1, 1⟩ r)))
      (mul ⟨(r.den : Int), r.den + (j + 1) * (r.den * r.den) * (r.den - r.num.toNat)⟩
        (Qinv (Qsub ⟨1, 1⟩ r))) :=
    Qmul_le_mul_right hinn hgb
  refine Qle_trans
    (Qmul_den_pos (Nat.lt_of_lt_of_le hrd (Nat.le_add_right _ _)) (Qinv_den_pos hsub)) hstep ?_
  -- the (1−r) field facts
  have hsnum : (Qsub (⟨1, 1⟩ : Q) r).num = (r.den : Int) - r.num := by
    simp only [Qsub, add, neg]; push_cast; omega
  have htoN : (r.num.toNat : Int) = r.num := Int.toNat_of_nonneg hrn
  have hgpos : 0 < r.den - r.num.toNat := by rw [hsnum] at hsub; omega
  have hden : (Qsub (⟨1, 1⟩ : Q) r).den = r.den := by simp only [Qsub, add, neg, Nat.one_mul]
  have hnum : (Qsub (⟨1, 1⟩ : Q) r).num.toNat = r.den - r.num.toNat := by rw [hsnum]; omega
  -- the core Nat inequality  q²(j+1) ≤ (q + m·g)·g,  m = (j+1)q²,  g = q − p ≥ 1
  have hkey : r.den * r.den * (j + 1)
      ≤ (r.den + (j + 1) * (r.den * r.den) * (r.den - r.num.toNat)) * (r.den - r.num.toNat) := by
    have e1 : r.den * r.den * (j + 1) = (j + 1) * (r.den * r.den) := Nat.mul_comm _ _
    have e2 : (j + 1) * (r.den * r.den)
        ≤ (j + 1) * (r.den * r.den) * (r.den - r.num.toNat) := Nat.le_mul_of_pos_right _ hgpos
    have e3 : (j + 1) * (r.den * r.den) * (r.den - r.num.toNat)
        ≤ (j + 1) * (r.den * r.den) * (r.den - r.num.toNat) * (r.den - r.num.toNat) :=
      Nat.le_mul_of_pos_right _ hgpos
    have heq : (r.den + (j + 1) * (r.den * r.den) * (r.den - r.num.toNat)) * (r.den - r.num.toNat)
        = r.den * (r.den - r.num.toNat)
          + (j + 1) * (r.den * r.den) * (r.den - r.num.toNat) * (r.den - r.num.toNat) :=
      Nat.add_mul _ _ _
    omega
  -- discharge the rational ≤ via the Nat inequality
  simp only [Qle, mul, Qinv, hden, hnum, Int.one_mul]
  exact_mod_cast hkey
/-- **The dyadic tail telescopes to a geometric partial sum**: `E(2^{j+d}) − E(2ʲ) ≤ ofQ(Σ_{k=j}^{j+d−1} rᵏ)`. -/
theorem czetaExp_tail (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (j : Nat) : ∀ d,
    Rle (Rsub (czetaExpSum s (2 ^ (j + d))) (czetaExpSum s (2 ^ j)))
        (ofQ (geoFrom (Qinv (add ⟨1, 1⟩ τ)) j d)
          (geoFrom_den_pos _ (Qinv_den_pos (by simp only [add]; push_cast; omega)) j d))
  | 0 => Rle_of_Req (Radd_neg _)
  | (d + 1) => by
      refine Rle_trans (Rle_of_Req (Req_symm
          (Rsub_telescope (czetaExpSum s (2 ^ (j + d + 1))) (czetaExpSum s (2 ^ (j + d)))
            (czetaExpSum s (2 ^ j))))) ?_
      refine Rle_trans (Radd_le_add (czetaExp_block_geo s hσ hτn hτd hθ (j + d))
          (czetaExp_tail s hσ hτn hτd hθ j d)) ?_
      exact Rle_of_Req (Radd_ofQ_ofQ _ _)

/-- `(1−q).num = q.den − q.num` (generic; `q` kept opaque so the inner structure is untouched). -/
private theorem Qsub_one_num (q : Q) : (Qsub (⟨1, 1⟩ : Q) q).num = (q.den : Int) - q.num := by
  simp only [Qsub, add, neg]; push_cast; omega

/-- The field facts for `r = 1/(1+τ)` (`τ > 0`): `0 < r.den`, `0 ≤ r.num`, `r.num.toNat ≤ r.den`,
    `0 < (1−r).num` — the hypotheses `geoFrom_le`/`geom_reindex` need. -/
theorem czetaR_facts {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den) :
    (0 < (Qinv (add (⟨1, 1⟩ : Q) τ)).den) ∧ (0 ≤ (Qinv (add (⟨1, 1⟩ : Q) τ)).num) ∧
    ((Qinv (add (⟨1, 1⟩ : Q) τ)).num.toNat ≤ (Qinv (add (⟨1, 1⟩ : Q) τ)).den) ∧
    (0 < (Qsub ⟨1, 1⟩ (Qinv (add (⟨1, 1⟩ : Q) τ))).num) := by
  have hxnum : (add (⟨1, 1⟩ : Q) τ).num = (τ.den : Int) + τ.num := by simp only [add]; push_cast; omega
  have hxden : (add (⟨1, 1⟩ : Q) τ).den = τ.den := by simp only [add, Nat.one_mul]
  have hrnum : (Qinv (add (⟨1, 1⟩ : Q) τ)).num = (τ.den : Int) := by simp only [Qinv, hxden]
  have hrden : (Qinv (add (⟨1, 1⟩ : Q) τ)).den = ((τ.den : Int) + τ.num).toNat := by
    simp only [Qinv, hxnum]
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [hrden]; omega
  · rw [hrnum]; exact_mod_cast Nat.zero_le _
  · rw [hrnum, hrden]; omega
  · rw [Qsub_one_num, hrnum, hrden]; omega

/-- **The reindexed dyadic tail collapses to the canonical modulus**: at the base `M(j)=(j+1)·r.den²`,
    `E(2^{M(j)+d}) − E(2^{M(j)}) ≤ 1/(j+1)` for every `d`. Combines `czetaExp_tail` (≤ `geoFrom`),
    `geoFrom_le` (≤ `rᴹ/(1−r)`) and `geom_reindex` (≤ `1/(j+1)`). -/
theorem czetaExp_tail_reindex (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (j d : Nat) :
    Rle (Rsub (czetaExpSum s (2 ^ ((j + 1) *
              ((Qinv (add ⟨1, 1⟩ τ)).den * (Qinv (add ⟨1, 1⟩ τ)).den) + d)))
            (czetaExpSum s (2 ^ ((j + 1) *
              ((Qinv (add ⟨1, 1⟩ τ)).den * (Qinv (add ⟨1, 1⟩ τ)).den)))))
        (ofQ ⟨1, j + 1⟩ (Nat.succ_pos j)) := by
  obtain ⟨hrd, hr0, hple, hsub⟩ := czetaR_facts hτn hτd
  refine Rle_trans (czetaExp_tail s hσ hτn hτd hθ _ d) ?_
  refine Rle_ofQ_ofQ _ (Nat.succ_pos j) ?_
  exact Qle_trans (Qmul_den_pos (qpow_den_pos hrd _) (Qinv_den_pos hsub))
    (geoFrom_le _ hrd hr0 hsub _ d) (geom_reindex hrd hr0 hple hsub j)

/-- The reindex exponent `M(j) = (j+1)·r.den²` (`r = 1/(1+τ)`): the dyadic block index that makes the
    reindexed partial sums `S(2^{M(j)})` Cauchy with rate `1/(j+1)`. -/
def czetaMidx (τ : Q) (j : Nat) : Nat :=
  (j + 1) * ((Qinv (add ⟨1, 1⟩ τ)).den * (Qinv (add ⟨1, 1⟩ τ)).den)

theorem czetaMidx_mono {τ : Q} {j k : Nat} (hjk : j ≤ k) : czetaMidx τ j ≤ czetaMidx τ k :=
  Nat.mul_le_mul_right _ (by omega)

/-- **The reindexed dyadic modulus tail, monotone form**: for `j ≤ k`, `E(2^{M(k)}) − E(2^{M(j)}) ≤ 1/(j+1)`. -/
theorem czetaExp_tail_mono (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) {j k : Nat} (hjk : j ≤ k) :
    Rle (Rsub (czetaExpSum s (2 ^ czetaMidx τ k)) (czetaExpSum s (2 ^ czetaMidx τ j)))
        (ofQ ⟨1, j + 1⟩ (Nat.succ_pos j)) := by
  have hidx : czetaMidx τ k
      = czetaMidx τ j + (k - j) * ((Qinv (add ⟨1, 1⟩ τ)).den * (Qinv (add ⟨1, 1⟩ τ)).den) := by
    simp only [czetaMidx]; rw [← Nat.add_mul]; congr 1; omega
  rw [hidx]
  exact czetaExp_tail_reindex s hσ hτn hτd hθ j
    ((k - j) * ((Qinv (add ⟨1, 1⟩ τ)).den * (Qinv (add ⟨1, 1⟩ τ)).den))

/-- **The modulus partial sum is monotone**: `N ≤ M ⟹ E(N) ≤ E(M)` (each increment `exp(…) ≥ 0`). -/
theorem czetaExp_mono (s : Complex) {N M : Nat} (hNM : N ≤ M) :
    Rle (czetaExpSum s N) (czetaExpSum s M) := by
  obtain ⟨d, rfl⟩ := Nat.le.dest hNM
  clear hNM
  induction d with
  | zero => exact Rle_refl _
  | succ d ih => exact Rle_trans ih (Rle_self_Radd_right (RexpReal_nonneg _))

/-- **The reindexed modulus tail for *every* `N`** (not just dyadic): `E(N) − E(2^{M(j)}) ≤ 1/(j+1)`.
    `E(N) ≤ E(2^{M(j)+N})` (monotone, `N < 2ᴺ`) and the dyadic tail caps the latter; for `N < 2^{M(j)}` the
    difference is even `≤ 0`. -/
theorem czetaExp_tail_full (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (j N : Nat) :
    Rle (Rsub (czetaExpSum s N) (czetaExpSum s (2 ^ czetaMidx τ j))) (ofQ ⟨1, j + 1⟩ (Nat.succ_pos j)) := by
  have hNle : N ≤ 2 ^ (czetaMidx τ j + N) := by
    have key : ∀ m, m < 2 ^ m := by
      intro m; induction m with
      | zero => decide
      | succ k ih => rw [Nat.pow_succ]; omega
    have h2 := Nat.pow_le_pow_right (show 1 ≤ 2 by omega) (Nat.le_add_left N (czetaMidx τ j))
    have := key N
    omega
  refine Rle_trans (Radd_le_add (czetaExp_mono s hNle) (Rle_refl _)) ?_
  exact czetaExp_tail_reindex s hσ hτn hτd hθ j N

/-- Real-part tail for arbitrary `N ≥ 2^{M(j)}` (upper): `S_re(N) − S_re(2^{M(j)}) ≤ 1/(j+1)`. -/
theorem czetaRe_tail_full (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (j N : Nat)
    (hN : 2 ^ czetaMidx τ j ≤ N) :
    Rle (Rsub (czetaReSum s N) (czetaReSum s (2 ^ czetaMidx τ j))) (ofQ ⟨1, j + 1⟩ (Nat.succ_pos j)) :=
  Rle_trans (czeta_re_diff_le s hN) (czetaExp_tail_full s hσ hτn hτd hθ j N)

/-- Real-part tail for arbitrary `N ≥ 2^{M(j)}` (lower). -/
theorem czetaRe_tail_full_neg (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (j N : Nat)
    (hN : 2 ^ czetaMidx τ j ≤ N) :
    Rle (Rneg (Rsub (czetaReSum s N) (czetaReSum s (2 ^ czetaMidx τ j)))) (ofQ ⟨1, j + 1⟩ (Nat.succ_pos j)) :=
  Rle_trans (Rle_trans (Rle_Rneg (czeta_re_diff_ge s hN)) (Rle_of_Req (Rneg_neg _)))
    (czetaExp_tail_full s hσ hτn hτd hθ j N)

/-- Imaginary-part tail for arbitrary `N ≥ 2^{M(j)}` (upper). -/
theorem czetaIm_tail_full (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (j N : Nat)
    (hN : 2 ^ czetaMidx τ j ≤ N) :
    Rle (Rsub (czetaImSum s N) (czetaImSum s (2 ^ czetaMidx τ j))) (ofQ ⟨1, j + 1⟩ (Nat.succ_pos j)) :=
  Rle_trans (czeta_im_diff_le s hN) (czetaExp_tail_full s hσ hτn hτd hθ j N)

/-- Imaginary-part tail for arbitrary `N ≥ 2^{M(j)}` (lower). -/
theorem czetaIm_tail_full_neg (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (j N : Nat)
    (hN : 2 ^ czetaMidx τ j ≤ N) :
    Rle (Rneg (Rsub (czetaImSum s N) (czetaImSum s (2 ^ czetaMidx τ j)))) (ofQ ⟨1, j + 1⟩ (Nat.succ_pos j)) :=
  Rle_trans (Rle_trans (Rle_Rneg (czeta_im_diff_ge s hN)) (Rle_of_Req (Rneg_neg _)))
    (czetaExp_tail_full s hσ hτn hτd hθ j N)

/-- **The full real partial-sum sequence is uniformly Cauchy** (not just the dyadic subsequence): for
    *all* `N, N' ≥ 2^{M(j)}`, `|S_re(N) − S_re(N')| ≤ 2/(j+1)`. So `Σ_{n} Re(n⁻ˢ)` converges as a genuine
    series — every partial sum past the dyadic anchor agrees within `2/(j+1)`. -/
theorem czetaRe_cauchy_full (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (j N N' : Nat)
    (hN : 2 ^ czetaMidx τ j ≤ N) (hN' : 2 ^ czetaMidx τ j ≤ N') :
    Rle (Rsub (czetaReSum s N) (czetaReSum s N')) (ofQ ⟨2, j + 1⟩ (Nat.succ_pos j)) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_telescope (czetaReSum s N)
      (czetaReSum s (2 ^ czetaMidx τ j)) (czetaReSum s N')))) ?_
  refine Rle_trans (Radd_le_add (czetaRe_tail_full s hσ hτn hτd hθ j N hN)
      (Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub (czetaReSum s N') (czetaReSum s (2 ^ czetaMidx τ j)))))
        (czetaRe_tail_full_neg s hσ hτn hτd hθ j N' hN'))) ?_
  exact Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
    (ofQ_congr _ _ (by simp only [Qeq, add]; push_cast; ring_uor)))

/-- **The full imaginary partial-sum sequence is uniformly Cauchy**: `|S_im(N) − S_im(N')| ≤ 2/(j+1)`. -/
theorem czetaIm_cauchy_full (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (j N N' : Nat)
    (hN : 2 ^ czetaMidx τ j ≤ N) (hN' : 2 ^ czetaMidx τ j ≤ N') :
    Rle (Rsub (czetaImSum s N) (czetaImSum s N')) (ofQ ⟨2, j + 1⟩ (Nat.succ_pos j)) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_telescope (czetaImSum s N)
      (czetaImSum s (2 ^ czetaMidx τ j)) (czetaImSum s N')))) ?_
  refine Rle_trans (Radd_le_add (czetaIm_tail_full s hσ hτn hτd hθ j N hN)
      (Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub (czetaImSum s N') (czetaImSum s (2 ^ czetaMidx τ j)))))
        (czetaIm_tail_full_neg s hσ hτn hτd hθ j N' hN'))) ?_
  exact Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
    (ofQ_congr _ _ (by simp only [Qeq, add]; push_cast; ring_uor)))

/-- **Reindexed real-part partial sums are Cauchy (upper)**: `S_re(2^{M(k)}) − S_re(2^{M(j)}) ≤ 1/(j+1)`. -/
theorem czetaRe_tail_le (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) {j k : Nat} (hjk : j ≤ k) :
    Rle (Rsub (czetaReSum s (2 ^ czetaMidx τ k)) (czetaReSum s (2 ^ czetaMidx τ j)))
        (ofQ ⟨1, j + 1⟩ (Nat.succ_pos j)) :=
  Rle_trans (czeta_re_diff_le s (Nat.pow_le_pow_right (by omega) (czetaMidx_mono hjk)))
    (czetaExp_tail_mono s hσ hτn hτd hθ hjk)

/-- **Reindexed real-part partial sums are Cauchy (lower)**: `−(S_re(2^{M(k)}) − S_re(2^{M(j)})) ≤ 1/(j+1)`. -/
theorem czetaRe_tail_ge (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) {j k : Nat} (hjk : j ≤ k) :
    Rle (Rneg (Rsub (czetaReSum s (2 ^ czetaMidx τ k)) (czetaReSum s (2 ^ czetaMidx τ j))))
        (ofQ ⟨1, j + 1⟩ (Nat.succ_pos j)) :=
  Rle_trans (Rle_trans (Rle_Rneg (czeta_re_diff_ge s (Nat.pow_le_pow_right (by omega) (czetaMidx_mono hjk))))
      (Rle_of_Req (Rneg_neg _))) (czetaExp_tail_mono s hσ hτn hτd hθ hjk)

/-- **Reindexed imaginary-part partial sums are Cauchy (upper)**. -/
theorem czetaIm_tail_le (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) {j k : Nat} (hjk : j ≤ k) :
    Rle (Rsub (czetaImSum s (2 ^ czetaMidx τ k)) (czetaImSum s (2 ^ czetaMidx τ j)))
        (ofQ ⟨1, j + 1⟩ (Nat.succ_pos j)) :=
  Rle_trans (czeta_im_diff_le s (Nat.pow_le_pow_right (by omega) (czetaMidx_mono hjk)))
    (czetaExp_tail_mono s hσ hτn hτd hθ hjk)

/-- **Reindexed imaginary-part partial sums are Cauchy (lower)**. -/
theorem czetaIm_tail_ge (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) {j k : Nat} (hjk : j ≤ k) :
    Rle (Rneg (Rsub (czetaImSum s (2 ^ czetaMidx τ k)) (czetaImSum s (2 ^ czetaMidx τ j))))
        (ofQ ⟨1, j + 1⟩ (Nat.succ_pos j)) :=
  Rle_trans (Rle_trans (Rle_Rneg (czeta_im_diff_ge s (Nat.pow_le_pow_right (by omega) (czetaMidx_mono hjk))))
      (Rle_of_Req (Rneg_neg _))) (czetaExp_tail_mono s hσ hτn hτd hθ hjk)

/-- **From a real upper bound to a same-index rational bound** (the completeness bridge): if `a − b ≤ c`
    as reals (`c` a rational), then `aₙ − bₙ ≤ c + 2/(n+1)` for every index `n`. Regularity moves the
    comparison index `2m+1` back to `n`; the generalized Archimedean lemma kills the `3/(m+1)` tail. -/
theorem seq_diff_le (a b : Real) (c : Q) (hcd : 0 < c.den)
    (h : Rle (Rsub a b) (ofQ c hcd)) (n : Nat) :
    Qle (Qsub (a.seq n) (b.seq n)) (add c ⟨2, n + 1⟩) := by
  apply Qarch_gen (C := 3) (Qsub_den_pos (a.den_pos n) (b.den_pos n))
    (add_den_pos hcd (Nat.succ_pos _))
  intro m
  have hmid : Qle (Qsub (a.seq (2 * m + 1)) (b.seq (2 * m + 1))) (add c ⟨2, m + 1⟩) := h m
  have s1 : Qle (a.seq n) (add (a.seq (2 * m + 1)) (add (Qbound n) (Qbound (2 * m + 1)))) :=
    Qle_add_of_Qabs_sub (a.den_pos n) (a.den_pos _)
      (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (a.reg n (2 * m + 1))
  have s2 : Qle (neg (b.seq n)) (add (neg (b.seq (2 * m + 1))) (add (Qbound n) (Qbound (2 * m + 1)))) :=
    Qle_add_of_Qabs_sub (neg_den_pos (b.den_pos n)) (neg_den_pos (b.den_pos _))
      (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
      (by rw [Qabs_Qsub_neg]; exact b.reg n (2 * m + 1))
  have hp1 : Qle (Qsub (a.seq n) (b.seq n))
      (add (add (a.seq (2 * m + 1)) (add (Qbound n) (Qbound (2 * m + 1))))
           (add (neg (b.seq (2 * m + 1))) (add (Qbound n) (Qbound (2 * m + 1))))) :=
    Qadd_le_add s1 s2
  have hreg : Qeq
      (add (add (a.seq (2 * m + 1)) (add (Qbound n) (Qbound (2 * m + 1))))
           (add (neg (b.seq (2 * m + 1))) (add (Qbound n) (Qbound (2 * m + 1)))))
      (add (Qsub (a.seq (2 * m + 1)) (b.seq (2 * m + 1)))
           (add (add (Qbound n) (Qbound (2 * m + 1))) (add (Qbound n) (Qbound (2 * m + 1))))) := by
    simp only [Qeq, Qsub, add, neg, Qbound]; push_cast; ring_uor
  refine Qle_trans
    (add_den_pos (add_den_pos (a.den_pos _) (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)))
      (add_den_pos (neg_den_pos (b.den_pos _)) (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))))
    hp1 ?_
  refine Qle_trans
    (add_den_pos (Qsub_den_pos (a.den_pos _) (b.den_pos _))
      (add_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
        (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))))
    (Qeq_le hreg) ?_
  exact Qle_trans
    (add_den_pos (add_den_pos hcd (Nat.succ_pos _))
      (add_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
        (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))))
    (Qadd_le_add hmid (Qle_refl _))
    (Qeq_le (by simp only [Qeq, add, Qbound]; push_cast; ring_uor))

/-- **The completeness bridge to `RReg`**: a family `X : ℕ → ℝ` whose pairwise real differences are
    bounded by rationals `c j k ≤ 1/(j+1) + 1/(k+1)` is a regular sequence of reals. -/
theorem RReg_of_real_bound (X : Nat → Real) (c : Nat → Nat → Q) (hcd : ∀ j k, 0 < (c j k).den)
    (hcb : ∀ j k, Qle (c j k) (add ⟨1, j + 1⟩ ⟨1, k + 1⟩))
    (hX : ∀ j k, Rle (Rsub (X j) (X k)) (ofQ (c j k) (hcd j k))) : RReg X := by
  intro j k n
  have hjk : Qle (Qsub ((X j).seq n) ((X k).seq n)) (add (c j k) ⟨2, n + 1⟩) :=
    seq_diff_le (X j) (X k) (c j k) (hcd j k) (hX j k) n
  have hkj : Qle (Qsub ((X k).seq n) ((X j).seq n)) (add (c k j) ⟨2, n + 1⟩) :=
    seq_diff_le (X k) (X j) (c k j) (hcd k j) (hX k j) n
  have hcb' : Qle (c k j) (add ⟨1, j + 1⟩ ⟨1, k + 1⟩) :=
    Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (hcb k j)
      (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
  refine Qabs_le_of_both ?_ ?_
  · exact Qle_trans (add_den_pos (hcd j k) (Nat.succ_pos _)) hjk
      (Qadd_le_add (hcb j k) (Qle_refl _))
  · have hcomm : Qeq (Qsub ((X k).seq n) ((X j).seq n))
        (neg (Qsub ((X j).seq n) ((X k).seq n))) := by
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
    refine Qle_congr_left (Qsub_den_pos ((X k).den_pos n) ((X j).den_pos n)) hcomm ?_
    exact Qle_trans (add_den_pos (hcd k j) (Nat.succ_pos _)) hkj
      (Qadd_le_add hcb' (Qle_refl _))

/-- `y ≤ x + y` when `0 ≤ x` (the right-summand version of `Qle_self_add`). -/
private theorem Qle_self_add_left {x y : Q} (hx : 0 ≤ x.num) (hxd : 0 < x.den) (hyd : 0 < y.den) :
    Qle y (add x y) :=
  Qle_trans (add_den_pos hyd hxd) (Qle_self_add hx)
    (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))

/-- **The reindexed real-part partial sums form a regular sequence of reals** (`RReg`) — the input to
    Bishop's `Rlim`. Each pairwise difference is `≤ 1/(j+1) + 1/(k+1)` (the symmetric tail bound). -/
theorem czetaRe_RReg (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) :
    RReg (fun j => czetaReSum s (2 ^ czetaMidx τ j)) := by
  refine RReg_of_real_bound _ (fun j k => add ⟨1, j + 1⟩ ⟨1, k + 1⟩)
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (fun j k => Qle_refl _) ?_
  intro j k
  rcases Nat.le_total j k with hjk | hkj
  · refine Rle_trans (Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub _ _)))
        (czetaRe_tail_ge s hσ hτn hτd hθ hjk)) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos _) _ (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · refine Rle_trans (czetaRe_tail_le s hσ hτn hτd hθ hkj) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos _) _
      (Qle_self_add_left (by show (0 : Int) ≤ 1; decide) (Nat.succ_pos _) (Nat.succ_pos _))

/-- **The reindexed imaginary-part partial sums form a regular sequence of reals** (`RReg`). -/
theorem czetaIm_RReg (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) :
    RReg (fun j => czetaImSum s (2 ^ czetaMidx τ j)) := by
  refine RReg_of_real_bound _ (fun j k => add ⟨1, j + 1⟩ ⟨1, k + 1⟩)
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (fun j k => Qle_refl _) ?_
  intro j k
  rcases Nat.le_total j k with hjk | hkj
  · refine Rle_trans (Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub _ _)))
        (czetaIm_tail_ge s hσ hτn hτd hθ hjk)) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos _) _ (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · refine Rle_trans (czetaIm_tail_le s hσ hτn hτd hθ hkj) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos _) _
      (Qle_self_add_left (by show (0 : Int) ≤ 1; decide) (Nat.succ_pos _) (Nat.succ_pos _))

/-- **`RTendsTo` gives a real-level rate bound**: if `X → L` then `X k − L ≤ 2/(k+1)` as reals. The
    `.seq`-level modulus (read at `2n+1`) lands inside the real comparison's `2/(n+1)` slack. -/
theorem RTendsTo_to_Rle {X : Nat → Real} {L : Real} (h : RTendsTo X L) (k : Nat) :
    Rle (Rsub (X k) L) (ofQ ⟨2, k + 1⟩ (Nat.succ_pos k)) := by
  intro n
  refine Qle_trans (Qabs_den_pos (Qsub_den_pos ((X k).den_pos _) (L.den_pos _)))
    (Qle_self_Qabs (Qsub ((X k).seq (2 * n + 1)) (L.seq (2 * n + 1)))) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (h k (2 * n + 1)) ?_
  exact Qadd_le_add (Qle_refl _)
    (by show (2 : Int) * ((n + 1 : Nat) : Int) ≤ 2 * ((2 * n + 1 + 1 : Nat) : Int); push_cast; omega)

/-- The companion lower bound `L − X k ≤ 2/(k+1)`. -/
theorem RTendsTo_to_Rle_lower {X : Nat → Real} {L : Real} (h : RTendsTo X L) (k : Nat) :
    Rle (Rsub L (X k)) (ofQ ⟨2, k + 1⟩ (Nat.succ_pos k)) := by
  intro n
  refine Qle_trans (Qabs_den_pos (Qsub_den_pos (L.den_pos _) ((X k).den_pos _)))
    (Qle_self_Qabs (Qsub (L.seq (2 * n + 1)) ((X k).seq (2 * n + 1)))) ?_
  rw [Qabs_Qsub_comm]
  refine Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (h k (2 * n + 1)) ?_
  exact Qadd_le_add (Qle_refl _)
    (by show (2 : Int) * ((n + 1 : Nat) : Int) ≤ 2 * ((2 * n + 1 + 1 : Nat) : Int); push_cast; omega)

/-- **Real-level Archimedean ⟹ `≈`**: if `a − b ≤ C/(k+1)` and `b − a ≤ C/(k+1)` (as reals) for every
    `k`, then `a ≈ b`. The vanishing real bound forces Bishop equality (`seq_diff_le` lands the bound at
    each index, the generalized Archimedean lemma kills the `k`-tail, `Req_of_lin_bound` closes). -/
theorem Req_of_Rle_ofQ_all {a b : Real} {C : Nat}
    (hab : ∀ k, Rle (Rsub a b) (ofQ ⟨(C : Int), k + 1⟩ (Nat.succ_pos k)))
    (hba : ∀ k, Rle (Rsub b a) (ofQ ⟨(C : Int), k + 1⟩ (Nat.succ_pos k))) : Req a b := by
  apply Req_of_lin_bound (C := 2)
  intro n
  have hub : Qle (Qsub (a.seq n) (b.seq n)) ⟨2, n + 1⟩ := by
    apply Qarch_gen (C := C) (Qsub_den_pos (a.den_pos n) (b.den_pos n)) (Nat.succ_pos n)
    intro k
    exact Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
      (seq_diff_le a b ⟨(C : Int), k + 1⟩ (Nat.succ_pos k) (hab k) n)
      (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
  have hlb : Qle (Qsub (b.seq n) (a.seq n)) ⟨2, n + 1⟩ := by
    apply Qarch_gen (C := C) (Qsub_den_pos (b.den_pos n) (a.den_pos n)) (Nat.succ_pos n)
    intro k
    exact Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
      (seq_diff_le b a ⟨(C : Int), k + 1⟩ (Nat.succ_pos k) (hba k) n)
      (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
  refine Qabs_le_of_both hub
    (Qle_congr_left (Qsub_den_pos (b.den_pos n) (a.den_pos n))
      (by simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor) hlb)

/-- **The Riemann zeta function `ζ(s) = Σ_{n≥1} n⁻ˢ` for `Re s > 1`** — a genuine constructive complex
    number. `Re s > 1` is witnessed by a rational `τ > 0` with `τ ≤ (Re s − 1)·log 2` (so the dyadic
    ratio `2^{1−Re s} < 1`); the real and imaginary parts are Bishop diagonal limits of the reindexed
    partial sums `Σ_{n<2^{M(j)}} Re/Im(n⁻ˢ)`, which converge geometrically (the rigorous complex tail). -/
def Czeta (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) : Complex :=
  ⟨Rlim (fun j => czetaReSum s (2 ^ czetaMidx τ j)) (czetaRe_RReg s hσ hτn hτd hθ),
   Rlim (fun j => czetaImSum s (2 ^ czetaMidx τ j)) (czetaIm_RReg s hσ hτn hτd hθ)⟩

/-- **`Re s > 1` is satisfiable** (non-vacuity witness): for `s = 2` (real), `τ = 1/2 ≤ (2−1)·log 2 = log 2`.
    `Rsub (ofQ 2) one ≈ one` (`2 − 1 = 1`) and `Rmul one (log 2) ≈ log 2`, so the bound reduces to
    `1/2 ≤ log 2` (`logN_2_ge_half`). -/
theorem czeta_two_theta :
    Rle (ofQ (⟨1, 2⟩ : Q) (by decide))
        (Rmul (Rsub (ofQ (⟨2, 1⟩ : Q) (by decide)) one) (logN 2 (by omega))) := by
  have hsub : Req (Rsub (ofQ (⟨2, 1⟩ : Q) (by decide)) one) one :=
    Req_of_seq_Qeq (fun n => by
      show Qeq (add (⟨2, 1⟩ : Q) (neg ⟨1, 1⟩)) (⟨1, 1⟩ : Q); decide)
  exact Rle_trans logN_2_ge_half
    (Rle_of_Req (Req_symm (Req_trans (Rmul_congr hsub (Req_refl _)) (Rone_mul _))))

/-- **Convergence of `ζ(s)` (real part)**: the reindexed real partial sums `Σ_{n<2^{M(k)}} Re(n⁻ˢ)`
    converge to `Re ζ(s)` with the canonical rate `2/(k+1)`. -/
theorem Czeta_re_tendsTo (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) :
    RTendsTo (fun j => czetaReSum s (2 ^ czetaMidx τ j)) (Czeta s hσ hτn hτd hθ).re :=
  Rlim_tendsTo _ (czetaRe_RReg s hσ hτn hτd hθ)

/-- **Convergence of `ζ(s)` (imaginary part)**: the reindexed imaginary partial sums converge to
    `Im ζ(s)` with rate `2/(k+1)`. -/
theorem Czeta_im_tendsTo (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) :
    RTendsTo (fun j => czetaImSum s (2 ^ czetaMidx τ j)) (Czeta s hσ hτn hτd hθ).im :=
  Rlim_tendsTo _ (czetaIm_RReg s hσ hτn hτd hθ)

/-- **The full real partial-sum sequence converges to `Re ζ(s)`** (not just the dyadic subsequence): for
    *every* `N ≥ 2^{M(k)}`, `|S_re(N) − Re ζ(s)| ≤ 3/(k+1)`. Triangle through the dyadic anchor:
    `1/(k+1)` (tail) + `2/(k+1)` (subsequence limit). -/
theorem czetaRe_full_tendsTo (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (k N : Nat)
    (hN : 2 ^ czetaMidx τ k ≤ N) :
    Rle (Rsub (czetaReSum s N) (Czeta s hσ hτn hτd hθ).re) (ofQ ⟨3, k + 1⟩ (Nat.succ_pos k))
      ∧ Rle (Rsub (Czeta s hσ hτn hτd hθ).re (czetaReSum s N)) (ofQ ⟨3, k + 1⟩ (Nat.succ_pos k)) := by
  refine ⟨?_, ?_⟩
  · refine Rle_trans (Rle_of_Req (Req_symm (Rsub_telescope (czetaReSum s N)
        (czetaReSum s (2 ^ czetaMidx τ k)) (Czeta s hσ hτn hτd hθ).re))) ?_
    refine Rle_trans (Radd_le_add (czetaRe_tail_full s hσ hτn hτd hθ k N hN)
        (RTendsTo_to_Rle (Czeta_re_tendsTo s hσ hτn hτd hθ) k)) ?_
    exact Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
      (ofQ_congr _ _ (by simp only [Qeq, add]; push_cast; ring_uor)))
  · refine Rle_trans (Rle_of_Req (Req_symm (Rsub_telescope (Czeta s hσ hτn hτd hθ).re
        (czetaReSum s (2 ^ czetaMidx τ k)) (czetaReSum s N)))) ?_
    refine Rle_trans (Radd_le_add (RTendsTo_to_Rle_lower (Czeta_re_tendsTo s hσ hτn hτd hθ) k)
        (Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub (czetaReSum s N) (czetaReSum s (2 ^ czetaMidx τ k)))))
          (czetaRe_tail_full_neg s hσ hτn hτd hθ k N hN))) ?_
    exact Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
      (ofQ_congr _ _ (by simp only [Qeq, add]; push_cast; ring_uor)))

/-- **The full imaginary partial-sum sequence converges to `Im ζ(s)`**: `|S_im(N) − Im ζ(s)| ≤ 3/(k+1)`
    for every `N ≥ 2^{M(k)}`. -/
theorem czetaIm_full_tendsTo (s : Complex) (hσ : Rnonneg s.re) {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hθ : Rle (ofQ τ hτd) (Rmul (Rsub s.re one) (logN 2 (by omega)))) (k N : Nat)
    (hN : 2 ^ czetaMidx τ k ≤ N) :
    Rle (Rsub (czetaImSum s N) (Czeta s hσ hτn hτd hθ).im) (ofQ ⟨3, k + 1⟩ (Nat.succ_pos k))
      ∧ Rle (Rsub (Czeta s hσ hτn hτd hθ).im (czetaImSum s N)) (ofQ ⟨3, k + 1⟩ (Nat.succ_pos k)) := by
  refine ⟨?_, ?_⟩
  · refine Rle_trans (Rle_of_Req (Req_symm (Rsub_telescope (czetaImSum s N)
        (czetaImSum s (2 ^ czetaMidx τ k)) (Czeta s hσ hτn hτd hθ).im))) ?_
    refine Rle_trans (Radd_le_add (czetaIm_tail_full s hσ hτn hτd hθ k N hN)
        (RTendsTo_to_Rle (Czeta_im_tendsTo s hσ hτn hτd hθ) k)) ?_
    exact Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
      (ofQ_congr _ _ (by simp only [Qeq, add]; push_cast; ring_uor)))
  · refine Rle_trans (Rle_of_Req (Req_symm (Rsub_telescope (Czeta s hσ hτn hτd hθ).im
        (czetaImSum s (2 ^ czetaMidx τ k)) (czetaImSum s N)))) ?_
    refine Rle_trans (Radd_le_add (RTendsTo_to_Rle_lower (Czeta_im_tendsTo s hσ hτn hτd hθ) k)
        (Rle_trans (Rle_of_Req (Req_symm (Rneg_Rsub (czetaImSum s N) (czetaImSum s (2 ^ czetaMidx τ k)))))
          (czetaIm_tail_full_neg s hσ hτn hτd hθ k N hN))) ?_
    exact Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
      (ofQ_congr _ _ (by simp only [Qeq, add]; push_cast; ring_uor)))

/-- **Canonicity (real part)**: `ζ(s)` does not depend on the convergence witness `τ`. Any two witnesses
    `τ₁, τ₂` of `Re s > 1` give `≈`-equal real parts — both are the limit of the *same* full partial-sum
    sequence (compared at `N = max(2^{M₁(k)}, 2^{M₂(k)})`), so the limit is unique. -/
theorem Czeta_re_canonical (s : Complex) (hσ : Rnonneg s.re) {τ₁ τ₂ : Q}
    (hτn₁ : 0 < τ₁.num) (hτd₁ : 0 < τ₁.den)
    (hθ₁ : Rle (ofQ τ₁ hτd₁) (Rmul (Rsub s.re one) (logN 2 (by omega))))
    (hτn₂ : 0 < τ₂.num) (hτd₂ : 0 < τ₂.den)
    (hθ₂ : Rle (ofQ τ₂ hτd₂) (Rmul (Rsub s.re one) (logN 2 (by omega)))) :
    Req (Czeta s hσ hτn₁ hτd₁ hθ₁).re (Czeta s hσ hτn₂ hτd₂ hθ₂).re := by
  apply Req_of_Rle_ofQ_all (C := 6)
  · intro k
    refine Rle_trans (Rle_of_Req (Req_symm (Rsub_telescope (Czeta s hσ hτn₁ hτd₁ hθ₁).re
        (czetaReSum s (max (2 ^ czetaMidx τ₁ k) (2 ^ czetaMidx τ₂ k)))
        (Czeta s hσ hτn₂ hτd₂ hθ₂).re))) ?_
    refine Rle_trans (Radd_le_add
        (czetaRe_full_tendsTo s hσ hτn₁ hτd₁ hθ₁ k _ (Nat.le_max_left _ _)).2
        (czetaRe_full_tendsTo s hσ hτn₂ hτd₂ hθ₂ k _ (Nat.le_max_right _ _)).1) ?_
    exact Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
      (ofQ_congr _ _ (by simp only [Qeq, add]; push_cast; ring_uor)))
  · intro k
    refine Rle_trans (Rle_of_Req (Req_symm (Rsub_telescope (Czeta s hσ hτn₂ hτd₂ hθ₂).re
        (czetaReSum s (max (2 ^ czetaMidx τ₁ k) (2 ^ czetaMidx τ₂ k)))
        (Czeta s hσ hτn₁ hτd₁ hθ₁).re))) ?_
    refine Rle_trans (Radd_le_add
        (czetaRe_full_tendsTo s hσ hτn₂ hτd₂ hθ₂ k _ (Nat.le_max_right _ _)).2
        (czetaRe_full_tendsTo s hσ hτn₁ hτd₁ hθ₁ k _ (Nat.le_max_left _ _)).1) ?_
    exact Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
      (ofQ_congr _ _ (by simp only [Qeq, add]; push_cast; ring_uor)))

/-- **Canonicity (imaginary part)**: `Im ζ(s)` is independent of the witness `τ`. -/
theorem Czeta_im_canonical (s : Complex) (hσ : Rnonneg s.re) {τ₁ τ₂ : Q}
    (hτn₁ : 0 < τ₁.num) (hτd₁ : 0 < τ₁.den)
    (hθ₁ : Rle (ofQ τ₁ hτd₁) (Rmul (Rsub s.re one) (logN 2 (by omega))))
    (hτn₂ : 0 < τ₂.num) (hτd₂ : 0 < τ₂.den)
    (hθ₂ : Rle (ofQ τ₂ hτd₂) (Rmul (Rsub s.re one) (logN 2 (by omega)))) :
    Req (Czeta s hσ hτn₁ hτd₁ hθ₁).im (Czeta s hσ hτn₂ hτd₂ hθ₂).im := by
  apply Req_of_Rle_ofQ_all (C := 6)
  · intro k
    refine Rle_trans (Rle_of_Req (Req_symm (Rsub_telescope (Czeta s hσ hτn₁ hτd₁ hθ₁).im
        (czetaImSum s (max (2 ^ czetaMidx τ₁ k) (2 ^ czetaMidx τ₂ k)))
        (Czeta s hσ hτn₂ hτd₂ hθ₂).im))) ?_
    refine Rle_trans (Radd_le_add
        (czetaIm_full_tendsTo s hσ hτn₁ hτd₁ hθ₁ k _ (Nat.le_max_left _ _)).2
        (czetaIm_full_tendsTo s hσ hτn₂ hτd₂ hθ₂ k _ (Nat.le_max_right _ _)).1) ?_
    exact Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
      (ofQ_congr _ _ (by simp only [Qeq, add]; push_cast; ring_uor)))
  · intro k
    refine Rle_trans (Rle_of_Req (Req_symm (Rsub_telescope (Czeta s hσ hτn₂ hτd₂ hθ₂).im
        (czetaImSum s (max (2 ^ czetaMidx τ₁ k) (2 ^ czetaMidx τ₂ k)))
        (Czeta s hσ hτn₁ hτd₁ hθ₁).im))) ?_
    refine Rle_trans (Radd_le_add
        (czetaIm_full_tendsTo s hσ hτn₂ hτd₂ hθ₂ k _ (Nat.le_max_right _ _)).2
        (czetaIm_full_tendsTo s hσ hτn₁ hτd₁ hθ₁ k _ (Nat.le_max_left _ _)).1) ?_
    exact Rle_of_Req (Req_trans (Radd_ofQ_ofQ _ _)
      (ofQ_congr _ _ (by simp only [Qeq, add]; push_cast; ring_uor)))

end Multiplicity.UOR.Bridge.F1Square.Analysis
