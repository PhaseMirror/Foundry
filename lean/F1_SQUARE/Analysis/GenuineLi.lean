/-
F1 square — v0.19.0 stage E, the closure push (part 2): **THE GENUINE LI SEQUENCE IN
CLOSED FORM** — constructed modulo the Stieltjes tail, with the built slices as anchors.

THE REMAINING OPEN OBJECT, CONTRACTED. The arithmetic side of the Bombieri–Lagarias
split has the exact closed form [CLASSICAL, deep-research-verified — BL JNT 77 (1999)
Thm 2 via Voros eq. 20 / Lagarias eq. (4.8); NO alternating sign — the alternating
variant in the arXiv print of Lagarias eq. (4.13) is a known typo, pinned]:

    `λₙ^{arith} = −Σ_{j=1}^n C(n,j) · η_{j−1}`    (standard η-convention:
    `−ζ′/ζ(s+1) = 1/s + Σ ηⱼ sʲ`; `η₀ = −γ`, `η₁ = γ² + 2γ₁`),

verified here against BOTH mechanized slices (`λ₁^{arith} = −η₀ = γ`,
`λ₂^{arith} = −(2η₀ + η₁) = 2γ − (γ² + 2γ₁)` — `genuineArith_one/two` below are
theorems, not numerics). The η-data through `η₁` is BUILT (`γ`, `γ₁` certified); the
tail `η₂, η₃, …` needs the higher Stieltjes constants `γ₂, γ₃, …` — each a
`GammaOne`-scale dyadic mechanization, not yet built. So the construction is
parameterized by a `StieltjesEta`: any η-family whose first two values are PROVEN equal
to the built ones. (CONVENTION GUARD: the Coffey η-recursion transcribed from research
is in Coffey's own normalization and was NOT used — the closed form above is anchored
to the two mechanized slices instead, the safe route past the Maslanka-style traps.)

WHAT IS NOW CONSTRUCTED. For any such η-data:
  • `genuineArithSeq eta`  — the arithmetic side, every `n`, one definition;
  • `genuineLamSeq eta n = genuineArithSeq eta n + genuineArchSeq n` — **the genuine Li
    sequence in closed form**, every `n`;
  • `weilTraceGenuine`     — the FULL-LADDER explicit-formula trace with closed forms on
    every side, at every positive index (the trace identity is definitional — the split
    IS the definition, as it is classically);
  • `genuineLam_one/two`   — the closed-form sequence MEETS the certified values
    (`≈ λ₁`, `≈ λ₂` — through `Rlambda1/2_decomposition`), so the certified head
    transfers: `genuineLam_head` (`Pos` at `n = 1, 2`) is a THEOREM of the closed form.

THE HONEST BOUNDARY, exact. `etaTwoSlice` (the inhabiting instance) carries the two
built values and `0` beyond — its `n ≥ 3` outputs are TRUNCATIONS, not the genuine
`λₙ` (faithfulness caution (d): truncations are never the object); nothing beyond the
anchors is used from it, and no positivity is asserted at `n ≥ 3` for any instance.
The GENUINE instance needs the genuine η-tail — open data, constructible one `γⱼ` at a
time by the established `GammaOne` pattern. With this module the crux's open content is
pinned to exactly TWO inputs (see `Square.crux_genuine_route`): the genuine η-tail, and
one bound between the two closed forms from `n = 3` on — the bound that exists iff RH.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.ArchTrend
import F1Square.Analysis.LiComplete
import F1Square.Li

namespace UOR.Bridge.F1Square.Analysis

/-- **Stieltjes η-data with the built anchors**: an η-family whose first two values are
    PROVEN equal to the mechanized `η₀ = −γ` and `η₁ = γ² + 2γ₁` (in the forms the
    v0.14.0/v0.16.0 slices built). The genuine instance's tail is the open data
    (`γ₂, γ₃, …`). -/
structure StieltjesEta where
  /-- the η-family (`ηⱼ` at index `j`) -/
  eta : Nat → Real
  /-- anchor: `η₀ = −γ` (the built Euler–Mascheroni) -/
  eta_zero : Req (eta 0) (Rneg Rgamma_h)
  /-- anchor: `η₁ = γ² + 2γ₁` (the built `γ`, `γ₁`) -/
  eta_one : Req (eta 1)
    (Radd (Rmul Rgamma_h Rgamma_h) (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1))

/-- The partial sum `Σ_{i=1}^{j} C(n,i)·η_{i−1}` (binomial weights as `nsmulR` —
    pure `Radd`, no scalar layer). -/
def arithTail (eta : Nat → Real) (n : Nat) : Nat → Real
  | 0 => zero
  | (j + 1) => Radd (arithTail eta n j) (nsmulR (choose n (j + 1)) (eta j))

/-- **The genuine arithmetic side, every `n`**: `λₙ^{arith} = −Σ_{j=1}^n C(n,j)·η_{j−1}`
    (module docstring for provenance and the convention guard). -/
def genuineArithSeq (eta : Nat → Real) (n : Nat) : Real :=
  Rneg (arithTail eta n n)

/-- **THE GENUINE LI SEQUENCE IN CLOSED FORM, every `n`**:
    `λₙ = λₙ^{arith} + λₙ^{∞}` with both sides closed forms — the split IS the
    definition, exactly as it is classically. -/
def genuineLamSeq (eta : Nat → Real) (n : Nat) : Real :=
  Radd (genuineArithSeq eta n) (genuineArchSeq n)

-- ===========================================================================
-- The consistency anchors: the closed form meets the built slices, as theorems.
-- ===========================================================================

/-- **Consistency at `n = 1`**: `−C(1,1)·η₀ = γ = λ₁^{arith}` (the v0.15.3 slice). -/
theorem genuineArith_one (E : StieltjesEta) :
    Req (genuineArithSeq E.eta 1) Rlambda1_arith := by
  show Req (Rneg (Radd zero (E.eta 0))) Rgamma_h
  refine Req_trans (Rneg_congr (Req_trans (Radd_comm zero (E.eta 0)) (Radd_zero _))) ?_
  exact Req_trans (Rneg_congr E.eta_zero) (Rneg_Rneg Rgamma_h)

/-- **Consistency at `n = 2`**: `−(2η₀ + η₁) = 2γ − (γ² + 2γ₁) = λ₂^{arith}`
    (the v0.18.0 slice). -/
theorem genuineArith_two (E : StieltjesEta) :
    Req (genuineArithSeq E.eta 2) Rlambda2_arith := by
  show Req (Rneg (Radd (Radd zero (Radd (E.eta 0) (E.eta 0))) (E.eta 1))) Rlambda2_arith
  refine Req_trans (Rneg_congr (Radd_congr
    (Req_trans (Radd_comm zero (Radd (E.eta 0) (E.eta 0))) (Radd_zero _))
    (Req_refl (E.eta 1)))) ?_
  refine Req_trans (Rneg_Radd (Radd (E.eta 0) (E.eta 0)) (E.eta 1)) ?_
  refine Radd_congr ?_ (Rneg_congr E.eta_one)
  refine Req_trans (Rneg_Radd (E.eta 0) (E.eta 0)) ?_
  exact Radd_congr
    (Req_trans (Rneg_congr E.eta_zero) (Rneg_Rneg Rgamma_h))
    (Req_trans (Rneg_congr E.eta_zero) (Rneg_Rneg Rgamma_h))

/-- **The closed form meets the certified `λ₁`**: `genuineLamSeq eta 1 ≈ Rlambda1`
    (through the v0.15.3 decomposition). -/
theorem genuineLam_one (E : StieltjesEta) :
    Req (genuineLamSeq E.eta 1) Rlambda1 :=
  Req_trans (Radd_congr (genuineArith_one E) genuineArch_one)
    (Req_symm Rlambda1_decomposition)

/-- **The closed form meets the certified `λ₂`**: `genuineLamSeq eta 2 ≈ Rlambda2`
    (through the v0.18.0 decomposition). -/
theorem genuineLam_two (E : StieltjesEta) :
    Req (genuineLamSeq E.eta 2) Rlambda2 :=
  Req_trans (Radd_congr (genuineArith_two E) genuineArch_two)
    (Req_symm Rlambda2_decomposition)

/-- **The certified head transfers to the closed form**: the first two values of the
    genuine-form Li sequence are strictly positive — a THEOREM of the closed form (via
    the certified `Pos λ₁`, `Pos λ₂`), for ANY anchored η-data. -/
theorem genuineLam_head (E : StieltjesEta) :
    Pos (genuineLamSeq E.eta 1) ∧ Pos (genuineLamSeq E.eta 2) :=
  ⟨Pos_congr (Req_symm (genuineLam_one E)) Rlambda1_pos,
   Pos_congr (Req_symm (genuineLam_two E)) Rlambda2_pos⟩

-- ===========================================================================
-- The full-ladder trace, and the inhabiting instance.
-- ===========================================================================

/-- **The full-ladder Weil trace with closed forms on every side**: the explicit-formula
    trace identity holds at EVERY positive index definitionally — the split is the
    definition, exactly as classically `λₙ` is DEFINED through the explicit formula. -/
def weilTraceGenuine (E : StieltjesEta) : WeilTrace where
  zeroSide := genuineLamSeq E.eta
  primePart := genuineArithSeq E.eta
  archPart := genuineArchSeq
  trace := fun _ _ => Req_refl _

/-- The inhabiting η-instance: the two built values, `0` beyond. ITS `n ≥ 3` OUTPUTS ARE
    TRUNCATIONS, not the genuine `λₙ` (faithfulness caution (d)) — it exists to show the
    structure is real; nothing beyond the anchors is used from it. -/
def etaTwoSlice : StieltjesEta where
  eta := fun n => match n with
    | 0 => Rneg Rgamma_h
    | 1 => Radd (Rmul Rgamma_h Rgamma_h) (Rmul (ofQ ⟨2, 1⟩ (by decide)) Rgamma1)
    | _ + 2 => zero
  eta_zero := Req_refl _
  eta_one := Req_refl _

end UOR.Bridge.F1Square.Analysis
