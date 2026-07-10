/-
# `tan(arctan t) = t` and the `cos(arctan t)` closed form

Building on the value-level identity `sin(arctan t) = t·cos(arctan t)`
(`Rsin_arctan_value_eq`, `ArctanODE.lean`) and the genuine Pythagorean identity
`cos² + sin² = 1` (`Rcos_sq_add_sin_sq`, `CosSinAdd.lean`):

* `Rcos_arctan_sq` — `cos²(arctan t)·(1+t²) = 1`, the closed form `cos²(arctan t) = 1/(1+t²)`.
  Substituting `sin = t·cos` into Pythagoras collapses to `cos²·(1+t²) = 1`. Since the right side
  is `1 > 0`, this is the gateway to `cos(arctan t) ≠ 0` and hence `tan(arctan t) = t`.

All RH-*independent* (the `arctan`-addition substrate feeding `arg(zw) = arg z + arg w`); crux
fields stay `none`, RH open.
-/
import F1Square.Analysis.ArctanODE
import F1Square.Analysis.RMulNF
import F1Square.Analysis.ArtanhAdd
import F1Square.Analysis.GammaTwoBracket
import F1Square.Analysis.RealDiv

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 1000000 in
/-- **`cos²(arctan t)·(1+t²) = 1`** (`|t| ≤ ρ < 1/16`), i.e. the closed form `cos²(arctan t) =
    1/(1+t²)`. Substitute `sin(arctan t) = t·cos(arctan t)` (`Rsin_arctan_value_eq`) into the
    Pythagorean identity `cos² + sin² = 1` (`Rcos_sq_add_sin_sq`): `cos² + t²·cos² = cos²·(1+t²) = 1`.
    The right side `1 > 0` gives `cos(arctan t) ≠ 0`, the gateway to `tan(arctan t) = t`. -/
theorem Rcos_arctan_sq (t₀ ρ : Q) (htd : 0 < t₀.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (htρ : Qle (Qabs t₀) ρ)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩) :
    Req (Rmul (Rmul (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)) (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)))
          (Radd one (Rmul (ofQ t₀ htd) (ofQ t₀ htd)))) one := by
  have hval := Rsin_arctan_value_eq t₀ ρ htd hρ0 hρd hlt htρ hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1
  have hpyth := Rcos_sq_add_sin_sq (Rarctan t₀ htd hρ0 hρd hlt htρ)
  -- t²·cos² = sin²  (substitute sin = t·cos and reassociate)
  have hT2 : Req (Rmul (Rmul (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))
        (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))) (Rmul (ofQ t₀ htd) (ofQ t₀ htd)))
      (Rmul (Rsin (Rarctan t₀ htd hρ0 hρd hlt htρ)) (Rsin (Rarctan t₀ htd hρ0 hρd hlt htρ))) := by
    refine Req_trans (Rmul_comm (Rmul (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))
      (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))) (Rmul (ofQ t₀ htd) (ofQ t₀ htd))) ?_
    refine Req_trans (Req_symm (prod_sq_reassoc (ofQ t₀ htd)
      (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)))) ?_
    exact Req_symm (Rmul_congr hval hval)
  -- cos²·(1+t²) = cos²·1 + cos²·t² = cos² + sin² = 1
  refine Req_trans (Rmul_distrib (Rmul (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))
    (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))) one (Rmul (ofQ t₀ htd) (ofQ t₀ htd))) ?_
  refine Req_trans (Radd_congr (Rmul_one (Rmul (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))
    (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)))) hT2) ?_
  exact hpyth

/-- **`cos(arctan t)` has the explicit inverse `cos(arctan t)·(1+t²)`** (no `sqrt`, no apartness
    witness): `cos · (cos·(1+t²)) = 1`. Reassociates `Rcos_arctan_sq` (`cos²·(1+t²)=1`). -/
theorem Rcos_arctan_inv (t₀ ρ : Q) (htd : 0 < t₀.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (htρ : Qle (Qabs t₀) ρ)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩) :
    Req (Rmul (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))
          (Rmul (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)) (Radd one (Rmul (ofQ t₀ htd) (ofQ t₀ htd)))))
      one :=
  Req_trans (Req_symm (Rmul_assoc (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))
      (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)) (Radd one (Rmul (ofQ t₀ htd) (ofQ t₀ htd)))))
    (Rcos_arctan_sq t₀ ρ htd hρ0 hρd hlt htρ hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1)

/-- **★ `tan(arctan t) = t` (value level, division-free)**: `Rsin(arctan t) · (cos(arctan t)·(1+t²))
    = t` for `|t| ≤ ρ < 1/16`. Using the explicit inverse `cos(arctan t)·(1+t²)` of `cos(arctan t)`
    (`Rcos_arctan_inv`), `tan(arctan t) = sin·cos⁻¹ = (t·cos)·(cos·(1+t²)) = t·(cos²·(1+t²)) = t`.
    The `sqrt`-free, `Rinv`-free value form of `tan∘arctan = id` — the arctan-addition substrate. -/
theorem Rtan_arctan_eq (t₀ ρ : Q) (htd : 0 < t₀.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (htρ : Qle (Qabs t₀) ρ)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩) :
    Req (Rmul (Rsin (Rarctan t₀ htd hρ0 hρd hlt htρ))
          (Rmul (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)) (Radd one (Rmul (ofQ t₀ htd) (ofQ t₀ htd)))))
      (ofQ t₀ htd) := by
  have hval := Rsin_arctan_value_eq t₀ ρ htd hρ0 hρd hlt htρ hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1
  refine Req_trans (Rmul_congr hval (Req_refl _)) ?_
  refine Req_trans (Rmul_assoc (ofQ t₀ htd) (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))
    (Rmul (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)) (Radd one (Rmul (ofQ t₀ htd) (ofQ t₀ htd))))) ?_
  refine Req_trans (Rmul_congr (Req_refl _)
    (Rcos_arctan_inv t₀ ρ htd hρ0 hρd hlt htρ hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1)) ?_
  exact Rmul_one (ofQ t₀ htd)

-- ===========================================================================
-- Angle-addition given the tangent: sin(A+B), cos(A+B) for sin = (tan)·cos.
-- ===========================================================================

/-- `x·(y·z) ≈ y·(x·z)` (left-commutativity of `Rmul`). -/
theorem Rmul_left_comm_loc (x y z : Real) : Req (Rmul x (Rmul y z)) (Rmul y (Rmul x z)) :=
  Req_trans (Req_symm (Rmul_assoc x y z))
    (Req_trans (Rmul_congr (Rmul_comm x y) (Req_refl z)) (Rmul_assoc y x z))

/-- `1·x ≈ x`. -/
theorem Rone_mul_loc (x : Real) : Req (Rmul one x) x := Req_trans (Rmul_comm one x) (Rmul_one x)

/-- `(a·c)·(b·d) ≈ (a·b)·(c·d)` (regroup the four factors), via the `RprodL` product normal form. -/
theorem Rmul_pair_regroup (a b c d : Real) :
    Req (Rmul (Rmul a c) (Rmul b d)) (Rmul (Rmul a b) (Rmul c d)) :=
  Req_trans (Rmul_pair_eq_RprodL4 a c b d)
    (Req_trans (RprodL_perm (List.Perm.cons a (List.Perm.swap b c [d])))
      (Req_symm (Rmul_pair_eq_RprodL4 a b c d)))

/-- **sin angle-addition given the tangent**: if `sin A = a·cos A` and `sin B = b·cos B` then
    `sin(A+B) = (a+b)·(cos A·cos B)`. (`Rsin_add` + substitution + reassociation/distribution.) -/
theorem Rsin_add_of_tan {A B : Real} {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den)
    (hA : Req (Rsin A) (Rmul (ofQ a ha) (Rcos A))) (hB : Req (Rsin B) (Rmul (ofQ b hb) (Rcos B))) :
    Req (Rsin (Radd A B)) (Rmul (Radd (ofQ a ha) (ofQ b hb)) (Rmul (Rcos A) (Rcos B))) := by
  refine Req_trans (Rsin_add A B) ?_
  refine Req_trans (Radd_congr (Rmul_congr (Req_refl _) hB) (Rmul_congr hA (Req_refl _))) ?_
  refine Req_trans (Radd_congr (Rmul_left_comm_loc (Rcos A) (ofQ b hb) (Rcos B))
    (Rmul_assoc (ofQ a ha) (Rcos A) (Rcos B))) ?_
  refine Req_trans (Req_symm (Rmul_distrib_right (ofQ b hb) (ofQ a ha) (Rmul (Rcos A) (Rcos B)))) ?_
  exact Rmul_congr (Radd_comm (ofQ b hb) (ofQ a ha)) (Req_refl _)

/-- **cos angle-addition given the tangent**: if `sin A = a·cos A` and `sin B = b·cos B` then
    `cos(A+B) = (1−a·b)·(cos A·cos B)`. (`Rcos_add` + substitution + the four-factor regroup.) -/
theorem Rcos_add_of_tan {A B : Real} {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den)
    (hA : Req (Rsin A) (Rmul (ofQ a ha) (Rcos A))) (hB : Req (Rsin B) (Rmul (ofQ b hb) (Rcos B))) :
    Req (Rcos (Radd A B))
      (Rmul (Rsub one (Rmul (ofQ a ha) (ofQ b hb))) (Rmul (Rcos A) (Rcos B))) := by
  refine Req_trans (Rcos_add A B) ?_
  refine Req_trans (Rsub_congr (Req_refl _) (Rmul_congr hA hB)) ?_
  refine Req_trans (Rsub_congr (Req_symm (Rone_mul_loc (Rmul (Rcos A) (Rcos B))))
    (Rmul_pair_regroup (ofQ a ha) (ofQ b hb) (Rcos A) (Rcos B))) ?_
  exact Req_symm (Rmul_sub_distrib_right one (Rmul (ofQ a ha) (ofQ b hb)) (Rmul (Rcos A) (Rcos B)))

-- ===========================================================================
-- arctan addition: A+B has tangent vval a b = (a+b)/(1−ab).
-- ===========================================================================

/-- The pure-`Int` core of the `vval` relation (dodges `ring_uor`'s `Nat.cast`-atom rejection). -/
theorem vval_rel_poly (pa qa pb qb : Int) :
    (pa * qb + pb * qa) * ((qa * qb - pa * pb) * (1 * (qa * qb)))
      = (pa * qb + pb * qa) * (1 * (qa * qb) + -(pa * pb) * 1) * (qa * qb) := by
  ring_uor

/-- **`vval` defining relation**: `(a+b) = vval a b · (1 − a·b)` (division-free, given `1−ab > 0`).
    The `tan`-addition identity in rational form: `vval = (a+b)/(1−ab)`. -/
theorem vval_rel (a b : Q) (hpos : 0 < (a.den : Int) * b.den - a.num * b.num) :
    Qeq (add a b) (mul (vval a b) (Qsub ⟨1, 1⟩ (mul a b))) := by
  have hD : (((((a.den : Int) * b.den - a.num * b.num).toNat) : Nat) : Int)
      = (a.den : Int) * b.den - a.num * b.num := Int.toNat_of_nonneg (Int.le_of_lt hpos)
  simp only [Qeq, add, mul, Qsub, neg, vval]
  push_cast [hD]
  exact vval_rel_poly a.num (a.den : Int) b.num (b.den : Int)

/-- **`a + b = vval a b · (1 − a·b)` at the real level** (via `ofQ` homomorphisms + `vval_rel`). The
    coefficient identity behind `tan(A+B) = vval a b`. -/
theorem vval_coeff_eq (a b : Q) (ha : 0 < a.den) (hb : 0 < b.den)
    (hpos : 0 < (a.den : Int) * b.den - a.num * b.num) :
    Req (Radd (ofQ a ha) (ofQ b hb))
      (Rmul (ofQ (vval a b) (vval_den_pos a b hpos)) (Rsub one (Rmul (ofQ a ha) (ofQ b hb)))) := by
  have hLHS : Req (Radd (ofQ a ha) (ofQ b hb))
      (ofQ (mul (vval a b) (Qsub ⟨1, 1⟩ (mul a b)))
        (Qmul_den_pos (vval_den_pos a b hpos) (Qsub_den_pos (by decide) (Qmul_den_pos ha hb)))) :=
    Req_trans (Radd_ofQ_ofQ ha hb)
      (ofQ_congr (add_den_pos ha hb) _ (vval_rel a b hpos))
  have hRHS : Req (Rmul (ofQ (vval a b) (vval_den_pos a b hpos)) (Rsub one (Rmul (ofQ a ha) (ofQ b hb))))
      (ofQ (mul (vval a b) (Qsub ⟨1, 1⟩ (mul a b)))
        (Qmul_den_pos (vval_den_pos a b hpos) (Qsub_den_pos (by decide) (Qmul_den_pos ha hb)))) := by
    refine Req_trans (Rmul_congr (Req_refl _)
      (Req_trans (Rsub_congr (Req_refl one) (Rmul_ofQ_ofQ ha hb))
        (Rsub_ofQ_ofQ (by decide) (Qmul_den_pos ha hb)))) ?_
    exact Rmul_ofQ_ofQ (vval_den_pos a b hpos) (Qsub_den_pos (by decide) (Qmul_den_pos ha hb))
  exact Req_trans hLHS (Req_symm hRHS)

/-- **★ value-level tangent-addition**: if `sin A = a·cos A` and `sin B = b·cos B` (and `1−ab > 0`),
    then `sin(A+B) = vval a b · cos(A+B)` — i.e. `A+B` is an angle whose tangent is `vval a b =
    (a+b)/(1−ab)`, the SAME form as `sin(arctan v) = v·cos(arctan v)`. Combines `Rsin_add_of_tan`
    (`sin(A+B)=(a+b)cosAcosB`), `Rcos_add_of_tan` (`cos(A+B)=(1−ab)cosAcosB`), and the `vval`
    relation `(a+b)=vval·(1−ab)` (`vval_coeff_eq`). The value-level `tan(A+B) = (tan A+tan B)/(1−tan A
    tan B)` — combined with tan-injectivity this yields `arctan a + arctan b = arctan(vval a b)`. -/
theorem Rsin_cos_add_tan {A B : Real} {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den)
    (hpos : 0 < (a.den : Int) * b.den - a.num * b.num)
    (hA : Req (Rsin A) (Rmul (ofQ a ha) (Rcos A))) (hB : Req (Rsin B) (Rmul (ofQ b hb) (Rcos B))) :
    Req (Rsin (Radd A B)) (Rmul (ofQ (vval a b) (vval_den_pos a b hpos)) (Rcos (Radd A B))) := by
  refine Req_trans (Rsin_add_of_tan ha hb hA hB) ?_
  refine Req_trans (Rmul_congr (vval_coeff_eq a b ha hb hpos) (Req_refl _)) ?_
  refine Req_trans (Rmul_assoc (ofQ (vval a b) (vval_den_pos a b hpos))
    (Rsub one (Rmul (ofQ a ha) (ofQ b hb))) (Rmul (Rcos A) (Rcos B))) ?_
  exact Rmul_congr (Req_refl _) (Req_symm (Rcos_add_of_tan ha hb hA hB))

-- ===========================================================================
-- Parity: cos is even, sin is odd (toward tan-injectivity → arctan addition).
-- ===========================================================================

/-- The alternating term is even in its base: `altTerm (−q) off n = altTerm q off n` (depends on `q²`
    only, and `(−q)² = q²`). -/
theorem altTerm_base_neg (q : Q) (off n : Nat) : Qeq (altTerm (neg q) off n) (altTerm q off n) := by
  unfold altTerm
  refine Qmul_congr (qpow_Qeq ?_ n) (Qeq_refl _)
  show Qeq (neg (mul (neg q) (neg q))) (neg (mul q q))
  simp only [Qeq, neg, mul]; push_cast; ring_uor

/-- The alternating sum is even in its base: `altSum (−q) off N = altSum q off N`. -/
theorem altSum_base_neg (q : Q) (off : Nat) : ∀ N, Qeq (altSum (neg q) off N) (altSum q off N)
  | 0 => altTerm_base_neg q off 0
  | (N + 1) => Qadd_congr (altSum_base_neg q off N) (altTerm_base_neg q off (N + 1))

/-- `xBound (−x) = xBound x` (negation preserves `|num|` and `den` of the 0-th approximant). -/
theorem xBound_neg (x : Real) : xBound (Rneg x) = xBound x := by
  unfold xBound
  show (neg (x.seq 0)).num.natAbs + 2 * (neg (x.seq 0)).den = (x.seq 0).num.natAbs + 2 * (x.seq 0).den
  simp only [neg, Int.natAbs_neg]

/-- `RaltReal_K (−x) = RaltReal_K x` (depends only on `xBound`). -/
theorem RaltReal_K_neg (x : Real) : RaltReal_K (Rneg x) = RaltReal_K x := by
  unfold RaltReal_K; rw [xBound_neg]

/-- `RaltReal_R (−x) j = RaltReal_R x j` (the diagonal reindex depends only on `xBound`). -/
theorem RaltReal_R_neg (x : Real) (j : Nat) : RaltReal_R (Rneg x) j = RaltReal_R x j := by
  unfold RaltReal_R; rw [xBound_neg, RaltReal_K_neg]

/-- **`cos` is even**: `cos(−x) = cos x` (`altSum_base_neg` + the reindex parity `RaltReal_R_neg`). -/
theorem Rcos_neg (x : Real) : Req (Rcos (Rneg x)) (Rcos x) := by
  refine Req_of_seq_Qeq (fun j => ?_)
  show Qeq (altSum (neg (x.seq (RaltReal_R (Rneg x) j))) 0 (RaltReal_R (Rneg x) j))
    (altSum (x.seq (RaltReal_R x j)) 0 (RaltReal_R x j))
  rw [RaltReal_R_neg]
  exact altSum_base_neg (x.seq (RaltReal_R x j)) 0 (RaltReal_R x j)

/-- `RsinAux(−x) = RsinAux x` (the `sin/x` series is even). -/
theorem RsinAux_neg (x : Real) : Req (RsinAux (Rneg x)) (RsinAux x) := by
  refine Req_of_seq_Qeq (fun j => ?_)
  show Qeq (altSum (neg (x.seq (RaltReal_R (Rneg x) j))) 1 (RaltReal_R (Rneg x) j))
    (altSum (x.seq (RaltReal_R x j)) 1 (RaltReal_R x j))
  rw [RaltReal_R_neg]
  exact altSum_base_neg (x.seq (RaltReal_R x j)) 1 (RaltReal_R x j)

/-- **`sin` is odd**: `sin(−x) = −sin x` (`sin = x·RsinAux`, `RsinAux` even, `Rmul_neg_left`). -/
theorem Rsin_neg (x : Real) : Req (Rsin (Rneg x)) (Rneg (Rsin x)) :=
  Req_trans (Rmul_congr (Req_refl (Rneg x)) (RsinAux_neg x)) (Rmul_neg_left x (RsinAux x))

/-- **sin subtraction formula**: `sin(x−y) = sin x·cos y − cos x·sin y` (`Rsin_add` + parity). -/
theorem Rsin_sub (x y : Real) :
    Req (Rsin (Rsub x y)) (Rsub (Rmul (Rsin x) (Rcos y)) (Rmul (Rcos x) (Rsin y))) := by
  refine Req_trans (Rsin_add x (Rneg y)) ?_
  refine Req_trans (Radd_congr (Rmul_congr (Req_refl _) (Rsin_neg y))
    (Rmul_congr (Req_refl _) (Rcos_neg y))) ?_
  refine Req_trans (Radd_congr (Rmul_neg_right (Rcos x) (Rsin y)) (Req_refl _)) ?_
  exact Radd_comm (Rneg (Rmul (Rcos x) (Rsin y))) (Rmul (Rsin x) (Rcos y))

/-- **Shared-tangent ⟹ `sin(x−y) = 0`**: if `sin x = v·cos x` and `sin y = v·cos y` (same `v`), then
    `sin(x−y) = v·cosx·cosy − v·cosx·cosy = 0`. (`Rsin_sub` + substitution + `Radd_neg`.) -/
theorem Rsin_sub_eq_zero {x y v : Real} (hx : Req (Rsin x) (Rmul v (Rcos x)))
    (hy : Req (Rsin y) (Rmul v (Rcos y))) : Req (Rsin (Rsub x y)) zero := by
  refine Req_trans (Rsin_sub x y) ?_
  refine Req_trans (Rsub_congr (Rmul_congr hx (Req_refl _)) (Rmul_congr (Req_refl _) hy)) ?_
  refine Req_trans (Rsub_congr (Rmul_assoc v (Rcos x) (Rcos y))
    (Rmul_left_comm_loc (Rcos x) v (Rcos y))) ?_
  exact Radd_neg (Rmul v (Rmul (Rcos x) (Rcos y)))

/-- **Cancellation**: if `a·b = 0` and `b` is apart from `0` (positive lower bound `Qbound k < b.seq k`,
    so `b` is invertible), then `a = 0`. Via `a = a·(b·b⁻¹) = (a·b)·b⁻¹ = 0·b⁻¹ = 0`. -/
theorem Rmul_eq_zero_cancel {a b : Real} {k : Nat} (hk : Qlt (Qbound k) (b.seq k))
    (h : Req (Rmul a b) zero) : Req a zero := by
  refine Req_trans (Req_symm (Rmul_one a)) ?_
  refine Req_trans (Rmul_congr (Req_refl a) (Req_symm (Rmul_Rinv_self hk))) ?_
  refine Req_trans (Req_symm (Rmul_assoc a b (Rinv b k hk))) ?_
  refine Req_trans (Rmul_congr h (Req_refl (Rinv b k hk))) ?_
  exact Req_trans (Rmul_comm zero (Rinv b k hk)) (Rmul_zero (Rinv b k hk))

/-- `x − y = 0 ⟹ x = y` (local copy). -/
theorem Req_of_Rsub_zero_loc {a b : Real} (h : Req (Rsub a b) zero) : Req a b := by
  have h1 : Req a (Radd (Rsub a b) b) := by
    show Req a (Radd (Radd a (Rneg b)) b)
    refine Req_trans (Req_symm (Radd_zero a)) ?_
    have hz : Req zero (Radd (Rneg b) b) :=
      Req_symm (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b))
    exact Req_trans (Radd_congr (Req_refl a) hz) (Req_symm (Radd_assoc a (Rneg b) b))
  exact Req_trans h1 (Req_trans (Radd_congr h (Req_refl b)) (Req_trans (Radd_comm zero b) (Radd_zero b)))

/-- **★ tangent-injectivity**: if `sin x = v·cos x`, `sin y = v·cos y` (same tangent `v`), and the
    angle difference `x−y` has `RsinAux(x−y)` apart from `0` (i.e. `x−y` is small enough that the
    `sin/x` factor is positive — `Qbound k < RsinAux(x−y).seq k`), then `x = y`. Via
    `Rsin_sub_eq_zero` (`sin(x−y)=0`) + `Rmul_eq_zero_cancel` (`sin(x−y) = (x−y)·RsinAux(x−y)`, so
    `x−y = 0`). The key step for `arctan a + arctan b = arctan(vval a b)`. -/
theorem Rtan_inj {x y v : Real} {k : Nat}
    (hk : Qlt (Qbound k) ((RsinAux (Rsub x y)).seq k))
    (hx : Req (Rsin x) (Rmul v (Rcos x))) (hy : Req (Rsin y) (Rmul v (Rcos y))) : Req x y :=
  Req_of_Rsub_zero_loc (Rmul_eq_zero_cancel hk (Rsin_sub_eq_zero hx hy))

-- ===========================================================================
-- Tangent-addition capstone: A+B = C from the tangent VALUES.
-- The arctan analog of `Req_add_of_exp_values` (the exp-injectivity core of the modulus half).
-- ===========================================================================

/-- **★ addition from tangent-values** (the tan-injectivity core of the imaginary/`arg` half): if
    `A` has tangent `a`, `B` has tangent `b` (i.e. `sin A = a·cos A`, `sin B = b·cos B`), `1−ab > 0`,
    and the angle `(A+B)−C` is small enough that `RsinAux((A+B)−C)` is apart from `0`, then `A+B = C`
    whenever `C` has tangent `vval a b = (a+b)/(1−ab)`. Combines the value-level tangent-addition
    `Rsin_cos_add_tan` (`A+B` has tangent `vval a b`) with tangent-injectivity `Rtan_inj` (`A+B` and
    `C` share that tangent ⟹ equal). The exact arctan analog of `Req_add_of_exp_values`: the algebraic
    law is clean and the sole analytic input (here the `RsinAux` apartness, there the exp-values) is an
    explicit, audit-visible hypothesis. This is what packages `arctan a + arctan b = arctan(vval a b)`,
    hence `arg(zw) = arg z + arg w`. -/
theorem Req_add_of_tan_values {A B C : Real} {a b : Q} {k : Nat} (ha : 0 < a.den) (hb : 0 < b.den)
    (hpos : 0 < (a.den : Int) * b.den - a.num * b.num)
    (hk : Qlt (Qbound k) ((RsinAux (Rsub (Radd A B) C)).seq k))
    (hA : Req (Rsin A) (Rmul (ofQ a ha) (Rcos A))) (hB : Req (Rsin B) (Rmul (ofQ b hb) (Rcos B)))
    (hC : Req (Rsin C) (Rmul (ofQ (vval a b) (vval_den_pos a b hpos)) (Rcos C))) :
    Req (Radd A B) C :=
  Rtan_inj hk (Rsin_cos_add_tan ha hb hpos hA hB) hC

-- ===========================================================================
-- Discharging the `RsinAux` apartness witness for small arguments.
-- `sin(w)/w ≈ 1 − w²/6 + …` is `≥ 1/2` for `|w| ≤ 1`, so `RsinAux w` is apart from `0`.
-- ===========================================================================

/-- **`−|x| ≤ x`** from `|x| ≤ c`: the lower one-sided bound of a `Qabs` estimate. -/
theorem Qneg_le_of_Qabs_le {x c : Q} (hxd : 0 < x.den) (h : Qle (Qabs x) c) : Qle (neg c) x := by
  have h1 : Qle (neg x) (Qabs x) := by
    have h0 := Qle_self_Qabs (neg x); rwa [Qabs_neg] at h0
  have h2 : Qle (neg x) c := Qle_trans (Qabs_den_pos hxd) h1 h
  have heq : Qeq (neg (neg x)) x := by simp only [Qeq, neg]; push_cast; ring_uor
  exact Qle_congr_right (b := neg (neg x)) hxd heq (Qneg_le_neg h2)

/-- **`sin(w)/w ≥ 5/6` to second order**: for `|q| ≤ 1` the explicit degree-2 partial sum
    `altSum q 1 2 = 1 − q²/6 + q⁴/120` is `≥ 5/6` (the `−q²/6` term loses at most `1/6`, the `q⁴/120`
    term is `≥ 0`). -/
theorem altSum_sin_two_ge {q : Q} (hqd : 0 < q.den) (hq1 : Qle (Qabs q) (⟨1, 1⟩ : Q)) :
    Qle (⟨5, 6⟩ : Q) (altSum q 1 2) := by
  have habs : Qle (Qabs (neg (mul q q))) (⟨1, 1⟩ : Q) :=
    Qle_congr_right (by decide) (by decide) (qsq_abs_le (M := 1) hqd hq1)
  have hsqd : 0 < (neg (mul q q)).den := Nat.mul_pos hqd hqd
  -- t0 = 1
  have h0 : Qle (⟨1, 1⟩ : Q) (altTerm q 1 0) := by
    have he : Qeq (⟨1, 1⟩ : Q) (altTerm q 1 0) := by
      show Qeq (⟨1, 1⟩ : Q) (mul (⟨1, 1⟩ : Q) ⟨1, fct (2 * 0 + 1)⟩)
      decide
    exact Qeq_le he
  -- t1 ≥ −1/6
  have ht1eq : Qeq (altTerm q 1 1) (mul (neg (mul q q)) (⟨1, 6⟩ : Q)) := by
    show Qeq (mul (qpow (neg (mul q q)) 1) ⟨1, fct (2 * 1 + 1)⟩) (mul (neg (mul q q)) (⟨1, 6⟩ : Q))
    rw [show fct (2 * 1 + 1) = 6 from rfl]
    simp only [qpow, Qeq, mul, neg]; push_cast; ring_uor
  have hmul1 : Qle (mul (neg (⟨1, 1⟩ : Q)) (⟨1, 6⟩ : Q)) (mul (neg (mul q q)) (⟨1, 6⟩ : Q)) :=
    Qmul_le_mul_right (by decide) (Qneg_le_of_Qabs_le hsqd habs)
  have h1 : Qle (neg (⟨1, 6⟩ : Q)) (altTerm q 1 1) :=
    Qle_congr_left (by decide) (by decide)
      (Qle_congr_right (Qmul_den_pos hsqd (by decide)) (Qeq_symm ht1eq) hmul1)
  -- t2 ≥ 0
  have h2 : Qle (⟨0, 1⟩ : Q) (altTerm q 1 2) := by
    have hsbase : (0 : Int) ≤ q.num * q.num := by
      rcases Int.le_total 0 q.num with h | h
      · exact Int.mul_nonneg h h
      · have hpp : (0 : Int) ≤ (-q.num) * (-q.num) := Int.mul_nonneg (by omega) (by omega)
        have he : (-q.num) * (-q.num) = q.num * q.num := by ring_uor
        omega
    have hsq : (0 : Int) ≤ (q.num * q.num) * (q.num * q.num) := Int.mul_nonneg hsbase hsbase
    have hN : (altTerm q 1 2).num = (q.num * q.num) * (q.num * q.num) := by
      show (mul (qpow (neg (mul q q)) 2) ⟨1, fct (2 * 2 + 1)⟩).num = (q.num * q.num) * (q.num * q.num)
      simp only [qpow, mul, neg]; ring_uor
    unfold Qle
    rw [hN]
    show (0 : Int) * ((altTerm q 1 2).den : Int) ≤ (q.num * q.num) * (q.num * q.num) * (1 : Int)
    omega
  -- combine: 1 + (−1/6) + 0 = 5/6
  have hsum := Qadd_le_add (Qadd_le_add h0 h1) h2
  exact Qle_congr_left (by decide) (by decide) hsum

/-- **The `sin/x` diagonal partial sum exceeds `1/3`** for `|q| ≤ 1` and depth `R ≥ 2`: its value is
    `≥ 1/2` — the degree-2 head is `≥ 5/6` (`altSum_sin_two_ge`) and the tail past it is `≤ 2/6`
    (`altSum_trunc_bound`). -/
theorem altSum_sin_diag_gt {q : Q} (hqd : 0 < q.den) (hq1 : Qle (Qabs q) (⟨1, 1⟩ : Q))
    {R : Nat} (hR2 : 2 ≤ R) : Qlt (⟨1, 3⟩ : Q) (altSum q 1 R) := by
  have hlow2 : Qle (⟨5, 6⟩ : Q) (altSum q 1 2) := altSum_sin_two_ge hqd hq1
  -- tail past index 2: |altSum q 1 R − altSum q 1 2| ≤ 2/6
  have htr : Qle (Qabs (Qsub (altSum q 1 R) (altSum q 1 2))) (⟨2, 6⟩ : Q) :=
    Qle_congr_right (by decide) (by decide)
      (altSum_trunc_bound (M := 1) hqd hq1 1 (by decide) hR2)
  have hub : Qle (altSum q 1 2) (add (altSum q 1 R) (⟨2, 6⟩ : Q)) :=
    Qle_add_of_Qabs_sub (altSum_den_pos hqd 1 2) (altSum_den_pos hqd 1 R) (by decide)
      (by rw [Qabs_Qsub_comm]; exact htr)
  -- so 5/6 ≤ altSum q 1 R + 2/6, hence altSum q 1 R ≥ 1/2
  have hchain : Qle (⟨5, 6⟩ : Q) (add (altSum q 1 R) (⟨2, 6⟩ : Q)) :=
    Qle_trans (altSum_den_pos hqd 1 2) hlow2 hub
  have hcancel : Qle (⟨1, 2⟩ : Q) (altSum q 1 R) := by
    have hstep := Qadd_le_add hchain (Qle_refl (neg (⟨2, 6⟩ : Q)))
    refine Qle_congr_left (by decide) (by decide)
      (Qle_congr_right (add_den_pos (add_den_pos (altSum_den_pos hqd 1 R) (by decide)) (by decide))
        ?_ hstep)
    simp only [Qeq, add, neg]; push_cast; ring_uor
  -- 1/3 < altSum q 1 R from 1/2 ≤ altSum q 1 R
  have hDi : (1 : Int) ≤ ((altSum q 1 R).den : Int) := by
    have := altSum_den_pos hqd 1 R; exact_mod_cast this
  simp only [Qlt, Qle] at hcancel ⊢
  push_cast at hcancel ⊢
  omega

/-- **★ `RsinAux w` is apart from `0` for `|w| ≤ 1`**: the `sin(w)/w` diagonal exceeds `1/3` at index
    `2` (`altSum_sin_diag_gt`, since the reindex depth `RaltReal_R w 2 ≥ 2`). This discharges the
    apartness witness `Rtan_inj` / `Req_add_of_tan_values` need, so the arctan-addition law applies
    whenever the angle difference is small. -/
theorem Pos_RsinAux_of_small {w : Real} (hw : ∀ n, Qle (Qabs (w.seq n)) (⟨1, 1⟩ : Q)) :
    Pos (RsinAux w) :=
  ⟨2, altSum_sin_diag_gt (w.den_pos _) (hw _) (Nat.le_trans (by decide) (RaltReal_R_ge w 2))⟩

-- ===========================================================================
-- The arctan addition law: arctan a + arctan b = arctan(vval a b), (a+b)/(1−ab).
-- ===========================================================================

/-- **★ the arctan addition law** `arctan a + arctan b = arctan((a+b)/(1−ab))` (value level): for
    `|a|, |b|, |vval a b| ≤ ρ` (a common `ρ < 1/16` satisfying the `Rsin_arctan_value_eq` thicket) and
    `1 − ab > 0`, the angles add to `arctan(vval a b)`. Each of `arctan a`, `arctan b`,
    `arctan(vval a b)` has the right tangent (`Rsin_arctan_value_eq`), so `Req_add_of_tan_values`
    closes it, given the `RsinAux` apartness `hk` for the angle difference (small, so
    `Pos_RsinAux_of_small` discharges it once the difference is bounded by `1`). This is the imaginary
    half of `Clog` additivity: `arg(zw) = arg z + arg w`. -/
theorem Rarctan_add {a b ρ : Q} {k : Nat}
    (hda : 0 < a.den) (hdb : 0 < b.den)
    (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (htρa : Qle (Qabs a) ρ) (htρb : Qle (Qabs b) ρ)
    (hpos : 0 < (a.den : Int) * b.den - a.num * b.num)
    (htρv : Qle (Qabs (vval a b)) ρ)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩)
    (hk : Qlt (Qbound k) ((RsinAux (Rsub
            (Radd (Rarctan a hda hρ0 hρd hlt htρa) (Rarctan b hdb hρ0 hρd hlt htρb))
            (Rarctan (vval a b) (vval_den_pos a b hpos) hρ0 hρd hlt htρv))).seq k)) :
    Req (Radd (Rarctan a hda hρ0 hρd hlt htρa) (Rarctan b hdb hρ0 hρd hlt htρb))
        (Rarctan (vval a b) (vval_den_pos a b hpos) hρ0 hρd hlt htρv) :=
  Req_add_of_tan_values hda hdb hpos hk
    (Rsin_arctan_value_eq a ρ hda hρ0 hρd hlt htρa hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1)
    (Rsin_arctan_value_eq b ρ hdb hρ0 hρd hlt htρb hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1)
    (Rsin_arctan_value_eq (vval a b) ρ (vval_den_pos a b hpos) hρ0 hρd hlt htρv hlt16 h2ρ hhalf
      hρ4 hρ2 hρ8 hρ1)

-- ===========================================================================
-- Magnitude bound on the arctan diagonal — to discharge the apartness automatically.
-- `|arctan t| ≤ 2ρ`: the geometric series Σρ^{2i+1} = ρ/(1−ρ²) ≤ 2ρ when ρ² ≤ 1/2.
-- ===========================================================================

/-- **`geoSum ρ N ≤ 2ρ`** when `1 − ρ² ≥ 1/2` (i.e. `ρ² ≤ 1/2`): `geoSum ρ N · (1−ρ²) ≤ ρ`
    (`geoSum_tel_le`), and `ρ ≤ 2ρ·(1−ρ²)` since `2(1−ρ²) ≥ 1`. -/
theorem geoSum_le_two {ρ : Q} (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (N : Nat) :
    Qle (geoSum ρ N) (mul (⟨2, 1⟩ : Q) ρ) := by
  have hWd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).den := Qsub_den_pos Nat.one_pos (Nat.mul_pos hρd hρd)
  have hWn : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).num := by
    have h : (1 : Int) * ((Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).den : Int)
        ≤ (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).num * 2 := hρ2
    have hd : (1 : Int) ≤ ((Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).den : Int) := by exact_mod_cast hWd
    omega
  have key : Qle (qpow ρ 1) (mul (mul (⟨2, 1⟩ : Q) ρ) (Qsub ⟨1, 1⟩ (mul ρ ρ))) := by
    have h12W : Qle (⟨1, 1⟩ : Q) (mul (⟨2, 1⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) :=
      Qle_congr_left (by decide) (by decide) (Qmul_le_mul_left (by decide) hρ2)
    have hstep : Qle (mul ρ (⟨1, 1⟩ : Q)) (mul ρ (mul (⟨2, 1⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ)))) :=
      Qmul_le_mul_left hρ0 h12W
    refine Qle_congr_right (Qmul_den_pos hρd (Qmul_den_pos (by decide) hWd)) ?_ hstep
    simp only [Qeq, mul]; push_cast; ring_uor
  apply Qmul_le_cancel_right hWn hWd
  exact Qle_trans (qpow_den_pos hρd 1) (geoSum_tel_le ρ hρd hρ0 N) key

/-- **`|arctan t| ≤ 2ρ` at the diagonal** (`|t| ≤ ρ`, `ρ² ≤ 1/2`): every approximant of the
    real-valued `Rarctan t` is bounded by `2ρ` (`arctanSum_abs_le` then `geoSum_le_two`). The uniform
    angle bound that, summed over the three angles of the addition law, keeps the difference `≤ 1` and
    so discharges the `RsinAux` apartness. -/
theorem Rarctan_seq_abs_le (t : Q) (htd : 0 < t.den) {ρ : Q} (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (htρ : Qle (Qabs t) ρ)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (n : Nat) :
    Qle (Qabs ((Rarctan t htd hρ0 hρd hlt htρ).seq n)) (mul (⟨2, 1⟩ : Q) ρ) :=
  Qle_trans (geoSum_den_pos hρd _) (arctanSum_abs_le htd hρ0 hρd htρ (Rartanh_R ρ n))
    (geoSum_le_two hρ0 hρd hρ2 _)

/-- **`2ρ ≤ 1/3`** from `16ρ < 1` (`hlt16`): each angle's budget so three of them sum below `1`. -/
theorem Qmul_two_le_third {ρ : Q} (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den) :
    Qle (mul (⟨2, 1⟩ : Q) ρ) (⟨1, 3⟩ : Q) := by
  have hnn : (0 : Int) ≤ 16 * ρ.num := Int.mul_nonneg (by decide) hρ0
  have h16 : 16 * ρ.num < (ρ.den : Int) := by
    have h : (16 * ρ.num).toNat < 1 * ρ.den := hlt16
    omega
  show (2 * ρ.num) * ((3 : Nat) : Int) ≤ (1 : Int) * ((1 * ρ.den : Nat) : Int)
  push_cast; omega

/-- **The arctan angle-difference is `≤ 1` everywhere**: each of `arctan a`, `arctan b`,
    `arctan(vval a b)` is `≤ 2ρ` (`Rarctan_seq_abs_le`), so the `Radd`/`Rsub`-reindexed difference is
    `≤ 6ρ ≤ 1` (`Qmul_six_le_one`). Discharges the `Pos_RsinAux_of_small` hypothesis. -/
theorem Rarctan_diff_seq_le {a b ρ : Q} (hda : 0 < a.den) (hdb : 0 < b.den)
    (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (htρa : Qle (Qabs a) ρ) (htρb : Qle (Qabs b) ρ)
    (hpos : 0 < (a.den : Int) * b.den - a.num * b.num) (htρv : Qle (Qabs (vval a b)) ρ)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ)))
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den) (n : Nat) :
    Qle (Qabs ((Rsub
        (Radd (Rarctan a hda hρ0 hρd hlt htρa) (Rarctan b hdb hρ0 hρd hlt htρb))
        (Rarctan (vval a b) (vval_den_pos a b hpos) hρ0 hρd hlt htρv)).seq n)) (⟨1, 1⟩ : Q) := by
  have hA := Rarctan_seq_abs_le a hda hρ0 hρd hlt htρa hρ2 (2 * (2 * n + 1) + 1)
  have hB := Rarctan_seq_abs_le b hdb hρ0 hρd hlt htρb hρ2 (2 * (2 * n + 1) + 1)
  have hC := Rarctan_seq_abs_le (vval a b) (vval_den_pos a b hpos) hρ0 hρd hlt htρv hρ2 (2 * n + 1)
  have dA : 0 < ((Rarctan a hda hρ0 hρd hlt htρa).seq (2 * (2 * n + 1) + 1)).den :=
    (Rarctan a hda hρ0 hρd hlt htρa).den_pos _
  have dB : 0 < ((Rarctan b hdb hρ0 hρd hlt htρb).seq (2 * (2 * n + 1) + 1)).den :=
    (Rarctan b hdb hρ0 hρd hlt htρb).den_pos _
  have dC : 0 < ((Rarctan (vval a b) (vval_den_pos a b hpos) hρ0 hρd hlt htρv).seq (2 * n + 1)).den :=
    (Rarctan (vval a b) (vval_den_pos a b hpos) hρ0 hρd hlt htρv).den_pos _
  have hCneg : Qle (Qabs (neg ((Rarctan (vval a b) (vval_den_pos a b hpos) hρ0 hρd hlt htρv).seq
        (2 * n + 1)))) (⟨1, 3⟩ : Q) := by
    rw [Qabs_neg]; exact Qle_trans (Qmul_den_pos (by decide) hρd) hC (Qmul_two_le_third hρ0 hρd hlt16)
  have hAt := Qle_trans (Qmul_den_pos (by decide) hρd) hA (Qmul_two_le_third hρ0 hρd hlt16)
  have hBt := Qle_trans (Qmul_den_pos (by decide) hρd) hB (Qmul_two_le_third hρ0 hρd hlt16)
  -- |add (add SA SB) (neg SC)| ≤ (|SA|+|SB|)+|SC| ≤ (1/3+1/3)+1/3 = 1
  refine Qle_trans (add_den_pos (Qabs_den_pos (add_den_pos dA dB)) (Qabs_den_pos (neg_den_pos dC)))
    (Qabs_add_le _ _) ?_
  refine Qle_trans (add_den_pos (add_den_pos (Qabs_den_pos dA) (Qabs_den_pos dB))
      (Qabs_den_pos (neg_den_pos dC)))
    (Qadd_le_add (Qabs_add_le _ _) (Qle_refl _)) ?_
  exact Qle_trans (add_den_pos (add_den_pos (by decide) (by decide)) (by decide))
    (Qadd_le_add (Qadd_le_add hAt hBt) hCneg) (Qeq_le (by decide))

/-- **★ the arctan addition law, apartness discharged** `arctan a + arctan b = arctan((a+b)/(1−ab))`:
    the `RsinAux` apartness `Rarctan_add` needs is now automatic — the angle difference is `≤ 1`
    everywhere (`Rarctan_diff_seq_le`), so `Pos_RsinAux_of_small` supplies the witness. Holds for any
    `|a|, |b|, |vval a b| ≤ ρ` with the shared `ρ < 1/16` thicket and `1 − ab > 0`. The complete
    imaginary half of `Clog` additivity. -/
theorem Rarctan_add_of_small {a b ρ : Q} (hda : 0 < a.den) (hdb : 0 < b.den)
    (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (htρa : Qle (Qabs a) ρ) (htρb : Qle (Qabs b) ρ)
    (hpos : 0 < (a.den : Int) * b.den - a.num * b.num) (htρv : Qle (Qabs (vval a b)) ρ)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩) :
    Req (Radd (Rarctan a hda hρ0 hρd hlt htρa) (Rarctan b hdb hρ0 hρd hlt htρb))
        (Rarctan (vval a b) (vval_den_pos a b hpos) hρ0 hρd hlt htρv) := by
  obtain ⟨k, hk⟩ := Pos_RsinAux_of_small
    (Rarctan_diff_seq_le hda hdb hρ0 hρd hlt htρa htρb hpos htρv hρ2 hlt16)
  exact Rarctan_add hda hdb hρ0 hρd hlt htρa htρb hpos htρv hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1 hk

-- ===========================================================================
-- Toward REAL-argument arctan addition (for `arg(zw) = arg z + arg w`).
-- The argument-variation leg, mirror of `artSum_wval_argdiff` (with the `vval` map, constant 12).
-- ===========================================================================

/-- **arctanSum arg-variation (via `vval`)**: `|arctanSum(vval a b, M) − arctanSum(vval a' b', M)| ≤
    12·(|a−a'| + |b−b'|)` for `|a|,|b|,|a'|,|b'| ≤ ρ` (`ρ² ≤ ½`) and `|vval ·| ≤ σ` (`σ² ≤ ½`). The
    arctan analog of `artSum_wval_argdiff`: `arctanSum_Lip_le` + `geoEvenSum_le_two`, then the `vval`
    map's two one-sided Lipschitz bounds (`vval_lip1`/`vval_lip2`, constant 6) through the mixed
    midpoint `vval a' b`. The `vval` denominator is sign-robust, so no `wvalR`-style split is needed. -/
theorem arctanSum_vval_argdiff (ρ σ a b a' b' : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num)
    (hρ2 : Qle (mul ρ ρ) ⟨1, 2⟩) (hσ0 : 0 ≤ σ.num) (hσd : 0 < σ.den)
    (hσ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul σ σ)))
    (had : 0 < a.den) (hbd : 0 < b.den) (ha'd : 0 < a'.den) (hb'd : 0 < b'.den)
    (ha : Qle (Qabs a) ρ) (hb : Qle (Qabs b) ρ) (ha' : Qle (Qabs a') ρ) (hb' : Qle (Qabs b') ρ)
    (hwσ : Qle (Qabs (vval a b)) σ) (hw'σ : Qle (Qabs (vval a' b')) σ) (M : Nat) :
    Qle (Qabs (Qsub (arctanSum (vval a b) M) (arctanSum (vval a' b') M)))
        (mul ⟨12, 1⟩ (add (Qabs (Qsub a a')) (Qabs (Qsub b b')))) := by
  have hwd : 0 < (vval a b).den := vval_den_pos a b (vval_inner_pos ρ a b hρd hρ0 had hbd ha hb hρ2)
  have hw'd : 0 < (vval a' b').den :=
    vval_den_pos a' b' (vval_inner_pos ρ a' b' hρd hρ0 ha'd hb'd ha' hb' hρ2)
  have hw2d : 0 < (vval a' b).den :=
    vval_den_pos a' b (vval_inner_pos ρ a' b hρd hρ0 ha'd hbd ha' hb hρ2)
  refine Qle_trans (Qmul_den_pos (geoEvenSum_den_pos hσd M) (Qabs_den_pos (Qsub_den_pos hwd hw'd)))
    (arctanSum_Lip_le hwd hw'd hσd hwσ hw'σ M) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos hwd hw'd)))
    (Qmul_le_mul_right (Qabs_num_nonneg _) (geoEvenSum_le_two hσ0 hσd hσ2 M)) ?_
  have hleg1 : Qle (Qabs (Qsub (vval a b) (vval a' b))) (mul ⟨6, 1⟩ (Qabs (Qsub a a'))) :=
    vval_lip1 ρ a a' b hρd hρ0 had ha'd hbd ha ha' hb hρ2
  have hleg2 : Qle (Qabs (Qsub (vval a' b) (vval a' b'))) (mul ⟨6, 1⟩ (Qabs (Qsub b b'))) :=
    vval_lip2 ρ a' b b' hρd hρ0 ha'd hbd hb'd ha' hb hb' hρ2
  refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos
      (Qabs_den_pos (Qsub_den_pos hwd hw2d)) (Qabs_den_pos (Qsub_den_pos hw2d hw'd))))
    (Qmul_le_mul_left (by decide) (Qabs_sub_triangle hwd hw2d hw'd)) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos
      (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos had ha'd)))
      (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos hbd hb'd)))))
    (Qmul_le_mul_left (by decide) (Qadd_le_add hleg1 hleg2)) ?_
  apply Qeq_le
  show Qeq (mul ⟨2, 1⟩ (add (mul ⟨6, 1⟩ (Qabs (Qsub a a'))) (mul ⟨6, 1⟩ (Qabs (Qsub b b')))))
    (mul ⟨12, 1⟩ (add (Qabs (Qsub a a')) (Qabs (Qsub b b'))))
  simp only [Qeq, mul, add]; push_cast; ring_uor

/-- **The combination leg in `arctanSum` form** (the arctan analog of `RartanhConst_add_wval_rho`):
    `|arctanSum a (Rartanh_R ρ (2n+1)) + arctanSum b (Rartanh_R ρ (2n+1)) − arctanSum (vval a b)
    (Rartanh_R ρ n)| ≤ 2/(n+1)`. This is precisely `Rarctan_add_of_small` (the real arctan addition
    law for the rationals `a, b`) read at diagonal index `n` — the `Req` unfolds to the `arctanSum`
    forms by definitional reduction of `Radd`/`Rarctan`. Inherently relates the depth-`n` `vval` to the
    depth-`(2n+1)` summands, so no polynomial bound is needed. -/
theorem RarctanConst_add_vval_rho (a b ρ : Q) (hda : 0 < a.den) (hdb : 0 < b.den)
    (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (htρa : Qle (Qabs a) ρ) (htρb : Qle (Qabs b) ρ)
    (hpos : 0 < (a.den : Int) * b.den - a.num * b.num) (htρv : Qle (Qabs (vval a b)) ρ)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩) (n : Nat) :
    Qle (Qabs (Qsub
        (add (arctanSum a (Rartanh_R ρ (2 * n + 1))) (arctanSum b (Rartanh_R ρ (2 * n + 1))))
        (arctanSum (vval a b) (Rartanh_R ρ n)))) (⟨2, n + 1⟩ : Q) :=
  Rarctan_add_of_small hda hdb hρ0 hρd hlt htρa htρb hpos htρv hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1 n

set_option maxHeartbeats 1200000 in
/-- **★ the real-argument arctan ADDITION** `arctan s + arctan t = arctan((s+t)/(1−st))` for reals
    `s, t` (the arctan analog of `Rartanh_add_real_via`). For `|s.seq m|, |t.seq m|,
    |vval(s.seq m, t.seq m)| ≤ ρ` (the `ρ < 1/16` thicket) and abstract diagonals `X1 = RarctanR s`,
    `X2 = RarctanR t`, `Y = RarctanR(vvalReal s t)` (via the seq equations), `X1 + X2 = Y`. Via
    `Req_of_lin_bound` and a 2-way split through `W = arctanSum(vval(s_P,t_P), …)`: the combination leg
    (`RarctanConst_add_vval_rho`, the exact rational addition relating depth-`n` to depth-`(2n+1)`) and
    the argument-variation leg (`arctanSum_vval_argdiff` + `s.reg`/`t.reg`). Packages as
    `arg(zw) = arg z + arg w`. -/
theorem RarctanR_add_real_via (s t X1 X2 Y : Real) (ρ : Q) (R_Y : Nat → Nat)
    (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩) (hRY : ∀ n, n ≤ R_Y n)
    (hbs : ∀ m, Qle (Qabs (s.seq m)) ρ) (hbt : ∀ m, Qle (Qabs (t.seq m)) ρ)
    (hbw : ∀ i, Qle (Qabs (vval (s.seq i) (t.seq i))) ρ)
    (hX1seq : ∀ j, X1.seq j = arctanSum (s.seq (Rartanh_R ρ j)) (Rartanh_R ρ j))
    (hX2seq : ∀ j, X2.seq j = arctanSum (t.seq (Rartanh_R ρ j)) (Rartanh_R ρ j))
    (hYseq : ∀ n, Y.seq n = arctanSum (vval (s.seq (R_Y n)) (t.seq (R_Y n))) (Rartanh_R ρ n)) :
    Req (Radd X1 X2) Y := by
  have hsd : ∀ m, 0 < (s.seq m).den := fun m => s.den_pos m
  have htd : ∀ m, 0 < (t.seq m).den := fun m => t.den_pos m
  have hρhalf : Qle (mul ρ ρ) (⟨1, 2⟩ : Q) := by
    have h := hρ2; simp only [Qle, Qsub, add, neg, mul] at h ⊢; push_cast at h ⊢; omega
  have hRge : ∀ k, k ≤ Rartanh_R ρ k := by
    intro k; unfold Rartanh_R
    have hk : 1 ≤ ρ.den * ρ.den + 4 * ρ.den := Nat.le_trans (by omega) (Nat.le_add_left _ _)
    calc k ≤ 1 * (k + 1) := by omega
      _ ≤ (ρ.den * ρ.den + 4 * ρ.den) * (k + 1) := Nat.mul_le_mul_right _ hk
  refine Req_of_lin_bound (C := 50) ?_
  intro n
  -- (Radd X1 X2).seq n = arctanSum(s_P,P) + arctanSum(t_P,P), P = Rartanh_R ρ (2n+1)
  have hae : (Radd X1 X2).seq n
      = add (arctanSum (s.seq (Rartanh_R ρ (2 * n + 1))) (Rartanh_R ρ (2 * n + 1)))
          (arctanSum (t.seq (Rartanh_R ρ (2 * n + 1))) (Rartanh_R ρ (2 * n + 1))) := by
    show add (X1.seq (2 * n + 1)) (X2.seq (2 * n + 1)) = _; rw [hX1seq, hX2seq]
  rw [hae, hYseq n]
  -- den-positivities
  have hposP : 0 < (s.seq (Rartanh_R ρ (2 * n + 1))).den * (t.seq (Rartanh_R ρ (2 * n + 1))).den
      - (s.seq (Rartanh_R ρ (2 * n + 1))).num * (t.seq (Rartanh_R ρ (2 * n + 1))).num :=
    vval_inner_pos ρ _ _ hρd hρ0 (hsd _) (htd _) (hbs _) (hbt _) hρhalf
  have hWd : 0 < (arctanSum (vval (s.seq (Rartanh_R ρ (2 * n + 1))) (t.seq (Rartanh_R ρ (2 * n + 1))))
      (Rartanh_R ρ n)).den := arctanSum_den_pos (vval_den_pos _ _ hposP) _
  have hYd : 0 < (arctanSum (vval (s.seq (R_Y n)) (t.seq (R_Y n))) (Rartanh_R ρ n)).den :=
    arctanSum_den_pos (vval_den_pos _ _ (vval_inner_pos ρ _ _ hρd hρ0 (hsd _) (htd _)
      (hbs _) (hbt _) hρhalf)) _
  have hRd : 0 < (add (arctanSum (s.seq (Rartanh_R ρ (2 * n + 1))) (Rartanh_R ρ (2 * n + 1)))
      (arctanSum (t.seq (Rartanh_R ρ (2 * n + 1))) (Rartanh_R ρ (2 * n + 1)))).den :=
    add_den_pos (arctanSum_den_pos (hsd _) _) (arctanSum_den_pos (htd _) _)
  -- leg A: combination (the rational addition law at the diagonal rationals)
  have hlegA : Qle (Qabs (Qsub
        (add (arctanSum (s.seq (Rartanh_R ρ (2 * n + 1))) (Rartanh_R ρ (2 * n + 1)))
          (arctanSum (t.seq (Rartanh_R ρ (2 * n + 1))) (Rartanh_R ρ (2 * n + 1))))
        (arctanSum (vval (s.seq (Rartanh_R ρ (2 * n + 1))) (t.seq (Rartanh_R ρ (2 * n + 1))))
          (Rartanh_R ρ n)))) (⟨2, n + 1⟩ : Q) :=
    RarctanConst_add_vval_rho _ _ ρ (hsd _) (htd _) hρ0 hρd hlt (hbs _) (hbt _) hposP (hbw _)
      hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1 n
  -- leg B: argument variation
  have hQbP : Qle (Qbound (Rartanh_R ρ (2 * n + 1))) (Qbound n) := by
    show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((Rartanh_R ρ (2 * n + 1) + 1 : Nat) : Int)
    have := hRge (2 * n + 1); rw [Int.one_mul, Int.one_mul]
    exact_mod_cast (show n + 1 ≤ Rartanh_R ρ (2 * n + 1) + 1 by omega)
  have hQbM : Qle (Qbound (R_Y n)) (Qbound n) := by
    show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((R_Y n + 1 : Nat) : Int)
    have := hRY n; rw [Int.one_mul, Int.one_mul]
    exact_mod_cast (show n + 1 ≤ R_Y n + 1 by omega)
  have hvar := arctanSum_vval_argdiff ρ ρ (s.seq (Rartanh_R ρ (2 * n + 1)))
    (t.seq (Rartanh_R ρ (2 * n + 1))) (s.seq (R_Y n)) (t.seq (R_Y n))
    hρd hρ0 hρhalf hρ0 hρd hρ2 (hsd _) (htd _) (hsd _) (htd _)
    (hbs _) (hbt _) (hbs _) (hbt _) (hbw _) (hbw _) (Rartanh_R ρ n)
  have hlegB : Qle (Qabs (Qsub
        (arctanSum (vval (s.seq (Rartanh_R ρ (2 * n + 1))) (t.seq (Rartanh_R ρ (2 * n + 1))))
          (Rartanh_R ρ n))
        (arctanSum (vval (s.seq (R_Y n)) (t.seq (R_Y n))) (Rartanh_R ρ n)))) (⟨48, n + 1⟩ : Q) := by
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
    show Qeq (mul ⟨12, 1⟩ (add (add (Qbound n) (Qbound n)) (add (Qbound n) (Qbound n))))
      (⟨48, n + 1⟩ : Q)
    simp only [Qeq, mul, add, Qbound]; push_cast; ring_uor
  -- triangle through W and combine
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hRd hWd))
      (Qabs_den_pos (Qsub_den_pos hWd hYd)))
    (Qabs_sub_triangle hRd hWd hYd) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)) (Qadd_le_add hlegA hlegB) ?_
  apply Qeq_le; exact Qadd_same_den_loc 2 48 (n + 1)

end UOR.Bridge.F1Square.Analysis
