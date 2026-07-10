/-
F1 square — **the functional-equation reflection, formalized at the Li growth-ratio level**: the
mirror symmetry `ρ ↔ 1−ρ` of the Riemann ξ-zeros, realized as an exact identity on the squared
moduli that govern the Li coefficients — and its consequence for the witness's closed-disk condition.

The completed ζ (the ξ-function) has its zeros symmetric under `s ↦ 1−s`: if `ρ` is a zero, so is
`1−ρ`. THIS FILE turns that symmetry into constructive algebra on the two squared moduli of
`ZeroGeometry` — `cnormSq ρ = |ρ|²` and `csubOneNormSq ρ = |ρ−1|²`, whose ratio `r(ρ) = |ρ−1|²/|ρ|²`
is the squared modulus of the zero's Cayley factor `1−1/ρ` (the per-zero Li growth factor). The exact
reflection identities (no `sqrt`, pure `Real` algebra via `Rneg_sq`/`Rneg_Rsub`):

    cnormSq (1−ρ)        =  csubOneNormSq ρ          (|1−ρ|²   = |ρ−1|²)
    csubOneNormSq (1−ρ)  =  cnormSq ρ                (|(1−ρ)−1|² = |ρ|²),

so the two mirror ratios are RECIPROCAL: `r(ρ)·r(1−ρ) = 1`. THE CONSEQUENCE (`mirror_both_in_disk_iff`):
a zero AND its mirror BOTH lie in the closed unit disk of Cayley factors (`|w|² ≤ 1`, i.e.
`csubOneNormSq ≤ cnormSq`, the witness's per-zero hypothesis in `RHWitness`) **iff** `|ρ−1|² = |ρ|²` —
the Cayley factor of UNIT modulus, which is exactly the on-the-line condition (`liRatio_on_line`).

WHY THIS MATTERS (and what it does NOT do). This is the THEOREM behind the remark in
`rh_witness_onLine`: the reciprocal-ratio constraint means the half-plane witness hypothesis
(`|w|² ≤ 1`) cannot be met by BOTH members of an off-line mirror pair — one factor is forced strictly
OUTSIDE the disk. So the closed-disk witness applied to the full (reflection-closed) zero set forces
every zero onto the line; it does not secretly weaken RH. It also does NOT prove the zeros are in the
disk — WHERE the zeros sit is RH, untouched. The crux fields stay `none`. This is the
functional-equation facet of the Atlas connected to the witness, formalized; novelty: the reflection
identity for the Li growth ratio.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.ZeroGeometry

namespace UOR.Bridge.F1Square.Analysis

/-- The functional-equation **reflection** `ρ ↦ 1−ρ` (real part `1−Re ρ`, imaginary part `−Im ρ`). -/
def Creflect (z : Complex) : Complex := ⟨Rsub one z.re, Rneg z.im⟩

/-- **Reflection identity I**: `|1−ρ|² = |ρ−1|²` — the reflected point's squared modulus is the
    original's `csubOneNormSq`. (`(1−r)² = (r−1)²` by `Rneg_Rsub`+`Rneg_sq`; `(−i)² = i²` by `Rneg_sq`.) -/
theorem cnormSq_Creflect (z : Complex) : Req (cnormSq (Creflect z)) (csubOneNormSq z) := by
  show Req (Radd (Rmul (Rsub one z.re) (Rsub one z.re)) (Rmul (Rneg z.im) (Rneg z.im)))
           (Radd (Rmul (Rsub z.re one) (Rsub z.re one)) (Rmul z.im z.im))
  refine Radd_congr ?_ (Rneg_sq z.im)
  have hneg : Req (Rsub one z.re) (Rneg (Rsub z.re one)) := Req_symm (Rneg_Rsub z.re one)
  exact Req_trans (Rmul_congr hneg hneg) (Rneg_sq (Rsub z.re one))

/-- **Reflection identity II**: `|(1−ρ)−1|² = |ρ|²` — the reflected point's `csubOneNormSq` is the
    original's squared modulus. (`(1−r)−1 = −r`, then `(−r)² = r²` by `Rneg_sq`.) -/
theorem csubOneNormSq_Creflect (z : Complex) : Req (csubOneNormSq (Creflect z)) (cnormSq z) := by
  show Req (Radd (Rmul (Rsub (Rsub one z.re) one) (Rsub (Rsub one z.re) one)) (Rmul (Rneg z.im) (Rneg z.im)))
           (Radd (Rmul z.re z.re) (Rmul z.im z.im))
  refine Radd_congr ?_ (Rneg_sq z.im)
  have e1 : Req (Rsub (Rsub one z.re) one) (Rneg z.re) := by
    show Req (Radd (Radd one (Rneg z.re)) (Rneg one)) (Rneg z.re)
    refine Req_trans (Radd_congr (Radd_comm one (Rneg z.re)) (Req_refl (Rneg one))) ?_
    refine Req_trans (Radd_assoc (Rneg z.re) one (Rneg one)) ?_
    exact Req_trans (Radd_congr (Req_refl (Rneg z.re)) (Radd_neg one)) (Radd_zero (Rneg z.re))
  exact Req_trans (Rmul_congr e1 e1) (Rneg_sq z.re)

/-- A zero is **in the closed Cayley disk** when its growth ratio is `≤ 1`: `|ρ−1|² ≤ |ρ|²` — i.e. its
    Cayley factor `1−1/ρ` has `|w|² ≤ 1` (the per-zero hypothesis of the `RHWitness` half-plane
    witness, in division-free form). By `liRatio_right_of_line`/`liRatio_on_line` this is `Re ρ ≥ ½`. -/
def InClosedDisk (z : Complex) : Prop := Rle (csubOneNormSq z) (cnormSq z)

/-- **THE MIRROR CONSTRAINT (the reflection facet meets the witness).** A zero and its
    functional-equation mirror BOTH lie in the closed Cayley disk **iff** the squared moduli are equal
    — `|ρ−1|² = |ρ|²`, the Cayley factor of UNIT modulus (the on-line condition, `liRatio_on_line`).
    The reciprocal-ratio identities force it: `InClosedDisk (1−ρ)` says `|ρ|² ≤ |ρ−1|²`, the reverse
    inequality, so both together pin equality (`Rle_antisymm`). Hence an OFF-line mirror pair can never
    both satisfy the witness hypothesis — exactly why the half-plane witness, on the
    reflection-closed zero set, forces the line. It does not prove the zeros are there; the crux
    fields stay `none`. -/
theorem mirror_both_in_disk_iff (z : Complex) :
    (InClosedDisk z ∧ InClosedDisk (Creflect z)) ↔ Req (csubOneNormSq z) (cnormSq z) := by
  constructor
  · intro h
    have hrev : Rle (cnormSq z) (csubOneNormSq z) :=
      Rle_trans (Rle_of_Req (Req_symm (csubOneNormSq_Creflect z)))
        (Rle_trans h.2 (Rle_of_Req (cnormSq_Creflect z)))
    exact Rle_antisymm h.1 hrev
  · intro heq
    refine ⟨Rle_of_Req heq, ?_⟩
    exact Rle_trans (Rle_of_Req (csubOneNormSq_Creflect z))
      (Rle_trans (Rle_of_Req (Req_symm heq)) (Rle_of_Req (Req_symm (cnormSq_Creflect z))))

/-- **On the line ⟹ the whole mirror pair is in the disk.** If `Re ρ = ½`, both `ρ` and `1−ρ` have
    Cayley factors in the closed disk (unit modulus). This is the forward content the witness consumes;
    the converse (in-disk ⟹ on line for the pair) is the squared-modulus equality `mirror_both_in_disk_iff`,
    whose discharge for the actual zero set is RH. -/
theorem onLine_mirror_in_disk (z : Complex) (h : OnCriticalLine z) :
    InClosedDisk z ∧ InClosedDisk (Creflect z) :=
  (mirror_both_in_disk_iff z).mpr (liRatio_on_line z h)

-- ===========================================================================
-- The OTHER symmetry: complex conjugation `ρ ↦ ρ̄`. Together with the reflection it generates the
-- full 4-fold symmetry group `{ρ, ρ̄, 1−ρ, 1−ρ̄}` of the completed-ζ zeros.
-- ===========================================================================

/-- Complex **conjugation** `ρ ↦ ρ̄` (same real part, negated imaginary part) — the second generator
    of the ξ-zero symmetry group (`ζ(s̄) = conj ζ(s)`). -/
def Cconj (z : Complex) : Complex := ⟨z.re, Rneg z.im⟩

/-- **Conjugation preserves the modulus**: `|ρ̄|² = |ρ|²` (`(−i)² = i²`, `Rneg_sq`). -/
theorem cnormSq_Cconj (z : Complex) : Req (cnormSq (Cconj z)) (cnormSq z) :=
  Radd_congr (Req_refl (Rmul z.re z.re)) (Rneg_sq z.im)

/-- **Conjugation preserves `csubOneNormSq`**: `|ρ̄−1|² = |ρ−1|²`. -/
theorem csubOneNormSq_Cconj (z : Complex) : Req (csubOneNormSq (Cconj z)) (csubOneNormSq z) :=
  Radd_congr (Req_refl (Rmul (Rsub z.re one) (Rsub z.re one))) (Rneg_sq z.im)

/-- **Conjugation preserves disk-membership**: `ρ̄` is in the closed Cayley disk iff `ρ` is. So a zero
    and its conjugate sit on the SAME side of the line — conjugation adds no obstruction, unlike the
    reflection (`mirror_both_in_disk_iff`), which flips the side. -/
theorem inClosedDisk_Cconj (z : Complex) : InClosedDisk (Cconj z) ↔ InClosedDisk z := by
  unfold InClosedDisk
  constructor
  · intro h
    exact Rle_trans (Rle_of_Req (Req_symm (csubOneNormSq_Cconj z)))
      (Rle_trans h (Rle_of_Req (cnormSq_Cconj z)))
  · intro h
    exact Rle_trans (Rle_of_Req (csubOneNormSq_Cconj z))
      (Rle_trans h (Rle_of_Req (Req_symm (cnormSq_Cconj z))))

/-- **THE SYMMETRY GROUP MEETS THE WITNESS**: for the ξ-zero symmetry orbit, the zero, its conjugate,
    and its reflection ALL lie in the closed Cayley disk **iff** `|ρ−1|² = |ρ|²` — unit modulus, the
    on-line condition. Conjugation is automatic (same side); the reflection is the binding leg. So the
    half-plane witness can hold across the full symmetry orbit only on the critical line — the
    structural reason RH's "all zeros in the disk" is equivalent to "all zeros on the line", realized
    constructively on the Li growth ratio. It does not prove the zeros are there; the crux fields stay
    `none`. -/
theorem symmetry_orbit_in_disk_iff (z : Complex) :
    (InClosedDisk z ∧ InClosedDisk (Cconj z) ∧ InClosedDisk (Creflect z))
      ↔ Req (csubOneNormSq z) (cnormSq z) := by
  constructor
  · intro h; exact (mirror_both_in_disk_iff z).mp ⟨h.1, h.2.2⟩
  · intro heq
    have hpair := (mirror_both_in_disk_iff z).mpr heq
    exact ⟨hpair.1, (inClosedDisk_Cconj z).mpr hpair.1, hpair.2⟩

-- ===========================================================================
-- The off-line branch of the Voros dichotomy, constructively: a zero left of the line leaves the disk.
-- ===========================================================================

/-- **A zero LEFT of the critical line leaves the closed Cayley disk** — proven, no interface: `Re z < ½`
    forces `|z−1|² > |z|²` (`liRatio_left_of_line`), i.e. its Cayley factor has `|w|² > 1`, so the
    witness's per-zero hypothesis `InClosedDisk` FAILS. This is the constructive geometric seed of the
    Voros dichotomy's off-line branch: the only thing left to the `[CLASSICAL]` saddle-point is that a
    factor outside the disk forces some `λₙ < 0` — the geometry itself is a theorem here. -/
theorem offLine_left_not_inClosedDisk (z : Complex) (h : Pos (Rsub half z.re)) :
    ¬ InClosedDisk z := fun hin =>
  not_Pos_of_Rnonneg_neg
    (Rnonneg_congr (Req_symm (Rneg_Rsub (csubOneNormSq z) (cnormSq z)))
      (Rnonneg_Rsub_of_Rle hin))
    (liRatio_left_of_line z h)

/-- **The geometric dichotomy meets the witness**: on the line the Cayley factor is in the closed disk
    (`liRatio_on_line` ⟹ `InClosedDisk`), and left of the line it is not
    (`offLine_left_not_inClosedDisk`). So the witness's hypothesis tracks position exactly — the only
    zeros it fails to cover are the genuinely off-line (left) ones. -/
theorem inClosedDisk_iff_geom (z : Complex) :
    (OnCriticalLine z → InClosedDisk z) ∧ (Pos (Rsub half z.re) → ¬ InClosedDisk z) :=
  ⟨fun h => Rle_of_Req (liRatio_on_line z h), offLine_left_not_inClosedDisk z⟩

-- ===========================================================================
-- The on-line CHARACTERIZATION (the converse of `liRatio_on_line`) and the SET-LEVEL closure:
-- on a reflection-closed zero set, the closed-disk witness hypothesis is EQUIVALENT to RH.
-- ===========================================================================

/-- `half·(x + x) = x` — halving the double. (`half·(x+x) = half·x + half·x = (half+half)·x = 1·x = x`,
    via `half_add_half`.) The arithmetic core of doubling-injectivity. -/
private theorem half_double (x : Real) : Req (Rmul half (Radd x x)) x :=
  Req_trans (Rmul_distrib half x x)
    (Req_trans (Req_symm (Rmul_distrib_right half half x))
      (Req_trans (Rmul_congr half_add_half (Req_refl x))
        (Req_trans (Rmul_comm one x) (Rmul_one x))))

/-- **Doubling is injective**: `x + x = y + y ⟹ x = y` (multiply both sides by `½`, `half_double`).
    The constructive replacement for "divide by 2". -/
theorem double_inj {x y : Real} (h : Req (Radd x x) (Radd y y)) : Req x y :=
  Req_trans (Req_symm (half_double x))
    (Req_trans (Rmul_congr (Req_refl half) h) (half_double y))

/-- **The on-line characterization — the converse of `liRatio_on_line`**: `|ρ−1|² = |ρ|² ⟹ Re ρ = ½`.
    The growth-ratio identity gives `|ρ−1|² − |ρ|² = 1 − 2·Re ρ`; equality forces `2·Re ρ = 1 = 2·½`,
    so `Re ρ = ½` by doubling-injectivity. Together with `liRatio_on_line` this makes unit Cayley
    modulus EQUIVALENT to being on the critical line. -/
theorem onLine_of_ratios_eq (z : Complex) (h : Req (csubOneNormSq z) (cnormSq z)) :
    OnCriticalLine z := by
  have hz : Req (Rsub (csubOneNormSq z) (cnormSq z)) zero :=
    Req_trans (Radd_congr h (Req_refl _)) (Radd_neg (cnormSq z))
  have h2 : Req one (Radd z.re z.re) :=
    Req_of_Rsub_zero (Req_trans (Req_symm (liRatio_diff_eq z)) hz)
  exact double_inj (Req_trans (Req_symm h2) (Req_symm half_add_half))

/-- **Unit Cayley modulus ⟺ on the critical line** — the two directions packaged
    (`liRatio_on_line` and `onLine_of_ratios_eq`). -/
theorem onLine_iff_ratios_eq (z : Complex) :
    OnCriticalLine z ↔ Req (csubOneNormSq z) (cnormSq z) :=
  ⟨liRatio_on_line z, onLine_of_ratios_eq z⟩

/-- A zero set is **reflection-closed** when it contains the functional-equation mirror `1−ρ` of each
    of its members — the genuine ξ-zero set is (`ξ(s) = ξ(1−s)`). -/
def ReflClosed (isZero : Complex → Prop) : Prop := ∀ z, isZero z → isZero (Creflect z)

/-- **THE SET-LEVEL CLOSURE — the closed-disk witness hypothesis IS RH (on a reflection-closed set).**
    For a reflection-closed zero set, "every zero's Cayley factor lies in the closed disk `|w|² ≤ 1`"
    (the half-plane witness hypothesis of `RHWitness`) is EQUIVALENT to "every zero on the critical
    line" (`AllZerosOnLine`). Forward: each `z` and its mirror `1−ρ` are both zeros, both in the disk,
    so `mirror_both_in_disk_iff` pins `|ρ−1|² = |ρ|²`, hence `Re ρ = ½` (`onLine_of_ratios_eq`).
    Reverse: on the line the factor is in the disk (`liRatio_on_line`). This upgrades the per-zero
    `rh_witness_onLine` remark to a SET-level theorem — the closed-disk witness does not secretly
    weaken RH. It does NOT place the zeros (RH); the crux fields stay `none`. -/
theorem allInClosedDisk_iff_allOnLine (isZero : Complex → Prop) (hcl : ReflClosed isZero) :
    (∀ z, isZero z → InClosedDisk z) ↔ AllZerosOnLine isZero := by
  constructor
  · intro h z hz
    exact onLine_of_ratios_eq z
      ((mirror_both_in_disk_iff z).mp ⟨h z hz, h (Creflect z) (hcl z hz)⟩)
  · intro h z hz
    exact Rle_of_Req (liRatio_on_line z (h z hz))

end UOR.Bridge.F1Square.Analysis
