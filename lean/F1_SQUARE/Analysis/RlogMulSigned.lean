import F1Square.Analysis.ClogAddBounded
import F1Square.Analysis.Gamma

/-!
# Signed-τ artanh/exp substrate — toward general-modulus `Rlog`/`Clog` additivity

The bounded-modulus discharge (`RlogMulPos`, `ClogAddBounded`) requires squared moduli `≥ 1`
(so the `tmap` arguments are `≥ 0`). Extending to the symmetric band `[1/B, B]` (moduli near 1,
above *and* below) needs the artanh/exp identities for **signed** arguments.

The key observation that sidesteps re-deriving the `t≥0` corner bounds: `exp(2·artanh τ) =
(1+τ)/(1−τ)` for `τ < 0` follows from the nonnegative case by **oddness**
(`artanh(−σ) = −artanh σ`, `Rartanh_neg`) and **exp-of-negation** (`exp(−x)·exp(x) = 1`,
`RexpReal_add`), with the addition law lifted through `RexpReal_inj_gen` (no nonneg restriction).

This file builds that substrate bottom-up.
-/

namespace UOR.Bridge.F1Square.Analysis

/-- **`artanh` is odd**: `Rartanh(−t) = −Rartanh t`. Per diagonal index the partial sum negates
    (`artSum_neg`), since the artanh series has only odd-degree terms. The bound for `−t` follows
    from the bound for `t` (`Qabs_neg`). -/
theorem Rartanh_neg (t : Real) (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs (t.seq n)) ρ)
    (hb' : ∀ n, Qle (Qabs ((Rneg t).seq n)) ρ) :
    Req (Rartanh (Rneg t) ρ hρ0 hρd hlt hb') (Rneg (Rartanh t ρ hρ0 hρd hlt hb)) := by
  refine Req_of_seq_Qeq (fun j => ?_)
  show Qeq (artSum ((Rneg t).seq (Rartanh_R ρ j)) (Rartanh_R ρ j))
        (neg (artSum (t.seq (Rartanh_R ρ j)) (Rartanh_R ρ j)))
  exact artSum_neg (t.den_pos _) (Rartanh_R ρ j)

/-- **`artanh` of a negated rational constant**: `RartanhConst(−τ) = −RartanhConst τ` (at any valid
    radius). Per-diagonal `artSum (neg τ) N = neg(artSum τ N)` (`artSum_neg`); no small-radius needed. -/
theorem RartanhConst_neg (τ ρ : Q) (hτd : 0 < τ.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hρlt : ρ.num.toNat < ρ.den) (hb : Qle (Qabs τ) ρ) (hbn : Qle (Qabs (neg τ)) ρ) :
    Req (RartanhConst (neg τ) ρ (by exact hτd) hρ0 hρd hρlt hbn)
        (Rneg (RartanhConst τ ρ hτd hρ0 hρd hρlt hb)) := by
  refine Req_of_seq_Qeq (fun j => ?_)
  show Qeq (artSum (neg τ) (Rartanh_R ρ j)) (neg (artSum τ (Rartanh_R ρ j)))
  exact artSum_neg hτd (Rartanh_R ρ j)

/-- **`2·artanh` of a negated rational constant**: `TwoArtanhConst(−τ) = −TwoArtanhConst τ`. -/
theorem TwoArtanhConst_neg (τ ρ : Q) (hτd : 0 < τ.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hρlt : ρ.num.toNat < ρ.den) (hb : Qle (Qabs τ) ρ) (hbn : Qle (Qabs (neg τ)) ρ) :
    Req (TwoArtanhConst (neg τ) ρ (by exact hτd) hρ0 hρd hρlt hbn)
        (Rneg (TwoArtanhConst τ ρ hτd hρ0 hρd hρlt hb)) :=
  Req_trans (Rmul_congr (Req_refl _) (RartanhConst_neg τ ρ hτd hρ0 hρd hρlt hb hbn))
    (Rmul_neg_right (ofQ ⟨2, 1⟩ (by decide)) (RartanhConst τ ρ hτd hρ0 hρd hρlt hb))

set_option maxHeartbeats 800000 in
/-- **★ The signed exp/artanh identity** `exp(2·artanh τ) = (1+τ)/(1−τ)` for `τ < 0`, derived from the
    nonnegative case (`hσid`, supplied for `σ = −τ > 0`) by oddness + exp-of-negation — *no* re-derivation
    of the `t ≥ 0` corner bounds. With `gσ = (1+σ)/(1−σ) > 1` (`hgσwit`) and `gτ·gσ = 1` (`hrecip`,
    i.e. `gτ = 1/gσ = (1+τ)/(1−τ)`): `exp(2artanh τ) = exp(−2artanh σ) = 1/exp(2artanh σ) = 1/gσ = gτ`. -/
theorem Rexp_TwoArtanh_of_neg (τ ρ gσ gτ : Q) (hτd : 0 < τ.den)
    (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : Qle (Qabs τ) ρ) (hbn : Qle (Qabs (neg τ)) ρ)
    (hgσd : 0 < gσ.den) (hgτd : 0 < gτ.den)
    (hgσwit : Qlt (Qbound 0) gσ) (hrecip : Qeq (mul gτ gσ) ⟨1, 1⟩)
    (hσid : Req (RexpReal (TwoArtanhConst (neg τ) ρ (by exact hτd) hρ0 hρd hρlt hbn)) (ofQ gσ hgσd)) :
    Req (RexpReal (TwoArtanhConst τ ρ hτd hρ0 hρd hρlt hb)) (ofQ gτ hgτd) := by
  let Y := TwoArtanhConst (neg τ) ρ (by exact hτd) hρ0 hρd hρlt hbn
  let Yτ := TwoArtanhConst τ ρ hτd hρ0 hρd hρlt hb
  have hA : Req Y (Rneg Yτ) := TwoArtanhConst_neg τ ρ hτd hρ0 hρd hρlt hb hbn
  have htac : Req Yτ (Rneg Y) := Req_symm (Req_trans (Rneg_congr hA) (Rneg_neg Yτ))
  have hsum0 : Req (Radd (Rneg Y) Y) zero := Req_trans (Radd_comm (Rneg Y) Y) (Radd_neg Y)
  have hprod1 : Req (Rmul (RexpReal (Rneg Y)) (RexpReal Y)) one :=
    Req_trans (Req_symm (RexpReal_add (Rneg Y) Y))
      (Req_trans (RexpReal_congr hsum0) RexpReal_zero)
  have hprodσ : Req (Rmul (RexpReal (Rneg Y)) (ofQ gσ hgσd)) one :=
    Req_trans (Rmul_congr (Req_refl _) (Req_symm hσid)) hprod1
  have hprodgτ : Req (Rmul (ofQ gτ hgτd) (ofQ gσ hgσd)) one :=
    Req_trans (Rmul_ofQ_ofQ hgτd hgσd) (ofQ_congr (Qmul_den_pos hgτd hgσd) (by decide) hrecip)
  have hk : Qlt (Qbound 0) ((ofQ gσ hgσd).seq 0) := hgσwit
  have hcancel : Req (RexpReal (Rneg Y)) (ofQ gτ hgτd) :=
    Rmul_right_cancel hk (Req_trans hprodσ (Req_symm hprodgτ))
  exact Req_trans (RexpReal_congr htac) hcancel

/-- Pure-`Int` multiplicativity identity behind the signed `hg`: `(1+c)/(1−c) = (1+a)/(1−a)·(1+b)/(1−b)`
    cleared, where `c = wvalR a b` has `(num,den) = (pa qb+pb qa, qa qb+pa pb)`. -/
private theorem wvalR_hg_poly (pa qa pb qb : Int) :
    ((qa * qb + pa * pb) + (pa * qb + pb * qa)) * ((qa - pa) * (qb - pb))
      = ((qa + pa) * (qb + pb)) * ((qa - pa) * (qb - pb)) := by ring_uor

/-- **Signed `hg` multiplicativity** for the normalized `(den+num)/(den−num)` exp-values: with
    `c = wvalR a b`, `gC = gA·gB`. The signed analog of `wval_hg`, using the `(·.den−·.num).toNat`
    (Int-toNat) dens that match `Rexp_TwoArtanh_signed_rho`'s output. Requires `|a|, |b| < 1`
    (`a.num < a.den`, `−a.den < a.num`, etc.) and `1 + ab > 0`. -/
theorem wvalR_hg (a b : Q) (haL : a.num < (a.den : Int)) (hbL : b.num < (b.den : Int))
    (hab : 0 < (a.den : Int) * b.den + a.num * b.num) :
    Qeq (⟨((wvalR a b).den : Int) + (wvalR a b).num,
          (((wvalR a b).den : Int) - (wvalR a b).num).toNat⟩ : Q)
        (mul (⟨(a.den : Int) + a.num, ((a.den : Int) - a.num).toNat⟩ : Q)
             (⟨(b.den : Int) + b.num, ((b.den : Int) - b.num).toNat⟩ : Q)) := by
  have hWden : ((wvalR a b).den : Int) = (a.den : Int) * b.den + a.num * b.num := by
    rw [wvalR_den]; exact Int.toNat_of_nonneg (Int.le_of_lt hab)
  have hgA : (((a.den : Int) - a.num).toNat : Int) = (a.den : Int) - a.num :=
    Int.toNat_of_nonneg (by omega)
  have hgB : (((b.den : Int) - b.num).toNat : Int) = (b.den : Int) - b.num :=
    Int.toNat_of_nonneg (by omega)
  have hCnn : 0 ≤ ((wvalR a b).den : Int) - (wvalR a b).num := by
    rw [hWden, wvalR_num]
    have hfac : (a.den : Int) * b.den + a.num * b.num - (a.num * (b.den : Int) + b.num * (a.den : Int))
        = ((a.den : Int) - a.num) * ((b.den : Int) - b.num) := by
      generalize (a.den : Int) = qa; generalize (b.den : Int) = qb; ring_uor
    rw [hfac]; exact Int.mul_nonneg (by omega) (by omega)
  have hgC : ((((wvalR a b).den : Int) - (wvalR a b).num).toNat : Int)
      = (a.den : Int) * b.den + a.num * b.num - (a.num * (b.den : Int) + b.num * (a.den : Int)) := by
    rw [Int.toNat_of_nonneg hCnn, hWden, wvalR_num]
  simp only [Qeq, mul]
  rw [hgC]
  push_cast [hgA, hgB, hWden, wvalR_num]
  generalize (a.den : Int) = qa; generalize (b.den : Int) = qb
  generalize a.num = pa; generalize b.num = pb
  rw [show qa * qb + pa * pb + (pa * qb + pb * qa) = (qa + pa) * (qb + pb) from by ring_uor,
    show qa * qb + pa * pb - (pa * qb + pb * qa) = (qa - pa) * (qb - pb) from by ring_uor]

/-- **Additivity from exp-values, no sign restriction** (the `RexpReal_inj_gen` core): if `exp A = gA`,
    `exp B = gB`, `exp C = gC` with `gC = gA·gB`, then `C = A + B` — for **any** reals `A, B, C`
    (dropping the `≥ 0` hypotheses of `Req_add_of_exp_values`, via the general injectivity
    `RexpReal_inj_gen`). The engine for the *signed* artanh addition law. -/
theorem Req_add_of_exp_values_gen {A B C : Real} {gA gB gC : Q}
    (hgAd : 0 < gA.den) (hgBd : 0 < gB.den) (hgCd : 0 < gC.den)
    (hA : Req (RexpReal A) (ofQ gA hgAd)) (hB : Req (RexpReal B) (ofQ gB hgBd))
    (hC : Req (RexpReal C) (ofQ gC hgCd)) (hg : Qeq gC (mul gA gB)) :
    Req C (Radd A B) := by
  apply RexpReal_inj_gen
  have hmul : Req (RexpReal (Radd A B)) (ofQ gC hgCd) :=
    Req_trans (RexpReal_add A B)
      (Req_trans (Rmul_congr hA hB)
        (Req_trans (Rmul_ofQ_ofQ hgAd hgBd)
          (ofQ_congr (Qmul_den_pos hgAd hgBd) hgCd (Qeq_symm hg))))
  exact Req_trans hC (Req_symm hmul)

set_option maxHeartbeats 800000 in
/-- **★ sign-agnostic exp/artanh identity** `exp(2·artanh τ) = (1+τ)/(1−τ)` for **any** rational `τ`
    with `|τ| < 1` (`τ.num.toNat < τ.den` and `(−τ).num.toNat < τ.den`), at any radius `ρ ≥ |τ|`.
    Case-splits on the (decidable) sign of `τ.num`: the nonnegative packager
    `Rexp_twoArtanh_general_rho` for `τ ≥ 0`, the new `Rexp_TwoArtanh_of_neg` for `τ < 0`. Output
    normalized to `(τ.den+τ.num)/(τ.den−τ.num)`. -/
theorem Rexp_TwoArtanh_signed_rho (τ ρ : Q) (hτd : 0 < τ.den)
    (hτlt : τ.num.toNat < τ.den) (hτlt' : (neg τ).num.toNat < τ.den)
    (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : Qle (Qabs τ) ρ) (hbn : Qle (Qabs (neg τ)) ρ) :
    Req (RexpReal (TwoArtanhConst τ ρ hτd hρ0 hρd hρlt hb))
      (ofQ (⟨(τ.den : Int) + τ.num, (τ.den - τ.num).toNat⟩ : Q)
        (by show 0 < (τ.den - τ.num).toNat
            have h' := hτlt'; simp only [neg] at h'; omega)) := by
  have hdpos : 0 < (τ.den - τ.num).toNat := by
    have h' := hτlt'; simp only [neg] at h'; omega
  have hqI : ((τ.den - τ.num).toNat : Int) = (τ.den : Int) - τ.num :=
    Int.toNat_of_nonneg (by have := hτlt; omega)
  by_cases hneg : τ.num < 0
  · -- τ < 0: reduce to the nonneg case for σ = −τ
    have hσge : 0 ≤ (neg τ).num := by show 0 ≤ -τ.num; omega
    have hσlt : (neg τ).num.toNat < (neg τ).den := by simpa only [neg] using hτlt'
    have hσd : 0 < (neg τ).den := hτd
    have hND : ((τ.den - (-τ.num).toNat : Nat) : Int) = (τ.den : Int) + τ.num := by
      rw [Int.ofNat_sub (by simpa only [neg] using Nat.le_of_lt hσlt),
        Int.toNat_of_nonneg (show (0 : Int) ≤ -τ.num by omega)]; omega
    have hσid := Rexp_twoArtanh_general_rho (neg τ) ρ hσd hσge hσlt hρ0 hρd hρlt hbn
    refine Rexp_TwoArtanh_of_neg τ ρ _ _ hτd hρ0 hρd hρlt hb hbn _ _ ?_ ?_ hσid
    · -- gσ > 1
      show Qlt (Qbound 0) (⟨((neg τ).den : Int) + (neg τ).num, ((neg τ).den - (neg τ).num.toNat)⟩ : Q)
      simp only [Qlt, Qbound, neg]; push_cast [hND]; omega
    · -- gτ · gσ = 1
      show Qeq (mul (⟨(τ.den : Int) + τ.num, (τ.den - τ.num).toNat⟩ : Q)
        (⟨((neg τ).den : Int) + (neg τ).num, ((neg τ).den - (neg τ).num.toNat)⟩ : Q)) ⟨1, 1⟩
      simp only [Qeq, mul, neg]; push_cast [hqI, hND]
      generalize (τ.den : Int) = d; ring_uor
  · -- τ ≥ 0: the nonneg packager, output bridged to the normalized form
    have hτge : 0 ≤ τ.num := Int.not_lt.mp hneg
    have hid := Rexp_twoArtanh_general_rho τ ρ hτd hτge hτlt hρ0 hρd hρlt hb
    refine Req_trans hid (ofQ_congr (by show 0 < τ.den - τ.num.toNat; omega) hdpos ?_)
    show Qeq (⟨(τ.den : Int) + τ.num, τ.den - τ.num.toNat⟩ : Q)
      (⟨(τ.den : Int) + τ.num, (τ.den - τ.num).toNat⟩ : Q)
    have hpI : (τ.num.toNat : Int) = τ.num := Int.toNat_of_nonneg hτge
    have hqI2 : ((τ.den - τ.num.toNat : Nat) : Int) = (τ.den : Int) - τ.num := by
      rw [Int.ofNat_sub (Nat.le_of_lt hτlt), hpI]
    show ((τ.den : Int) + τ.num) * (((τ.den - τ.num).toNat : Nat) : Int)
        = ((τ.den : Int) + τ.num) * ((τ.den - τ.num.toNat : Nat) : Int)
    rw [hqI, hqI2]

set_option maxHeartbeats 800000 in
/-- **★ signed artanh addition law at a common radius** `2·artanh(wvalR a b) = 2·artanh a + 2·artanh b`
    for **signed** rationals `a, b` with `|a|, |b| < 1` and `1 + ab > 0`, all three `artanh`'s at one
    radius `σ`. The signed analog of `TwoArtanh_add_wval_rho`, using `wvalR` (sign-robust) +
    `Rexp_TwoArtanh_signed_rho` (×3) + `Req_add_of_exp_values_gen` + `wvalR_hg`. -/
theorem TwoArtanh_add_wvalR_rho (a b σ : Q)
    (had : 0 < a.den) (haL : a.num.toNat < a.den) (haL' : (neg a).num.toNat < a.den)
    (hbd : 0 < b.den) (hbL : b.num.toNat < b.den) (hbL' : (neg b).num.toNat < b.den)
    (hσ0 : 0 ≤ σ.num) (hσd : 0 < σ.den) (hσlt : σ.num.toNat < σ.den)
    (hab : 0 < (a.den : Int) * b.den + a.num * b.num)
    (hba : Qle (Qabs a) σ) (hbb : Qle (Qabs b) σ) (hbc : Qle (Qabs (wvalR a b)) σ) :
    Req (TwoArtanhConst (wvalR a b) σ (wvalR_den_pos a b hab) hσ0 hσd hσlt hbc)
        (Radd (TwoArtanhConst a σ had hσ0 hσd hσlt hba)
              (TwoArtanhConst b σ hbd hσ0 hσd hσlt hbb)) := by
  -- Int forms of the `|·| < 1` bounds
  have haLi : a.num < (a.den : Int) := by omega
  have haGi : -(a.den : Int) < a.num := by have := haL'; simp only [neg] at this; omega
  have hbLi : b.num < (b.den : Int) := by omega
  have hbGi : -(b.den : Int) < b.num := by have := hbL'; simp only [neg] at this; omega
  have hWd : ((wvalR a b).den : Int) = (a.den : Int) * b.den + a.num * b.num := by
    rw [wvalR_den]; exact Int.toNat_of_nonneg (Int.le_of_lt hab)
  -- |wvalR a b| < 1: den ± num = (qa∓pa)(qb∓pb) > 0
  have hcnum_lt : (wvalR a b).num < ((wvalR a b).den : Int) := by
    rw [hWd, wvalR_num]
    have hfac : (a.den : Int) * b.den + a.num * b.num - (a.num * (b.den : Int) + b.num * (a.den : Int))
        = ((a.den : Int) - a.num) * ((b.den : Int) - b.num) := by
      generalize (a.den : Int) = qa; generalize (b.den : Int) = qb; ring_uor
    have hpos : 0 < ((a.den : Int) - a.num) * ((b.den : Int) - b.num) :=
      Int.mul_pos (by omega) (by omega)
    omega
  have hcnum_gt : -((wvalR a b).den : Int) < (wvalR a b).num := by
    rw [hWd, wvalR_num]
    have hfac : (a.num * (b.den : Int) + b.num * (a.den : Int)) + ((a.den : Int) * b.den + a.num * b.num)
        = ((a.den : Int) + a.num) * ((b.den : Int) + b.num) := by
      generalize (a.den : Int) = qa; generalize (b.den : Int) = qb; ring_uor
    have hpos : 0 < ((a.den : Int) + a.num) * ((b.den : Int) + b.num) :=
      Int.mul_pos (by omega) (by omega)
    omega
  have hcL : (wvalR a b).num.toNat < (wvalR a b).den := by omega
  have hcL' : (neg (wvalR a b)).num.toNat < (wvalR a b).den := by
    have : ((neg (wvalR a b)).num) = -(wvalR a b).num := rfl
    simp only [this]; omega
  -- the three signed exp identities, via Rexp_TwoArtanh_signed_rho
  have hA := Rexp_TwoArtanh_signed_rho a σ had haL haL' hσ0 hσd hσlt hba
    (by rw [Qabs_neg]; exact hba)
  have hB := Rexp_TwoArtanh_signed_rho b σ hbd hbL hbL' hσ0 hσd hσlt hbb
    (by rw [Qabs_neg]; exact hbb)
  have hC := Rexp_TwoArtanh_signed_rho (wvalR a b) σ (wvalR_den_pos a b hab) hcL hcL'
    hσ0 hσd hσlt hbc (by rw [Qabs_neg]; exact hbc)
  exact Req_add_of_exp_values_gen
    (by show 0 < (a.den - a.num).toNat; omega) (by show 0 < (b.den - b.num).toNat; omega)
    (by show 0 < ((wvalR a b).den - (wvalR a b).num).toNat
        have := hcnum_lt; rw [hWd] at this ⊢; omega)
    hA hB hC (wvalR_hg a b haLi hbLi hab)

/-- `½·(2·x) ≈ x` (local copy; the private one lives in `ArtanhAdd`). -/
private theorem two_half_cancel_s (x : Real) :
    Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x)) x := by
  have hc : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨2, 1⟩ : Q) (by decide))) one :=
    Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 2⟩ : Q) (by decide))
    (ofQ (⟨2, 1⟩ : Q) (by decide)) x)) ?_
  exact Req_trans (Rmul_congr hc (Req_refl x)) (Rone_mul x)

set_option maxHeartbeats 800000 in
/-- **★ signed single-`artanh` addition law at a common radius** (the `×2` stripped):
    `artanh(wvalR a b) = artanh a + artanh b` as `RartanhConst`s, for signed `a, b`. The signed analog
    of `RartanhConst_add_wval_rho` — from `TwoArtanh_add_wvalR_rho` by `Rmul_distrib` + cancelling `2`.
    This single-level form has the clean depths the real-lift diagonal's combination leg needs. -/
theorem RartanhConst_add_wvalR_rho (a b σ : Q)
    (had : 0 < a.den) (haL : a.num.toNat < a.den) (haL' : (neg a).num.toNat < a.den)
    (hbd : 0 < b.den) (hbL : b.num.toNat < b.den) (hbL' : (neg b).num.toNat < b.den)
    (hσ0 : 0 ≤ σ.num) (hσd : 0 < σ.den) (hσlt : σ.num.toNat < σ.den)
    (hab : 0 < (a.den : Int) * b.den + a.num * b.num)
    (hba : Qle (Qabs a) σ) (hbb : Qle (Qabs b) σ) (hbc : Qle (Qabs (wvalR a b)) σ) :
    Req (RartanhConst (wvalR a b) σ (wvalR_den_pos a b hab) hσ0 hσd hσlt hbc)
        (Radd (RartanhConst a σ had hσ0 hσd hσlt hba)
              (RartanhConst b σ hbd hσ0 hσd hσlt hbb)) := by
  have hlaw := TwoArtanh_add_wvalR_rho a b σ had haL haL' hbd hbL hbL' hσ0 hσd hσlt hab hba hbb hbc
  have hmul2 : Req (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (RartanhConst (wvalR a b) σ (wvalR_den_pos a b hab) hσ0 hσd hσlt hbc))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Radd (RartanhConst a σ had hσ0 hσd hσlt hba)
              (RartanhConst b σ hbd hσ0 hσd hσlt hbb))) :=
    Req_trans hlaw (Req_symm (Rmul_distrib _ _ _))
  exact Req_trans (Req_symm (two_half_cancel_s _))
    (Req_trans (Rmul_congr (Req_refl (ofQ (⟨1, 2⟩ : Q) (by decide))) hmul2) (two_half_cancel_s _))

set_option maxHeartbeats 1600000 in
/-- **★ signed real artanh addition diagonal** `artanh s + artanh t = artanh(wvalReal s t)` for **signed**
    real `s, t` (`|s.seq m|, |t.seq m| < 1` both ways). The signed analog of `Rartanh_add_real_via`:
    identical diagonal assembly (arg-variation leg `artSum_wval_argdiff` and the den-positivity
    `wval_inner_pos` are already sign-agnostic over `wvalR`), with the combination leg now the signed
    `RartanhConst_add_wvalR_rho`. Drops the `≥0` hypotheses `hs0`/`ht0`, adds the `−num`-side bounds
    `hslt'`/`htlt'`. -/
theorem Rartanh_add_real_via_signed (s t X1 X2 Y : Real) (σ : Q) (R_Y : Nat → Nat)
    (hσ0 : 0 ≤ σ.num) (hσd : 0 < σ.den) (hσlt : σ.num.toNat < σ.den)
    (hσ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul σ σ))) (hRY : ∀ n, n ≤ R_Y n)
    (hslt : ∀ m, (s.seq m).num.toNat < (s.seq m).den) (htlt : ∀ m, (t.seq m).num.toNat < (t.seq m).den)
    (hslt' : ∀ m, (neg (s.seq m)).num.toNat < (s.seq m).den)
    (htlt' : ∀ m, (neg (t.seq m)).num.toNat < (t.seq m).den)
    (hbs : ∀ m, Qle (Qabs (s.seq m)) σ) (hbt : ∀ m, Qle (Qabs (t.seq m)) σ)
    (hbw : ∀ i, Qle (Qabs (wvalR (s.seq i) (t.seq i))) σ)
    (hX1seq : ∀ j, X1.seq j = artSum (s.seq (Rartanh_R σ j)) (Rartanh_R σ j))
    (hX2seq : ∀ j, X2.seq j = artSum (t.seq (Rartanh_R σ j)) (Rartanh_R σ j))
    (hYseq : ∀ n, Y.seq n = artSum (wvalR (s.seq (R_Y n)) (t.seq (R_Y n))) (Rartanh_R σ n)) :
    Req (Radd X1 X2) Y := by
  have hsd : ∀ m, 0 < (s.seq m).den := fun m => s.den_pos m
  have htd : ∀ m, 0 < (t.seq m).den := fun m => t.den_pos m
  have hσhalf : Qle (mul σ σ) ⟨1, 2⟩ := by
    have h := hσ2; simp only [Qle, Qsub, add, neg, mul] at h ⊢; push_cast at h ⊢; omega
  have hRge : ∀ k, k ≤ Rartanh_R σ k := by
    intro k; unfold Rartanh_R
    have hk : 1 ≤ σ.den * σ.den + 4 * σ.den := Nat.le_trans (by omega) (Nat.le_add_left _ _)
    calc k ≤ 1 * (k + 1) := by omega
      _ ≤ (σ.den * σ.den + 4 * σ.den) * (k + 1) := Nat.mul_le_mul_right _ hk
  refine Req_of_lin_bound (C := 34) ?_
  intro n
  have hae : (Radd X1 X2).seq n
      = add (artSum (s.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))
          (artSum (t.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1))) := by
    show add (X1.seq (2 * n + 1)) (X2.seq (2 * n + 1)) = _; rw [hX1seq, hX2seq]
  rw [hae, hYseq n]
  have hWd : 0 < (artSum (wvalR (s.seq (Rartanh_R σ (2 * n + 1))) (t.seq (Rartanh_R σ (2 * n + 1))))
      (Rartanh_R σ n)).den :=
    artSum_den_pos (wvalR_den_pos _ _ (wval_inner_pos σ _ _ hσd hσ0 (hsd _) (htd _) (hbs _) (hbt _) hσhalf)) _
  have hYd : 0 < (artSum (wvalR (s.seq (R_Y n)) (t.seq (R_Y n))) (Rartanh_R σ n)).den :=
    artSum_den_pos (wvalR_den_pos _ _ (wval_inner_pos σ _ _ hσd hσ0 (hsd _) (htd _) (hbs _) (hbt _) hσhalf)) _
  have hRd : 0 < (add (artSum (s.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))
      (artSum (t.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))).den :=
    add_den_pos (artSum_den_pos (hsd _) _) (artSum_den_pos (htd _) _)
  -- combination leg: the SIGNED rational addition law at the diagonal rationals (already in wvalR form)
  have hcomb : Qle (Qabs (Qsub
        (artSum (wvalR (s.seq (Rartanh_R σ (2 * n + 1))) (t.seq (Rartanh_R σ (2 * n + 1)))) (Rartanh_R σ n))
        (add (artSum (s.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))
          (artSum (t.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))))) (⟨2, n + 1⟩ : Q) :=
    RartanhConst_add_wvalR_rho (s.seq (Rartanh_R σ (2 * n + 1)))
      (t.seq (Rartanh_R σ (2 * n + 1))) σ (hsd _) (hslt _) (hslt' _) (htd _) (htlt _) (htlt' _)
      hσ0 hσd hσlt (wval_inner_pos σ _ _ hσd hσ0 (hsd _) (htd _) (hbs _) (hbt _) hσhalf)
      (hbs _) (hbt _) (hbw _) n
  have hvar := artSum_wval_argdiff σ σ (s.seq (Rartanh_R σ (2 * n + 1)))
    (t.seq (Rartanh_R σ (2 * n + 1))) (s.seq (R_Y n)) (t.seq (R_Y n))
    hσd hσ0 hσhalf hσ0 hσd hσ2 (hsd _) (htd _) (hsd _) (htd _)
    (hbs _) (hbt _) (hbs _) (hbt _) (hbw _) (hbw _) (Rartanh_R σ n)
  have hQbP : Qle (Qbound (Rartanh_R σ (2 * n + 1))) (Qbound n) := by
    show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((Rartanh_R σ (2 * n + 1) + 1 : Nat) : Int)
    have := hRge (2 * n + 1); rw [Int.one_mul, Int.one_mul]
    exact_mod_cast (show n + 1 ≤ Rartanh_R σ (2 * n + 1) + 1 by omega)
  have hQbM : Qle (Qbound (R_Y n)) (Qbound n) := by
    show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((R_Y n + 1 : Nat) : Int)
    have := hRY n; rw [Int.one_mul, Int.one_mul]
    exact_mod_cast (show n + 1 ≤ R_Y n + 1 by omega)
  have hlegB : Qle (Qabs (Qsub
        (artSum (wvalR (s.seq (Rartanh_R σ (2 * n + 1))) (t.seq (Rartanh_R σ (2 * n + 1)))) (Rartanh_R σ n))
        (artSum (wvalR (s.seq (R_Y n)) (t.seq (R_Y n))) (Rartanh_R σ n)))) (⟨32, n + 1⟩ : Q) := by
    refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos
        (Qabs_den_pos (Qsub_den_pos (hsd _) (hsd _))) (Qabs_den_pos (Qsub_den_pos (htd _) (htd _)))))
      hvar ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos
        (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
        (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))))
      (Qmul_le_mul_left (by decide) (Qadd_le_add (s.reg _ _) (t.reg _ _))) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos
        (add_den_pos (Qbound_den_pos n) (Qbound_den_pos n))
        (add_den_pos (Qbound_den_pos n) (Qbound_den_pos n))))
      (Qmul_le_mul_left (by decide)
        (Qadd_le_add (Qadd_le_add hQbP hQbM) (Qadd_le_add hQbP hQbM))) ?_
    apply Qeq_le
    show Qeq (mul ⟨8, 1⟩ (add (add (Qbound n) (Qbound n)) (add (Qbound n) (Qbound n))))
      (⟨32, n + 1⟩ : Q)
    simp only [Qeq, mul, add, Qbound]; push_cast; ring_uor
  have hlegA : Qle (Qabs (Qsub
        (add (artSum (s.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))
          (artSum (t.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1))))
        (artSum (wvalR (s.seq (Rartanh_R σ (2 * n + 1))) (t.seq (Rartanh_R σ (2 * n + 1)))) (Rartanh_R σ n))))
      (⟨2, n + 1⟩ : Q) := by
    rw [Qabs_Qsub_comm]; exact hcomb
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hRd hWd))
      (Qabs_den_pos (Qsub_den_pos hWd hYd)))
    (Qabs_sub_triangle hRd hWd hYd) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)) (Qadd_le_add hlegA hlegB) ?_
  apply Qeq_le; exact Qadd_same_den_loc 2 32 (n + 1)

/-- **`tmap` maps `(0,∞)` into `(−1,1)`** (sign-free): for `q > 0`, both `(tmap q).num.toNat < (tmap q).den`
    and `(−tmap q).num.toNat < (tmap q).den`, i.e. `|tmap q| < 1`. The two-sided analog of
    `tmap_nonneg_lt_one`, for the signed `Rlog_mul` whose `artanh` arguments `tmap(x.seq)` wobble below
    `0` when `x.seq < 1`. -/
theorem tmap_abs_lt_one (q : Q) (hqd : 0 < q.den) (hqn : 0 < q.num) :
    (tmap q).num.toNat < (tmap q).den ∧ (neg (tmap q)).num.toNat < (tmap q).den := by
  have hd0 : (0 : Int) < q.den := by exact_mod_cast hqd
  have hnum : (tmap q).num = (q.num - (q.den : Int)) * q.den := by
    unfold tmap mul Qsub Qinv add neg; push_cast; ring_uor
  have hdenI : ((tmap q).den : Int) = (q.den : Int) * (q.num + q.den) := by
    show (((tmap q).den : Nat) : Int) = _
    unfold tmap mul Qsub Qinv add neg
    push_cast [Int.toNat_of_nonneg (show (0 : Int) ≤ q.num * 1 + 1 * (q.den : Int) by omega)]
    ring_uor
  have hdpos : (0 : Int) < ((tmap q).den : Int) := by
    rw [hdenI]; have := Int.mul_pos hd0 (show (0 : Int) < q.num + q.den by omega); omega
  have hnd : (tmap q).num < ((tmap q).den : Int) := by
    rw [hnum, hdenI]
    have key : (q.den : Int) * (q.num + q.den) - (q.num - q.den) * q.den = 2 * (q.den * q.den) := by
      ring_uor
    have hpos : (0 : Int) < 2 * (q.den * q.den) := by have := Int.mul_pos hd0 hd0; omega
    omega
  have hnd2 : -(tmap q).num < ((tmap q).den : Int) := by
    rw [hnum, hdenI]
    have key : (q.num - q.den) * q.den + (q.den : Int) * (q.num + q.den) = 2 * (q.num * q.den) := by
      ring_uor
    have hpos : (0 : Int) < 2 * (q.num * q.den) := by have := Int.mul_pos hqn hd0; omega
    omega
  refine ⟨by omega, ?_⟩
  have he : (neg (tmap q)).num = -(tmap q).num := rfl
  rw [he]; omega

set_option maxHeartbeats 800000 in
/-- **Log-multiplication wiring, signed** — the signed analog of `Rlog_mul_via`, routing the real
    addition through `Rartanh_add_real_via_signed` (so `tx`, `ty` may dip below `0`). -/
theorem Rlog_mul_via_signed (c tx ty txy : Real) (σ : Q)
    (hσ0 : 0 ≤ σ.num) (hσd : 0 < σ.den) (hσlt : σ.num.toNat < σ.den)
    (hσhalf : Qle (mul σ σ) ⟨1, 2⟩)
    (hslt : ∀ m, (tx.seq m).num.toNat < (tx.seq m).den)
    (htlt : ∀ m, (ty.seq m).num.toNat < (ty.seq m).den)
    (hslt' : ∀ m, (neg (tx.seq m)).num.toNat < (tx.seq m).den)
    (htlt' : ∀ m, (neg (ty.seq m)).num.toNat < (ty.seq m).den)
    (hbx : ∀ m, Qle (Qabs (tx.seq m)) σ) (hby : ∀ m, Qle (Qabs (ty.seq m)) σ)
    (hbw : ∀ i, Qle (Qabs (wvalR (tx.seq i) (ty.seq i))) σ) (hbtxy : ∀ m, Qle (Qabs (txy.seq m)) σ)
    (htmul : Req txy (wvalReal tx ty σ hσd hσ0 hσhalf hbx hby)) :
    Req (Radd (Rmul c (Rartanh tx σ hσ0 hσd hσlt hbx)) (Rmul c (Rartanh ty σ hσ0 hσd hσlt hby)))
        (Rmul c (Rartanh txy σ hσ0 hσd hσlt hbtxy)) := by
  have hσ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul σ σ)) := by
    have h := hσhalf; simp only [Qle, Qsub, add, neg, mul] at h ⊢; push_cast at h ⊢; omega
  have hbW : ∀ n, Qle (Qabs ((wvalReal tx ty σ hσd hσ0 hσhalf hbx hby).seq n)) σ :=
    fun n => hbw (8 * n + 7)
  have hRY : ∀ n, n ≤ 8 * Rartanh_R σ n + 7 := by
    intro n
    have hk : 1 ≤ σ.den * σ.den + 4 * σ.den := Nat.le_trans (by omega) (Nat.le_add_left _ _)
    have : n ≤ Rartanh_R σ n := by
      unfold Rartanh_R
      calc n ≤ 1 * (n + 1) := by omega
        _ ≤ (σ.den * σ.den + 4 * σ.den) * (n + 1) := Nat.mul_le_mul_right _ hk
    omega
  have hadd : Req (Radd (Rartanh tx σ hσ0 hσd hσlt hbx) (Rartanh ty σ hσ0 hσd hσlt hby))
      (Rartanh (wvalReal tx ty σ hσd hσ0 hσhalf hbx hby) σ hσ0 hσd hσlt hbW) :=
    Rartanh_add_real_via_signed tx ty (Rartanh tx σ hσ0 hσd hσlt hbx) (Rartanh ty σ hσ0 hσd hσlt hby)
      (Rartanh (wvalReal tx ty σ hσd hσ0 hσhalf hbx hby) σ hσ0 hσd hσlt hbW)
      σ (fun n => 8 * Rartanh_R σ n + 7) hσ0 hσd hσlt hσ2 hRY hslt htlt hslt' htlt' hbx hby hbw
      (fun _ => rfl) (fun _ => rfl) (fun _ => rfl)
  have hcong : Req (Rartanh (wvalReal tx ty σ hσd hσ0 hσhalf hbx hby) σ hσ0 hσd hσlt hbW)
      (Rartanh txy σ hσ0 hσd hσlt hbtxy) :=
    Rartanh_congr (wvalReal tx ty σ hσd hσ0 hσhalf hbx hby) txy σ hσ0 hσd hσlt hσ2 hbW hbtxy
      (Req_symm htmul)
  exact Rlog_mul_algebra c (Rartanh tx σ hσ0 hσd hσlt hbx) (Rartanh ty σ hσ0 hσd hσlt hby)
    (Rartanh (wvalReal tx ty σ hσd hσ0 hσhalf hbx hby) σ hσ0 hσd hσlt hbW)
    (Rartanh txy σ hσ0 hσd hσlt hbtxy) hadd hcong

set_option maxHeartbeats 1600000 in
/-- **`hbw` bound for `[1/B, B]` arguments** (signed): for positive `a, b` with `a, b ≤ B` and
    `1 ≤ a·B, b·B` (i.e. `1/B ≤ a, b ≤ B`), `|wvalR(tmap a, tmap b)| ≤ ρ_{B²} = tmap(B²)`. The signed
    analog of `wvalR_tmap_seq_bound`: `tmap a, tmap b` may be negative, so `hD > 0` is derived from
    `|tmap| < 1` (`tmap_abs_lt_one`) rather than `tmap ≥ 0`, and the product bound `ab ∈ [1/B², B²]`
    from the two-sided membership. -/
theorem wvalR_tmap_seq_bound_signed (a b B : Q) (had : 0 < a.den) (hbd : 0 < b.den) (hBd : 0 < B.den)
    (hapos : 0 < a.num) (hbpos : 0 < b.num) (haB : Qle a B) (hbB : Qle b B)
    (haBge : Qle (⟨1, 1⟩ : Q) (mul a B)) (hbBge : Qle (⟨1, 1⟩ : Q) (mul b B)) (hBge : Qle (⟨1, 1⟩ : Q) B) :
    Qle (Qabs (wvalR (tmap a) (tmap b)))
        (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q) := by
  have ha0 : 0 ≤ a.num := Int.le_of_lt hapos
  have hb0 : 0 ≤ b.num := Int.le_of_lt hbpos
  have hBn : 0 ≤ B.num := by have := hBge; simp only [Qle] at this; omega
  have ha1' : 0 < (add a ⟨1, 1⟩).num := by
    show 0 < a.num * 1 + 1 * (a.den : Int); have := Int.ofNat_nonneg a.den; omega
  have hb1' : 0 < (add b ⟨1, 1⟩).num := by
    show 0 < b.num * 1 + 1 * (b.den : Int); have := Int.ofNat_nonneg b.den; omega
  have hab1 : 0 < (add (mul a b) ⟨1, 1⟩).num := by
    show 0 < a.num * b.num * 1 + 1 * ((a.den * b.den : Nat) : Int)
    have h1 : 0 < a.num * b.num := Int.mul_pos hapos hbpos
    have h2 : 0 < ((a.den * b.den : Nat) : Int) := by exact_mod_cast Nat.mul_pos had hbd
    omega
  have htad : 0 < (tmap a).den := Qmul_den_pos (Qsub_den_pos had Nat.one_pos) (Qinv_den_pos ha1')
  have htbd : 0 < (tmap b).den := Qmul_den_pos (Qsub_den_pos hbd Nat.one_pos) (Qinv_den_pos hb1')
  -- |tmap a|, |tmap b| < 1
  obtain ⟨hta1, hta2⟩ := tmap_abs_lt_one a had hapos
  obtain ⟨htb1, htb2⟩ := tmap_abs_lt_one b hbd hbpos
  have htaL : (tmap a).num < ((tmap a).den : Int) := by have := hta1; omega
  have htaG : -((tmap a).den : Int) < (tmap a).num := by
    have := hta2; have he : (neg (tmap a)).num = -(tmap a).num := rfl; rw [he] at this; omega
  have htbL : (tmap b).num < ((tmap b).den : Int) := by have := htb1; omega
  have htbG : -((tmap b).den : Int) < (tmap b).num := by
    have := htb2; have he : (neg (tmap b)).num = -(tmap b).num := rfl; rw [he] at this; omega
  have hD : 0 < ((tmap a).den : Int) * (tmap b).den + (tmap a).num * (tmap b).num := by
    have h1 : (0 : Int) < (((tmap a).den : Int) + (tmap a).num) * (((tmap b).den : Int) + (tmap b).num) :=
      Int.mul_pos (by omega) (by omega)
    have h2 : (0 : Int) < (((tmap a).den : Int) - (tmap a).num) * (((tmap b).den : Int) - (tmap b).num) :=
      Int.mul_pos (by omega) (by omega)
    have hsum : (((tmap a).den : Int) + (tmap a).num) * (((tmap b).den : Int) + (tmap b).num)
          + (((tmap a).den : Int) - (tmap a).num) * (((tmap b).den : Int) - (tmap b).num)
        = 2 * (((tmap a).den : Int) * (tmap b).den + (tmap a).num * (tmap b).num) := by
      generalize ((tmap a).den : Int) = da; generalize ((tmap b).den : Int) = db
      generalize (tmap a).num = na; generalize (tmap b).num = nb; ring_uor
    omega
  have hB2d : 0 < (mul B B).den := Qmul_den_pos hBd hBd
  have hB2n : 0 ≤ (mul B B).num := Int.mul_nonneg hBn hBn
  have hMab1 : 0 < (add (mul B B) ⟨1, 1⟩).num := by
    show 0 < B.num * B.num * 1 + 1 * ((B.den * B.den : Nat) : Int)
    have h2 : 0 < ((B.den * B.den : Nat) : Int) := by exact_mod_cast Nat.mul_pos hBd hBd
    have h1 : 0 ≤ B.num * B.num := Int.mul_nonneg hBn hBn; omega
  have habM : Qle (mul a b) (mul B B) := Qmul_le_mul had hBd hbd ha0 hb0 haB hbB
  have habMge : Qle (⟨1, 1⟩ : Q) (mul (mul a b) (mul B B)) := by
    -- (a·b)·(B·B) = (a·B)·(b·B) ≥ 1·1
    refine Qle_trans (by decide) (Qeq_le (by decide : Qeq (⟨1, 1⟩ : Q) (mul ⟨1, 1⟩ ⟨1, 1⟩))) ?_
    refine Qle_trans (Qmul_den_pos (Qmul_den_pos had hBd) (Qmul_den_pos hbd hBd))
      (Qmul_le_mul (by decide) (Qmul_den_pos had hBd) (by decide) (by decide) (by decide)
        haBge hbBge) ?_
    apply Qeq_le; simp only [Qeq, mul]; push_cast; ring_uor
  exact Qle_trans (Qmul_den_pos (Qsub_den_pos hB2d Nat.one_pos) (Qinv_den_pos hMab1))
    (wvalR_tmap_bound a b B B had hbd ha1' hb1' hab1 hD hB2d hMab1 habM habMge)
    (Qeq_le (tmap_M_eq hB2d hB2n))

set_option maxHeartbeats 1600000 in
/-- **★ Real log-multiplicativity, signed** `Rlog(x·y) = Rlog x + Rlog y` for `x, y` presented in the
    **symmetric band** `[1/B, B]` pointwise (`x.seq, y.seq > 0`, `≤ B`, `≥ 1/B`) — *not* requiring
    `x.seq, y.seq ≥ 1`. The signed analog of `Rlog_mul`: identical radius bookkeeping, but the
    `artanh` arguments `tmap(x.seq)` may be negative, so it routes through `Rlog_mul_via_signed` with
    `tmap_abs_lt_one` (two-sided) and `wvalR_tmap_seq_bound_signed`. Extends real log-multiplicativity
    to moduli on **either side** of 1 — the realistic Hadamard regime. -/
theorem Rlog_mul_signed (x y : Real) (B : Q) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxpos : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B)
    (hxloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) B))
    (hypos : ∀ n, 0 < (y.seq n).num) (hyhiB : ∀ n, Qle (y.seq n) B)
    (hyloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (y.seq n) B))
    (hB2d : 0 < (mul B B).den) (hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B))
    (hxypos : ∀ n, 0 < ((Rmul x y).seq n).num) (hxyhi : ∀ n, Qle ((Rmul x y).seq n) (mul B B))
    (hxylo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul x y).seq n) (mul B B)))
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
              ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hσhalf : Qle (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
              ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩) ⟨1, 2⟩) :
    Req (Radd (Rlog x B hBd hBge hxpos hxhiB hxloB) (Rlog y B hBd hBge hypos hyhiB hyloB))
        (Rlog (Rmul x y) (mul B B) hB2d hB2ge hxypos hxyhi hxylo) := by
  obtain ⟨hBn, hB1, hρ0, hρd, hρlt, hρ1⟩ := Rlog_radius_facts B hBd hBge
  obtain ⟨hB2n, hB21, hσ0, hσd, hσlt, hσ1⟩ := Rlog_radius_facts (mul B B) hB2d hB2ge
  have hden_x : ∀ n, 0 < (Rlog_seq x n).den := fun n => Qmul_den_pos
    (Qsub_den_pos (x.den_pos _) Nat.one_pos) (Qinv_den_pos (by
      have := hxpos (Rlog_R n); have h := Int.ofNat_nonneg (x.seq (Rlog_R n)).den
      show 0 < (x.seq (Rlog_R n)).num * 1 + 1 * ((x.seq (Rlog_R n)).den : Int); omega))
  have hden_y : ∀ n, 0 < (Rlog_seq y n).den := fun n => Qmul_den_pos
    (Qsub_den_pos (y.den_pos _) Nat.one_pos) (Qinv_den_pos (by
      have := hypos (Rlog_R n); have h := Int.ofNat_nonneg (y.seq (Rlog_R n)).den
      show 0 < (y.seq (Rlog_R n)).num * 1 + 1 * ((y.seq (Rlog_R n)).den : Int); omega))
  have hden_xy : ∀ n, 0 < (Rlog_seq (Rmul x y) n).den := fun n => Qmul_den_pos
    (Qsub_den_pos ((Rmul x y).den_pos _) Nat.one_pos) (Qinv_den_pos (by
      have := hxypos (Rlog_R n); have h := Int.ofNat_nonneg ((Rmul x y).seq (Rlog_R n)).den
      show 0 < ((Rmul x y).seq (Rlog_R n)).num * 1 + 1 * (((Rmul x y).seq (Rlog_R n)).den : Int); omega))
  have hbtρx := Rlog_tbound x B hBd hBn hB1 hxhiB hxloB hxpos
  have hbtρy := Rlog_tbound y B hBd hBn hB1 hyhiB hyloB hypos
  have hbtσxy := Rlog_tbound (Rmul x y) (mul B B) hB2d hB2n hB21 hxyhi hxylo hxypos
  have hbxσ : ∀ k, Qle (Qabs (tmap (x.seq k))) (⟨(mul B B).num - ((mul B B).den : Int),
      (mul B B).num.toNat + (mul B B).den⟩ : Q) := fun k => Qle_trans hρd (hbtρx k) hρσ
  have hbyσ : ∀ k, Qle (Qabs (tmap (y.seq k))) (⟨(mul B B).num - ((mul B B).den : Int),
      (mul B B).num.toNat + (mul B B).den⟩ : Q) := fun k => Qle_trans hρd (hbtρy k) hρσ
  rw [Rlog_eq_Rmul x B hBd hBge hxpos hxhiB hxloB hden_x hρ0 hρd hρlt (fun n => hbtρx (Rlog_R n)),
    Rlog_eq_Rmul y B hBd hBge hypos hyhiB hyloB hden_y hρ0 hρd hρlt (fun n => hbtρy (Rlog_R n)),
    Rlog_eq_Rmul (Rmul x y) (mul B B) hB2d hB2ge hxypos hxyhi hxylo hden_xy hσ0 hσd hσlt
      (fun n => hbtσxy (Rlog_R n))]
  have hradx : Req (Rartanh ⟨Rlog_seq x, Rlog_regular x hxpos, hden_x⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ hρ0 hρd hρlt (fun n => hbtρx (Rlog_R n)))
      (Rartanh ⟨Rlog_seq x, Rlog_regular x hxpos, hden_x⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        hσ0 hσd hσlt (fun n => hbxσ (Rlog_R n))) :=
    Rartanh_radius_indep ⟨Rlog_seq x, Rlog_regular x hxpos, hden_x⟩ _ _
      ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
      ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
      ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ hρd hσd hρ0 hρd hρlt hρ2
      (fun n => hbtρx (Rlog_R n)) (fun _ => rfl) (fun _ => rfl)
  have hrady : Req (Rartanh ⟨Rlog_seq y, Rlog_regular y hypos, hden_y⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ hρ0 hρd hρlt (fun n => hbtρy (Rlog_R n)))
      (Rartanh ⟨Rlog_seq y, Rlog_regular y hypos, hden_y⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        hσ0 hσd hσlt (fun n => hbyσ (Rlog_R n))) :=
    Rartanh_radius_indep ⟨Rlog_seq y, Rlog_regular y hypos, hden_y⟩ _ _
      ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
      ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
      ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ hρd hσd hρ0 hρd hρlt hρ2
      (fun n => hbtρy (Rlog_R n)) (fun _ => rfl) (fun _ => rfl)
  have hvia := Rlog_mul_via_signed (ofQ (⟨2, 1⟩ : Q) (by decide))
    ⟨Rlog_seq x, Rlog_regular x hxpos, hden_x⟩ ⟨Rlog_seq y, Rlog_regular y hypos, hden_y⟩
    ⟨Rlog_seq (Rmul x y), Rlog_regular (Rmul x y) hxypos, hden_xy⟩
    ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
    hσ0 hσd hσlt hσhalf
    (fun m => (tmap_abs_lt_one (x.seq (Rlog_R m)) (x.den_pos _) (hxpos (Rlog_R m))).1)
    (fun m => (tmap_abs_lt_one (y.seq (Rlog_R m)) (y.den_pos _) (hypos (Rlog_R m))).1)
    (fun m => (tmap_abs_lt_one (x.seq (Rlog_R m)) (x.den_pos _) (hxpos (Rlog_R m))).2)
    (fun m => (tmap_abs_lt_one (y.seq (Rlog_R m)) (y.den_pos _) (hypos (Rlog_R m))).2)
    (fun m => hbxσ (Rlog_R m)) (fun m => hbyσ (Rlog_R m))
    (fun i => wvalR_tmap_seq_bound_signed (x.seq (Rlog_R i)) (y.seq (Rlog_R i)) B (x.den_pos _)
      (y.den_pos _) hBd (hxpos (Rlog_R i)) (hypos (Rlog_R i)) (hxhiB (Rlog_R i)) (hyhiB (Rlog_R i))
      (hxloB (Rlog_R i)) (hyloB (Rlog_R i)) hBge)
    (fun m => hbtσxy (Rlog_R m))
    (tmul_wvalReal_via x y ⟨Rlog_seq (Rmul x y), Rlog_regular (Rmul x y) hxypos, hden_xy⟩
      (wvalReal ⟨Rlog_seq x, Rlog_regular x hxpos, hden_x⟩ ⟨Rlog_seq y, Rlog_regular y hypos, hden_y⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        hσd hσ0 hσhalf (fun m => hbxσ (Rlog_R m)) (fun m => hbyσ (Rlog_R m)))
      ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
      hσd hσ0 hσhalf hxpos hypos hbxσ hbyσ (fun _ => rfl) (fun _ => rfl))
  exact Req_trans
    (Radd_congr (Rmul_congr (Req_refl _) hradx) (Rmul_congr (Req_refl _) hrady)) hvia

set_option maxHeartbeats 1600000 in
/-- **★ `RlogPos` multiplicativity, signed** (symmetric band): `log(xy) = log x + log y` for positive
    reals `x, y` presented in `[1/B, B]` — the signed analog of `RlogPos_mul`, bridging each `RlogPos`
    to its presented-radius `Rlog` (`RlogPos_eq_Rlog`, already sign-agnostic) and combining via the
    signed `Rlog_mul_signed`. Drops the `≥1` hypotheses. -/
theorem RlogPos_mul_signed (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky))
    (kxy : Nat) (hxy : Qlt (Qbound kxy) ((Rmul x y).seq kxy))
    (B : Q) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxposB : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B)
    (hxloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) B))
    (hyposB : ∀ n, 0 < (y.seq n).num) (hyhiB : ∀ n, Qle (y.seq n) B)
    (hyloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (y.seq n) B))
    (hB2d : 0 < (mul B B).den) (hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B))
    (hxypos : ∀ n, 0 < ((Rmul x y).seq n).num) (hxyhi : ∀ n, Qle ((Rmul x y).seq n) (mul B B))
    (hxylo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul x y).seq n) (mul B B)))
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
              ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hσhalf : Qle (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
              ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩) ⟨1, 2⟩)
    (hσ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩ ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩))) :
    Req (RlogPos (Rmul x y) kxy hxy) (Radd (RlogPos x kx hx) (RlogPos y ky hy)) := by
  have bx := RlogPos_eq_Rlog x kx hx B hBd hBge hxposB hxhiB hxloB hρ2
  have by' := RlogPos_eq_Rlog y ky hy B hBd hBge hyposB hyhiB hyloB hρ2
  have bxy := RlogPos_eq_Rlog (Rmul x y) kxy hxy (mul B B) hB2d hB2ge hxypos hxyhi hxylo hσ2
  have hmul := Rlog_mul_signed x y B hBd hBge hxposB hxhiB hxloB hyposB hyhiB hyloB
    hB2d hB2ge hxypos hxyhi hxylo hρ2 hρσ hσhalf
  exact Req_trans bxy (Req_trans (Req_symm hmul) (Radd_congr (Req_symm bx) (Req_symm by')))

/-- Pure-`Int` core of the lower-bound positivity witness: `d < p·(qn+1)` from `d·qd ≤ p·qn`
    (`d, p > 0`, `qd ≥ 1`). -/
private theorem pos_wit_poly (p d qn qd : Int) (hd : 0 < d) (hp : 0 < p) (hqd1 : 1 ≤ qd)
    (hkey : d * qd ≤ p * qn) : d < p * (qn + 1) := by
  have h1 : 0 ≤ d * (qd - 1) := Int.mul_nonneg (Int.le_of_lt hd) (by omega)
  have h1d : d * (qd - 1) = d * qd - d := by ring_uor
  have h2 : p * (qn + 1) = p * qn + p := by ring_uor
  omega

/-- **Positivity witness from a lower bound**: if `x.seq n · M ≥ 1` for all `n` (`x ≥ 1/M`, `M > 0`),
    then `x` has a `RlogPos` positivity witness at index `M.num.toNat` — even when `x < 1`. Lets the
    symmetric-band assembly furnish the witness for `Rmul (cnormSq z) (cnormSq w)` when the squared
    moduli dip below 1. -/
theorem pos_witness_of_mulM_ge (x : Real) (M : Q) (hMpos : 0 < M.num) (hMd : 0 < M.den)
    (hlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) M)) :
    Qlt (Qbound M.num.toNat) (x.seq M.num.toNat) := by
  have hd1 : ((M.num.toNat : Nat) : Int) = M.num := Int.toNat_of_nonneg (Int.le_of_lt hMpos)
  have hdpos : 0 < (x.seq M.num.toNat).den := x.den_pos _
  have hkey : (x.seq M.num.toNat).den * (M.den : Int) ≤ (x.seq M.num.toNat).num * M.num := by
    have hk := hlo M.num.toNat
    simp only [Qle, mul] at hk; push_cast at hk; omega
  have hMd1 : (1 : Int) ≤ M.den := by exact_mod_cast hMd
  have hnumpos : 0 < (x.seq M.num.toNat).num := by
    have hde : (1 : Int) ≤ (x.seq M.num.toNat).den := by exact_mod_cast hdpos
    have h0 : (0 : Int) < (x.seq M.num.toNat).den * M.den := by
      have := Int.mul_pos (by exact_mod_cast hdpos : (0:Int) < (x.seq M.num.toNat).den)
        (by exact_mod_cast hMd : (0:Int) < (M.den:Int)); omega
    have h1 : (0 : Int) < (x.seq M.num.toNat).num * M.num := by omega
    rcases Int.lt_trichotomy (x.seq M.num.toNat).num 0 with h | h | h
    · exfalso; have := Int.mul_neg_of_neg_of_pos h hMpos; omega
    · exfalso; rw [h] at h1; simp at h1
    · exact h
  show Qlt (Qbound M.num.toNat) (x.seq M.num.toNat)
  simp only [Qlt, Qbound]; push_cast [hd1]
  have hp := pos_wit_poly (x.seq M.num.toNat).num (x.seq M.num.toNat).den M.num (M.den : Int)
    (by exact_mod_cast hdpos) hnumpos hMd1 hkey
  omega

set_option maxHeartbeats 1600000 in
/-- **The `Clog_add` modulus seam, discharged (symmetric band)**: `log|zw|² = log|z|² + log|w|²` for
    squared moduli in `[1/B, B]` (moduli on **either** side of 1). The signed analog of
    `RlogPos_cnormSq_mul`, via `cnormSq_mul` + `RlogPos_congr` + `RlogPos_mul_signed`; the witness for
    `Rmul (cnormSq z) (cnormSq w)` comes from the lower bound (`pos_witness_of_mulM_ge`) since the
    product may be `< 1`. -/
theorem RlogPos_cnormSq_mul_signed (z w : Complex)
    (knz : Nat) (hknz : Qlt (Qbound knz) ((cnormSq z).seq knz))
    (knw : Nat) (hknw : Qlt (Qbound knw) ((cnormSq w).seq knw))
    (knzw : Nat) (hknzw : Qlt (Qbound knzw) ((cnormSq (Cmul z w)).seq knzw))
    (B : Q) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hXpos : ∀ n, 0 < ((cnormSq z).seq n).num) (hXhi : ∀ n, Qle ((cnormSq z).seq n) B)
    (hXlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq z).seq n) B))
    (hYpos : ∀ n, 0 < ((cnormSq w).seq n).num) (hYhi : ∀ n, Qle ((cnormSq w).seq n) B)
    (hYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq w).seq n) B))
    (hB2d : 0 < (mul B B).den) (hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B))
    (hXYpos : ∀ n, 0 < ((Rmul (cnormSq z) (cnormSq w)).seq n).num)
    (hXYhi : ∀ n, Qle ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B))
    (hXYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B)))
    (hZWpos : ∀ n, 0 < ((cnormSq (Cmul z w)).seq n).num)
    (hZWhi : ∀ n, Qle ((cnormSq (Cmul z w)).seq n) (mul B B))
    (hZWlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq (Cmul z w)).seq n) (mul B B)))
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
              ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hσhalf : Qle (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
              ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩) ⟨1, 2⟩)
    (hσ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩ ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩))) :
    Req (RlogPos (cnormSq (Cmul z w)) knzw hknzw)
        (Radd (RlogPos (cnormSq z) knz hknz) (RlogPos (cnormSq w) knw hknw)) := by
  have hM2pos : 0 < (mul B B).num := by have := hB2ge; simp only [Qle] at this; omega
  have hxy' : Qlt (Qbound (mul B B).num.toNat)
      ((Rmul (cnormSq z) (cnormSq w)).seq (mul B B).num.toNat) :=
    pos_witness_of_mulM_ge (Rmul (cnormSq z) (cnormSq w)) (mul B B) hM2pos hB2d hXYlo
  refine Req_trans ?_ (RlogPos_mul_signed (cnormSq z) (cnormSq w) knz hknz knw hknw _ hxy'
    B hBd hBge hXpos hXhi hXlo hYpos hYhi hYlo hB2d hB2ge hXYpos hXYhi hXYlo hρ2 hρσ hσhalf hσ2)
  exact RlogPos_congr (cnormSq (Cmul z w)) (Rmul (cnormSq z) (cnormSq w)) knzw hknzw _ hxy'
    (mul B B) hB2d hB2ge hZWpos hZWhi hZWlo hXYpos hXYhi hXYlo hσ2 (cnormSq_mul z w)

set_option maxHeartbeats 1600000 in
/-- **★★ unconditional complex logarithm additivity (symmetric band)** `Clog(zw) = Clog z + Clog w`,
    with the modulus seam `hmod` discharged for squared moduli in `[1/B, B]` (moduli on either side of
    1 — the realistic Hadamard regime). The symmetric-band analog of `Clog_add_bounded`, supplying
    `hmod` via `RlogPos_cnormSq_mul_signed`. -/
theorem Clog_add_signed (z w : Complex)
    (knz : Nat) (hknz : Qlt (Qbound knz) ((cnormSq z).seq knz))
    (knw : Nat) (hknw : Qlt (Qbound knw) ((cnormSq w).seq knw))
    (knzw : Nat) (hknzw : Qlt (Qbound knzw) ((cnormSq (Cmul z w)).seq knzw))
    (kz : Nat) (hkz : Qlt (Qbound kz) (z.re.seq kz))
    (kw : Nat) (hkw : Qlt (Qbound kw) (w.re.seq kw))
    (kzw : Nat) (hzw : Qlt (Qbound kzw) ((Cmul z w).re.seq kzw))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2arg : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩)
    (hbs : ∀ n, Qle (Qabs ((Rdiv z.im z.re kz hkz).seq n)) ρ)
    (hbt : ∀ n, Qle (Qabs ((Rdiv w.im w.re kw hkw).seq n)) ρ)
    (hbzw : ∀ n, Qle (Qabs ((Rdiv (Cmul z w).im (Cmul z w).re kzw hzw).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs (vval ((Rdiv z.im z.re kz hkz).seq n)
      ((Rdiv w.im w.re kw hkw).seq n))) ρ)
    (B : Q) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hXpos : ∀ n, 0 < ((cnormSq z).seq n).num) (hXhi : ∀ n, Qle ((cnormSq z).seq n) B)
    (hXlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq z).seq n) B))
    (hYpos : ∀ n, 0 < ((cnormSq w).seq n).num) (hYhi : ∀ n, Qle ((cnormSq w).seq n) B)
    (hYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq w).seq n) B))
    (hB2d : 0 < (mul B B).den) (hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B))
    (hXYpos : ∀ n, 0 < ((Rmul (cnormSq z) (cnormSq w)).seq n).num)
    (hXYhi : ∀ n, Qle ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B))
    (hXYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B)))
    (hZWpos : ∀ n, 0 < ((cnormSq (Cmul z w)).seq n).num)
    (hZWhi : ∀ n, Qle ((cnormSq (Cmul z w)).seq n) (mul B B))
    (hZWlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq (Cmul z w)).seq n) (mul B B)))
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
              ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hσhalf : Qle (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
              ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩) ⟨1, 2⟩)
    (hσ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩ ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩))) :
    Ceq (Clog (Cmul z w) knzw hknzw kzw hzw ρ hρ0 hρd hlt hbzw)
        (Cadd (Clog z knz hknz kz hkz ρ hρ0 hρd hlt hbs)
              (Clog w knw hknw kw hkw ρ hρ0 hρd hlt hbt)) :=
  Clog_add z w knz hknz knw hknw knzw hknzw kz hkz kw hkw kzw hzw ρ hρ0 hρd hlt hlt16 h2ρ hhalf hρ4
    hρ2arg hρ8 hρ1 hbs hbt hbzw hbw
    (RlogPos_cnormSq_mul_signed z w knz hknz knw hknw knzw hknzw B hBd hBge
      hXpos hXhi hXlo hYpos hYhi hYlo hB2d hB2ge
      hXYpos hXYhi hXYlo hZWpos hZWhi hZWlo hρ2 hρσ hσhalf hσ2)

end UOR.Bridge.F1Square.Analysis
