/-
Copyright (c) 2026 Multiplicity. All rights reserved.
Released under Apache 2.0 license.
Authors: Multiplicity Foundry
-/
import Init.Omega
import Multiplicity.SpectralAttractor.Tags
import Multiplicity.SpectralAttractor.Basic
import Multiplicity.SpectralAttractor.Certificates
import Multiplicity.SpectralAttractor.Matrices

/-!
# The sum-zero hyperplane

ADR-0034-F1 signature layer: the hyperplane `H = {v : Σ_i v_i = 0}`
on which the indefinite proxy kernel is *claimed* (numerically) to be
positive definite.

Machine-checked content (all unconditional):

* additive structure of finite sums (`finSum_add`, `finSum_neg`);
* negation distributes over carrier addition (`cneg_add`);
* the difference basis `basisDiff k = e_0 - e_{k+1}`: each generator
  lies in `H`;
* `H` is closed under pointwise addition and negation;
* congruence of the quadratic form on pointwise-equal vectors;
* unconditional symmetry of `proxyKernel`.

The signature condition itself — positivity of the restricted form,
known numerically on the difference basis — enters exactly as the
hypothesis structure `ProxySignatureHypothesis`; extending from the
difference basis to all of `H` is the remaining analytic step and is
deliberately *not* claimed here (no `sorry`: it is not stated as a
theorem).
-/

namespace ComplexKappa.SpectralAttractor

variable {R : Type}

/-! ## Carrier negation -/

private theorem add_right_cancel_inv {R} [so : SpectralOrderedCarrier R]
    {X Y s : R} (hX : X + s = czero) (hY : Y + s = czero) : X = Y := by
  have hsY : s + Y = czero := by rw [so.add_comm]; exact hY
  calc X = X + (s + Y) := by rw [hsY]; exact (add_czero X).symm
    _ = (X + s) + Y := (so.add_assoc X s Y).symm
    _ = Y := by rw [hX]; exact czero_add Y

private theorem cneg_left {R} [so : SpectralOrderedCarrier R] (z : R) :
    so.toNeg.neg z + z = czero := by
  rw [so.add_comm]
  exact so.add_left_neg z

private theorem cneg_czero {R} [so : SpectralOrderedCarrier R] :
    so.toNeg.neg czero = czero := by
  have hA : czero (R := R) + so.toNeg.neg czero
      = so.toNeg.neg czero :=
    czero_add (so.toNeg.neg czero)
  have hB : czero (R := R) + so.toNeg.neg czero
      = czero (R := R) :=
    so.add_left_neg (czero (R := R))
  rw [← hA]
  exact hB

/-- Negation distributes over addition (derived, not a class field). -/
@[proof] theorem cneg_add {R} [so : SpectralOrderedCarrier R] (a b : R) :
    so.toNeg.neg (a + b) = so.toNeg.neg a + so.toNeg.neg b := by
  refine add_right_cancel_inv (s := a + b) ?_ ?_
  · exact cneg_left (a + b)
  · have step : (so.toNeg.neg a + so.toNeg.neg b) + (a + b)
        = so.toNeg.neg a + (so.toNeg.neg b + (a + b)) := so.add_assoc _ _ _
    have inner : so.toNeg.neg b + (a + b)
        = (so.toNeg.neg b + b) + a := by
      rw [so.add_assoc, so.add_comm a b, ← so.add_assoc]
    rw [step, inner, cneg_left b, czero_add, cneg_left a]

/-! ## Hyperplane carrier -/

/-- Entry sum of a vector. -/
@[adr] def vecSum {R} [so : SpectralOrderedCarrier R] (v : Vec R) : R :=
  finSum v

/-- The sum-zero hyperplane membership predicate. -/
@[adr] def inSumZero {R} [so : SpectralOrderedCarrier R] (v : Vec R) : Prop :=
  vecSum v = czero

/-! ## Sums: additivity and negation -/

/-- Finite sums are additive. -/
@[proof] theorem finSum_add {R} [so : SpectralOrderedCarrier R]
    (f g : Vec R) :
    finSum f + finSum g =
      finSum (fun i => f i + g i) := by
  have key : ∀ (m : Nat) (h : m ≤ dim),
      sumGo f m h + sumGo g m h
        = sumGo (fun i => f i + g i) m h := by
    intro m
    induction m with
    | zero => intro _; exact cadd_czero_czero
    | succ k ih =>
        intro h
        have eL := sumGo_succ f k h
        have eR := sumGo_succ g k h
        have eP := sumGo_succ (fun i => f i + g i) k h
        show sumGo f (k+1) h + sumGo g (k+1) h = _
        rw [eP, ← ih (Nat.le_trans (Nat.le_succ k) h), eL, eR]
        generalize ha : sumGo f k (Nat.le_trans (Nat.le_succ k) h) = a
        generalize hb : sumGo g k (Nat.le_trans (Nat.le_succ k) h) = b
        generalize hxf :
          f ⟨k, Nat.lt_of_lt_of_le (Nat.lt_succ_self k) h⟩ = xf
        generalize hxg :
          g ⟨k, Nat.lt_of_lt_of_le (Nat.lt_succ_self k) h⟩ = xg
        calc (a + xf) + (b + xg)
            = a + (xf + (b + xg)) := so.add_assoc _ _ _
          _ = a + ((xf + b) + xg) := by rw [so.add_assoc]
          _ = a + ((b + xf) + xg) := by rw [so.add_comm xf b]
          _ = a + (b + (xf + xg)) := by rw [so.add_assoc]
          _ = (a + b) + (xf + xg) := (so.add_assoc a b _).symm
  show sumGo f dim (Nat.le_refl dim) + sumGo g dim (Nat.le_refl dim) = _
  rw [key dim (Nat.le_refl dim)]
  rfl

/-- Entry-sum version of additivity. -/
@[proof] theorem vecSum_add {R} [so : SpectralOrderedCarrier R]
    (f g : Vec R) :
    vecSum f + vecSum g = vecSum (fun i => f i + g i) :=
  finSum_add f g

/-- Finite sums commute with negation. -/
@[proof] theorem finSum_neg {R} [so : SpectralOrderedCarrier R]
    (f : Vec R) :
    so.toNeg.neg (finSum f) = finSum (fun i => so.toNeg.neg (f i)) := by
  have key : ∀ (m : Nat) (h : m ≤ dim),
      so.toNeg.neg (sumGo f m h) = sumGo (fun i => so.toNeg.neg (f i)) m h := by
    intro m
    induction m with
    | zero =>
        intro _
        show so.toNeg.neg czero = czero
        exact @cneg_czero R so
    | succ k ih =>
        intro h
        have eL := sumGo_succ f k h
        have eR := sumGo_succ (fun i => so.toNeg.neg (f i)) k h
        show so.toNeg.neg (sumGo f (k+1) h) = _
        rw [eL, eR, cneg_add, ih (Nat.le_trans (Nat.le_succ k) h)]
  show so.toNeg.neg (sumGo f dim (Nat.le_refl dim)) = _
  rw [key dim (Nat.le_refl dim)]
  rfl

/-! ## The hyperplane -/

/-- Unit spike at index `i` with value `x`. -/
@[adr] def unitAt {R} [so : SpectralOrderedCarrier R] (i : Fin dim) (x : R) :
    Vec R := fun j => if _h : j.val = i.val then x else czero

@[proof] theorem finSum_unitAt {R} [so : SpectralOrderedCarrier R]
    (i : Fin dim) (x : R) : finSum (unitAt i x) = x := by
  have hx : unitAt i x i = x := by
    show (if _h : i.val = i.val then x else czero) = x
    rw [dif_pos rfl]
  refine @Eq.trans R (finSum (unitAt i x)) (unitAt i x i) x
    (@finSum_single R so (unitAt i x) i
      (fun j hj => by
        show (if _h : j.val = i.val then x else czero) = czero
        rw [dif_neg (fun e => hj (Fin.ext e))])) hx

private theorem hdim_pos : (0:Nat) < dim := by
  show (0:Nat) < 9
  omega

private theorem hmode_dim (k : ZeroMode) : k.val + 1 < dim := by
  show k.val + 1 < 9
  have hk : k.val < 8 := k.isLt
  omega

/-- Difference-basis generator `e_0 - e_{k+1}` of the hyperplane,
defined directly as the signed pair of unit spikes. -/
@[adr] def basisDiff {R} [so : SpectralOrderedCarrier R] (k : ZeroMode) :
    Vec R :=
  fun i =>
    so.toAdd.add (unitAt ⟨0, hdim_pos⟩ so.carOne i)
      (unitAt ⟨k.val + 1, hmode_dim k⟩
        (so.toNeg.neg so.carOne) i)

@[proof] theorem vecSum_unitAt {R} [so : SpectralOrderedCarrier R]
    (i : Fin dim) (x : R) : vecSum (unitAt i x) = x :=
  @finSum_unitAt R so i x

/-- Every difference-basis generator lies in the hyperplane. -/
@[proof] theorem basisDiff_inSumZero {R} [so : SpectralOrderedCarrier R]
    (k : ZeroMode) :
    inSumZero (R := R) (basisDiff (R := R) k) := by
  have h1 : @vecSum R so
        (fun i => unitAt ((⟨0, hdim_pos⟩ : Fin dim)) so.carOne i)
      = so.carOne :=
    @finSum_unitAt R so ((⟨0, hdim_pos⟩ : Fin dim)) so.carOne
  have h2 : @vecSum R so (fun i =>
        unitAt ((⟨k.val + 1, hmode_dim k⟩ : Fin dim))
          (so.toNeg.neg so.carOne) i)
      = so.toNeg.neg so.carOne :=
    @finSum_unitAt R so ((⟨k.val + 1, hmode_dim k⟩ : Fin dim))
      (so.toNeg.neg so.carOne)
  have hb : @vecSum R so (fun i =>
        so.toAdd.add
          (unitAt ((⟨0, hdim_pos⟩ : Fin dim)) so.carOne i)
          (unitAt ((⟨k.val + 1, hmode_dim k⟩ : Fin dim))
            (so.toNeg.neg so.carOne) i))
      = so.toAdd.add (@vecSum R so
          (fun i => unitAt ((⟨0, hdim_pos⟩ : Fin dim)) so.carOne i))
        (@vecSum R so (fun i =>
          unitAt ((⟨k.val + 1, hmode_dim k⟩ : Fin dim))
            (so.toNeg.neg so.carOne) i)) :=
    Eq.symm (finSum_add _ _)
  show @vecSum R so (fun i =>
      so.toAdd.add
        (unitAt ((⟨0, hdim_pos⟩ : Fin dim)) so.carOne i)
        (unitAt ((⟨k.val + 1, hmode_dim k⟩ : Fin dim))
          (so.toNeg.neg so.carOne) i)) = czero
  rw [hb, h1, h2]
  exact so.add_left_neg so.carOne

/-- The hyperplane is closed under pointwise addition. -/
@[proof] theorem inSumZero_add {R} [so : SpectralOrderedCarrier R]
    {v w : Vec R} (hv : inSumZero v) (hw : inSumZero w) :
    inSumZero (fun i => v i + w i) := by
  unfold inSumZero vecSum at *
  rw [← finSum_add, hv, hw]
  exact cadd_czero_czero

/-- The hyperplane is closed under negation. -/
@[proof] theorem inSumZero_neg {R} [so : SpectralOrderedCarrier R]
    {v : Vec R} (hv : inSumZero v) :
    inSumZero (fun i => so.toNeg.neg (v i)) := by
  unfold inSumZero vecSum at *
  rw [← finSum_neg, hv]
  exact cneg_czero

/-! ## Quadratic-form congruence -/

/-- Matrix–vector products agree on pointwise-equal vectors. -/
@[proof] theorem mulMV_congr {R} [so : SpectralOrderedCarrier R]
    {M : Mat R} {v w : Vec R} (h : ∀ i, v i = w i) :
    ∀ i, mulMV M v i = mulMV M w i :=
  fun i => finSum_congr (fun j => by rw [h j])

/-- Quadratic forms agree on pointwise-equal vectors. -/
@[proof] theorem quadMat_congr {R} [so : SpectralOrderedCarrier R]
    {M : Mat R} {v w : Vec R} (h : ∀ i, v i = w i) :
    quadMat M v = quadMat M w := by
  show finSum (fun i => v i * mulMV M v i)
      = finSum (fun i => w i * mulMV M w i)
  exact finSum_congr (fun i => by rw [h i, mulMV_congr h i])

/-! ## Proxy-kernel symmetry (unconditional) -/

/-- The proxy kernel is symmetric. -/
@[proof] theorem proxyKernel_sym {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (pc : ProxyCoupling R) (α β : R)
    (i j : Fin dim) :
    proxyKernel pc α β i j = proxyKernel pc α β j i := by
  unfold proxyKernel
  cases toModeOpt i with
  | none =>
      cases toModeOpt j with
      | none => rfl
      | some _ => rfl
  | some ni =>
      cases toModeOpt j with
      | none => rfl
      | some nj =>
          show so.toAdd.add (α * (c ni * c nj))
                (so.toNeg.neg (β * (pc.s ni * pc.s nj)))
              = so.toAdd.add (α * (c nj * c ni))
                (so.toNeg.neg (β * (pc.s nj * pc.s ni)))
          rw [so.mul_comm (c ni) (c nj),
            so.mul_comm (pc.s ni) (pc.s nj)]

/-! ## The signature condition (hypothesis interface) -/

/-- Numerical-to-formal bridge: the *signature condition* of
ADR-0034-F1 §4.3 — the proxy kernel restricts to a positive-definite
form on the sum-zero hyperplane, certified numerically on the
difference basis `{e_0 - e_{k+1}}`.  Basis positivity is the part
checked in numerics; its extension to all of `H` is the remaining
analytic step and is carried as an explicit hypothesis, not a
theorem. -/
@[adr] structure ProxySignatureHypothesis
    {R} [so : SpectralOrderedCarrier R] [se : SpectralExpCarrier R]
    (pc : ProxyCoupling R) (α β : R) : Prop where
  /-- The form is positive on every difference-basis generator. -/
  basis_pos : ∀ k : ZeroMode,
    so.carLe czero (quadMat (proxyKernel pc α β) (basisDiff k)) ∧
      ¬ so.carLe (quadMat (proxyKernel pc α β) (basisDiff k)) czero
  /-- Extension obligation (documented): positivity on the basis
  extends to all nonzero vectors of `H`. -/
  extends_to_hyperplane : True

end ComplexKappa.SpectralAttractor
