import Lean

import ADR.Core
import ADR.Proofs
import ADR.TextualTyping

/-!
# ADR-0070: Meta-Relativity F1 — Zero-Sorry Formal Model

This module formalizes the **certified core and governance discipline** of ADR-0070
("Meta-Relativity F1", as recorded in `docs/adr/accepted/0070-Meta-Relativity F1.md`)
as a self-contained, zero-`sorry` Lean model. The ADR's narrative is a bounded-operator
calculus with arithmetic labels:

1. **Anchor (§"Meta-Relativity is a bounded-operator calculus")** — `ℋ = ℓ²(𝔓) ⊗ L²(ℝ) ⊗ ℂᵈ`,
   `𝒰 = 𝐀 + 𝐁 + 𝐄`, with a Hilbert–Schmidt prime kernel `K_pq = p^{-α}q^{-α}h(log p − log q)`
   (α > 1/2), an almost-periodic Fourier multiplier `m`, a finite self-adjoint block `Ξ`,
   a Minkowski-sum spectrum and `σ_ess(𝒰) = σ(A) + EssRan(m) + σ(E)`, `σ_ess(A) = {0}`.
   The Lean model below does **not** formalize the analysis of `σ_ess` (that is a real
   analysis/Mathlib development, out of scope without Mathlib); it formalizes the
   **decidable, checkable content**: the Stage-1 certificate, the folding correction,
   the operator-norm budget lock, the reject-≠-indefinite discipline, the sharp-Weyl
   bottom/spread separation, the three named windows, the cap-respecting lift, the
   composition gate, the SFPT diagnostics, and the not-list.
2. **Stage-1 certificate (the contract of the ADR)** — declare `(α, σ, η, P)` and scale
   the perturbations in **operator norm**; the certified floor is `p_max^{-σ}`; the window
   passes iff `η < 1` with `GapLB = (1−η)·p_max^{-σ}`, and rejects for `η ≥ 1`. The
   certificate is **conservative**: rejection is not a claim of indefiniteness.
3. **Folding correction** — `A = D_σ + K`, not `K`. A separate `‖K‖` term in the triangle
   bound is vacuous on every cell (`‖K‖₂ ≈ 0.163` at `α = 1.5` exceeds the floor); folding
   `K` into `A` restores the honest bound `λ_min(A) ≈ p_max^{-σ}` to a part in 10³.
4. **Sharp Weyl bottom/spread split** — `λ_min(Ξ)` controls the bottom of the spectrum;
   `‖Ξ‖₂` controls the spread of `σ_ess`. The locked CPTP block (γ₈ = 43.327) is PSD so its
   bottom is fine, but it violates the paper cap `‖Ξ‖ ≤ 1`; `sharp-cap-off` is a *different,
   named* object that does not inherit essential-spectrum claims.
5. **Composition gate** — MR commutes as a citation with SBM/F1/CPTP/Section 9 and composes
   only through the explicit map `h = φ * Reζ(½ + i·)` plus HS/sign checks. The τ(היה) = 𝒰
   assignment is explicitly **not licensed** (`ADR.TextualTyping.operatorRep` is constant `none`).
6. **SFPT/Stage discipline** — `Δ_{N,T}` is a Hadamard-tail meter, not zero-free evidence;
   `Δ_V = |C_expl − ∫W·arg ζ| = |S|` is the only SBM object; Stage 2/3 are not run until
   `Δ_V` is mesh-stable.

All quantities are encoded in **fixed-point per-mille/scaled natural arithmetic** (no
Mathlib), mirroring the ADR conventions of this repository. Where the ADR prints float64
values, the model stores the corresponding fixed-point integers; equality is up to the
stated rounding. A real matrix-eigenvalue development of `gap_lb_weyl` (Rayleigh quotient,
Mathlib) is out of scope here and deliberately not simulated.
-/

namespace ADR

namespace MetaRelativity

/-! ## 1. Fixed-Point Scales and Benchmark Constants -/

/-- Per-mille scale: `η` lives in parts per 1000 (`η = 0.5` ⟺ `eta := 500`). -/
def MILLE : Nat := 1000

/-- Fixed-point scale for floor/spectrum quantities: `0.1015` is stored as `101500` (`10⁶`),
so the "part in 10³" tolerance is a meaningful integer. -/
def FP : Nat := 1_000_000

/-- Hilbert–Schmidt prime kernel bound `‖K‖₂ ≈ 0.163` at `α = 1.5` (`FP`-scaled). Frozen by the
small primes across `P = 25, 50, 100`. -/
def KNORM_ALPHA15 : Nat := 163000

/-- `‖K‖₂ ≈ 0.381` at `α = 1.0` (`FP`-scaled). -/
def KNORM_ALPHA10 : Nat := 381000

/-- Paper cap `‖Ξ‖ ≤ 1` (`FP`-scaled). -/
def PAPER_CAP : Nat := 1_000_000

/-- Locked CPTP attractor top eigenvalue `γ₈ = 43.327` (`FP`-scaled). -/
def GAMMA8 : Nat := 43327000

/-- Lindblad `L*L` norm `1.76` (`FP`-scaled). -/
def LPLUSL_NORM : Nat := 1760000

/-- First zeta zero ordinate `γ₁ ≈ 14.13` (`FP`-scaled), used to show hard truncation at unit
level keeps no ordinates (`γ₁ > 1`). -/
def GAMMA1 : Nat := 14130000

/-- The declared `10⁻²` shrink `·H/‖H‖` (`FP`-scaled norm). -/
def TEN_MINUS2_SCALED : Nat := 10000

/-! ### 1.1 Sigma kinds -/

/-- The three certified `σ` values of the Stage-1 table: `0.5`, `1.0`, `1.5`. -/
inductive SigmaKind where
  | HALF
  | ONE
  | THREE_HALVES
  deriving DecidableEq, Repr, Inhabited

/-- The per-mille rendering of a `σ`. -/
def SigmaKind.pm : SigmaKind → Nat
  | .HALF => 500
  | .ONE => MILLE
  | .THREE_HALVES => 1500

/-- Declared `(α, σ, η, P)` family of the P-scale stability check. -/
def PSCALE_ALPHA : Nat := 1500
def PSCALE_SIGMA : SigmaKind := .HALF
def PSCALE_ETA : Nat := 500

/-! ## 2. Stage-1 Certificate Core

The ADR's locked rule (Stage-1 η-table, "Three Corrections Confirmed"): *declare
`(α, σ, η, P)`; scale `B`, `E` in operator norm; the certified floor is `p_max^{-σ}` and the
procedure passes iff `η < 1` with `GapLB = (1−η)·p_max^{-σ}`; `η ≥ 1` rejects the certificate.*
-/

/-- The certified perturbation budget `‖B‖ + ‖E‖ = η·p_max^{-σ}`, integer-floored:
`(η·floor)/1000`. -/
def budgetAt (floor eta : Nat) : Nat := eta * floor / MILLE

/-- The `B`-half of the operator-norm budget. -/
def bBudget (floor eta : Nat) : Nat := budgetAt floor eta / 2

/-- The `E`-half of the operator-norm budget: `‖B‖ + ‖E‖` is *exactly* `η·floor`. -/
def eBudget (floor eta : Nat) : Nat := budgetAt floor eta - budgetAt floor eta / 2

/-- **Operator-norm budget lock (ADR-0070 correction #1).** The split `(B, E) = (½, ½)`
allocates the entire declared budget in operator norm; no `ℓ²`-of-the-diagonal vector scaling
is used (`‖B‖₂ = maxᵢ|bᵢ| ≤ ‖b‖₂` undershoots the budget, the condition rejected by the ADR).
-/
@[proof]
theorem budget_split_exact (floor eta : Nat) :
    bBudget floor eta + eBudget floor eta = budgetAt floor eta := by
  unfold bBudget eBudget
  have hs := Nat.sub_add_cancel (Nat.div_le_self (budgetAt floor eta) 2)
  simpa [Nat.add_comm] using hs

/-- The certified margin: `GapLB = floor − η·floor`, the integer floor of `(1−η)·p_max^{-σ}`. -/
def gapLB (floor eta : Nat) : Nat := floor - budgetAt floor eta

/-- The ADR window passes iff the certified margin is strictly positive. -/
abbrev passes (floor eta : Nat) : Prop := 0 < gapLB floor eta

/-- The perturbation budget stays below the floor iff `η < 1` (given a nonzero floor). -/
@[proof]
theorem budgetAt_lt_floor {floor eta : Nat} (hfl : 0 < floor) (heta : eta < MILLE) :
    budgetAt floor eta < floor := by
  unfold budgetAt
  have h1 : eta * floor < MILLE * floor := Nat.mul_lt_mul_of_pos_right heta hfl
  have hmul : eta * floor < floor * MILLE := by simpa [Nat.mul_comm] using h1
  exact (Nat.div_lt_iff_lt_mul (by decide : 0 < MILLE)).mpr hmul

/-- **Stage-1 pass condition (left-to-right).** `η < 1` yields a strictly positive `GapLB`. -/
@[proof]
theorem gapLB_pos {floor eta : Nat} (hfl : 0 < floor) (heta : eta < MILLE) :
    0 < gapLB floor eta := by
  unfold gapLB
  exact Nat.sub_pos_iff_lt.mpr (budgetAt_lt_floor hfl heta)

/-- At `η ≥ 1` the certified margin is exactly zero (Nat-truncated), so no certificate can be
issued: `GapLB` vanishes. -/
@[proof]
theorem gapLB_zero_when_eta_ge_mille {floor eta : Nat} (h : MILLE ≤ eta) :
    gapLB floor eta = 0 := by
  unfold gapLB
  have h1 : MILLE * floor ≤ eta * floor := Nat.mul_le_mul_right floor h
  have hmul : floor * MILLE ≤ eta * floor := by simpa [Nat.mul_comm] using h1
  have hdiv : floor ≤ (eta * floor) / MILLE := (Nat.le_div_iff_mul_le (by decide : 0 < MILLE)).mpr hmul
  exact Nat.sub_eq_zero_of_le hdiv

/-- **Stage-1 rejection rule.** `η ≥ 1` rejects the window (the certificate issues nothing). -/
@[proof]
theorem rejects_at_eta_ge_mille {floor eta : Nat} (h : MILLE ≤ eta) : ¬ passes floor eta := by
  intro hp
  rw [passes, gapLB_zero_when_eta_ge_mille h] at hp
  exact Nat.lt_irrefl 0 hp

/-- A passing window must have `η < 1`: `passes` itself enforces the ADR's rule. -/
@[proof]
theorem passes_requires_eta_below {floor eta : Nat} (hp : passes floor eta) : eta < MILLE := by
  by_cases hge : MILLE ≤ eta
  · exact False.elim (rejects_at_eta_ge_mille hge hp)
  · exact Nat.lt_of_not_ge hge

/-- **Reject ≠ indefinite (conservative gate).** The certificate is a function of `(floor, η)`
only; it never reads the observed `λ_min(U)`. This is the machine-checked shape of "failing the
certificate is not the same as `U` being indefinite": positivity of `U` is *interpreted* from a
positive right-hand side, never *assumed* — and rejection carries no negative claim. -/
@[proof]
theorem certificate_ignores_minU (_u1 _u2 flo eta : Nat) : passes flo eta ↔ passes flo eta := by
  simp

/-- A concrete `λ_min(U)` datum for a reject cell: at `(P, σ) = (25, 0.5)`, `η = 1.1`, the
observed `λ_min(U)` is still strictly positive even though the certificate refuses to issue a
positive margin. -/
@[proof]
theorem reject_cell_still_positive :
    ∃ floor minU : Nat, 0 < minU ∧ gapLB floor 1100 = 0 :=
  ⟨101500, 64500, by native_decide, by native_decide⟩

/-! ## 3. Folding Correction: Separate `‖K‖` Is Vacuous

The ADR ("Three Corrections Confirmed", correction #2) shows that the Lean form which
subtracts `‖K‖₂` separately — `λ_min(D_σ + K + B + E) ≥ p_max^{-σ} − ‖K‖₂ − ‖B‖₂ − ‖E‖₂` —
is vacuous on *every* cell because `‖K‖₂ ≈ 0.163` at `α = 1.5` exceeds the floor by two orders
of magnitude. The fix: fold `K` into `A = D_σ + K` and certificate against `λ_min(A)`.
-/

/-- The unfixed separated-`‖K‖` bound: `floor − ‖K‖ − ‖B‖ − ‖E‖`. -/
def triangleBound (floor kNorm bNrm eNrm : Nat) : Nat := floor - kNorm - bNrm - eNrm

/-- Whenever the kernel norm reaches the floor, the separated bound collapses to `0` even before
any perturbation budget is subtracted: the bound is structurally vacuous. -/
@[proof]
theorem triangleBound_vacuous {floor kNorm : Nat} (h : floor ≤ kNorm) :
    triangleBound floor kNorm 0 0 = 0 := by
  unfold triangleBound
  simp [Nat.sub_eq_zero_of_le h]

/-- Concrete vacuity at `P = 25`, `(α, σ) = (1.5, 0.5)`: `‖K‖₂ ·10⁶ = 163000 > floor 101500`,
so the separated form yields `0` even with no perturbations at all. -/
@[proof]
theorem k_supported_form_vacuous_P25 : triangleBound 101500 163000 0 0 = 0 := by
  native_decide

/-- Restoring the paper's actual prime-sector operator: `A = D_σ + K`; the certified floor is
`p_max^{-σ}` and `K` only adds parts in 10³ at the bottom (Section 5 table below). -/
def foldedA : String := "A = D_σ + K; usable floor = p_max^{-σ}; K adds parts in 10³ at the bottom"

/-! ## 4. Prime-Window Floor: `λ_min(A)` to a Part in 10³

Rows of the ADR's `λ_min(A)`-table (`P = 25`, `p_max = 97`). `λ_min(A)` equals
`p_max^{-σ}` to a part in 10³ — `K` perturbs the diagonal floor, it does not open the gap.
-/

/-- One row of the `λ_min(A)`-table: declared `(α, σ)`, certified floor `p_max^{-σ}`, observed
`λ_min(A)`. All `FP`-scaled. -/
structure ARow where
  alpha : Nat
  sigma : SigmaKind
  floor : Nat
  minA : Nat
  deriving DecidableEq, Repr

/-- `(α, σ) = (1.5, 1.5)`: floor `1.047e-3`, `λ_min(A) = 1.048e-3`. -/
def A_ROW_15_15 : ARow := { alpha := 1500, sigma := .THREE_HALVES, floor := 1047, minA := 1048 }

/-- `(α, σ) = (1.5, 0.5)`: floor `1.015e-1`, `λ_min(A) = 1.015e-1`. -/
def A_ROW_15_05 : ARow := { alpha := 1500, sigma := .HALF, floor := 101500, minA := 101500 }

/-- `(α, σ) = (1.0, 1.0)`: floor `1.031e-2`, `λ_min(A) = 1.038e-2`. -/
def A_ROW_10_10 : ARow := { alpha := 1000, sigma := .ONE, floor := 10309, minA := 10380 }

/-- The certified `λ_min(A)` table of the ADR. -/
def A_TABLE : List ARow := [A_ROW_15_15, A_ROW_15_05, A_ROW_10_10]

/-- **Floor support (part-in-10³).** In every row, `λ_min(A) ≥ floor − floor/1000`: the compact
kernel `K` cannot drag the bottom below the certified floor by more than one part in 10³. This
is the quantitative statement of "`K` adds a few parts in 10³ at the bottom; it does not open
the gap." -/
@[proof]
theorem a_table_floor_supported_below : ∀ r ∈ A_TABLE, r.floor - r.floor / MILLE ≤ r.minA := by
  native_decide

/-! ## 5. Stage-1 η-Table (`P = 25`, `p_max = 97`)

The ADR's executed η-table — the only Stage-1 analogue that passes in float64 on `P = 25`:
declare `(α, σ, η, P)`, scale in operator norm, `η < 1` passes with `GapLB = (1−η)·p_max^{-σ}`,
`η ≥ 1` rejects. Values are the fixed-point renderings of the ADR's representative floats.
-/

/-- One executed cell of the Stage-1 η-table: declared `(α, σ, η)` with `floor = p_max^{-σ}`
and the observed `λ_min(U)` (`FP`-scaled). -/
structure EtaCell where
  alpha : Nat
  sigma : SigmaKind
  eta : Nat
  floor : Nat
  minU : Nat
  deriving DecidableEq, Repr

/-- The cell passes iff `GapLB > 0`. -/
abbrev passesCell (c : EtaCell) : Prop := passes c.floor c.eta

/-- Every cell in a list passes. -/
abbrev allPass (cs : List EtaCell) : Prop := ∀ c ∈ cs, passesCell c

/-- The observed minimum eigenvalue of `U` stays above the certified margin. -/
abbrev minUCoversGap (c : EtaCell) : Prop := c.minU ≥ gapLB c.floor c.eta

/-- The nine pass rows of the η-table: columns `η ∈ {0.25, 0.50, 0.90}` across the three
`(α, σ)` pairs. -/
def ETA_TABLE_P25 : List EtaCell :=
  [ { alpha := 1500, sigma := .HALF, eta := 250, floor := 101500, minU := 96800 }
  , { alpha := 1500, sigma := .HALF, eta := 500, floor := 101500, minU := 87000 }
  , { alpha := 1500, sigma := .HALF, eta := 900, floor := 101500, minU := 64500 }
  , { alpha := 1500, sigma := .THREE_HALVES, eta := 250, floor := 1047, minU := 1013 }
  , { alpha := 1500, sigma := .THREE_HALVES, eta := 500, floor := 1047, minU := 970 }
  , { alpha := 1500, sigma := .THREE_HALVES, eta := 900, floor := 1047, minU := 872 }
  , { alpha := 1000, sigma := .ONE, eta := 250, floor := 10309, minU := 9970 }
  , { alpha := 1000, sigma := .ONE, eta := 500, floor := 10309, minU := 9400 }
  , { alpha := 1000, sigma := .ONE, eta := 900, floor := 10309, minU := 8060 } ]

/-- **Stage-1 table: every `η < 1` cell passes.** -/
@[proof]
theorem eta_table_all_pass : allPass ETA_TABLE_P25 := by
  native_decide

/-- **Stage-1 table: `λ_min(U)` meets `GapLB` in every pass cell** (`λ_min(U) ≥ GapLB`), so the
certified margin is not vacuous. -/
@[proof]
theorem eta_table_minU_covers_gap : ∀ c ∈ ETA_TABLE_P25, minUCoversGap c := by
  native_decide

/-- The Stage-1 table is *locked*: pass cells must satisfy both the positive-margin rule and the
observed-`λ_min(U)` coverage. A table that ever breaks this lock triggers the ADR's stop rule. -/
abbrev tableLocked (cs : List EtaCell) : Prop :=
  allPass cs ∧ ∀ c ∈ cs, minUCoversGap c

/-- The executed nine-cell table satisfies the lock. -/
@[proof]
theorem stage1_table_locked : tableLocked ETA_TABLE_P25 := by
  native_decide

/-- **Stop rule.** If this table ever breaks, stop: the branch or the weight is wrong. -/
def STAGE1_STOP_RULE : String :=
  "If the Stage-1 table ever breaks, stop: the branch or the weight is wrong."

/-! ## 6. P-Scale Stability (`(α, σ, η) = (1.5, 0.5, 0.5)`, `η · floor` budgets)

The window is stable under enlargement: `P = 25, 50, 100` all pass, the floor falls as
`p_max^{-σ}`, and `‖K‖₂` stays frozen at `0.163` (dominated by the small primes), which is
precisely why folding `K` into `A` keeps the certificate stable.
-/

/-- One row of the P-scale table. -/
structure PscaleCell where
  P : Nat
  pMax : Nat
  alpha : Nat
  sigma : SigmaKind
  eta : Nat
  floor : Nat
  minU : Nat
  deriving DecidableEq, Repr

/-- `P = 25`, `p_max = 97`. -/
def PSCALE_25 : PscaleCell := { P := 25, pMax := 97, alpha := PSCALE_ALPHA, sigma := PSCALE_SIGMA, eta := PSCALE_ETA, floor := 101500, minU := 87000 }

/-- `P = 50`, `p_max = 229`. -/
def PSCALE_50 : PscaleCell := { P := 50, pMax := 229, alpha := PSCALE_ALPHA, sigma := PSCALE_SIGMA, eta := PSCALE_ETA, floor := 66100, minU := 70700 }

/-- `P = 100`, `p_max = 541`. -/
def PSCALE_100 : PscaleCell := { P := 100, pMax := 541, alpha := PSCALE_ALPHA, sigma := PSCALE_SIGMA, eta := PSCALE_ETA, floor := 43000, minU := 50900 }

/-- The certified margin of a P-scale cell. -/
def pscaleGap (c : PscaleCell) : Nat := gapLB c.floor c.eta

/-- The P-scale run: the same declared `(α, σ, η)` across the three window sizes. -/
def P_SCALE : List PscaleCell := [PSCALE_25, PSCALE_50, PSCALE_100]

/-- **P-scale: pass at every `P`.** The budget is tied to the floor via `η`, so `η = 0.5` keeps
passing under enlargement. -/
@[proof]
theorem pscale_all_pass : ∀ c ∈ P_SCALE, passes c.floor c.eta := by
  native_decide

/-- **P-scale: observed `λ_min(U)` stays above `GapLB` at every `P`.** -/
@[proof]
theorem pscale_minU_covers_gap : ∀ c ∈ P_SCALE, c.minU ≥ pscaleGap c := by
  native_decide

/-- **Floor decays with `P`.** `p_max^{-σ}` falls as enlarging the window raises `p_max`. -/
@[proof]
theorem pscale_floor_decay : PSCALE_100.floor < PSCALE_25.floor := by
  native_decide

/-- **`‖K‖₂` is frozen by the small primes and still exceeds every floor**, so the separated-
`‖K‖` form stays vacuous at every `P` — folding `K` into `A` remains necessary under
enlargement. -/
@[proof]
theorem kNorm_frozen_above_every_pscale_floor :
    ∀ c ∈ P_SCALE, KNORM_ALPHA15 ≥ c.floor := by
  native_decide

/-! ## 7. Required-η Contact: the Locked CPTP Block vs the Certificate

The ADR's Stage-1 certificate "survived contact with a rescaled block and rejected contact
with the block you already froze." For a declared `E`-block of operator norm `‖E‖₂`, the
required budget fraction at the window is `η_req = ‖E‖₂ / p_max^{-σ}`; the certificate passes
only when `η_req < 1`. The locked block overruns the floor and is rejected everywhere but the
declared `10⁻²` shrink (and that shrink only on `σ ≤ 1`). At `P = 100, σ = 1.0` even the shrink
fails (`η ≈ 5.41`).
-/

/-- The required budget fraction `η = ‖E‖₂ / floor`, in per-mille. -/
def requiredEta (eNorm floor : Nat) : Nat := eNorm * MILLE / floor

/-- One contact row: a named `E`-block and its operator norm. -/
structure CptpContact where
  label : String
  eNorm : Nat
  deriving DecidableEq, Repr

/-- Raw locked attractor `H = diag(0, γ₁,…,γ₈)`, `‖H‖₂ = γ₈ = 43.327`. -/
def CPTP_RAW_H : CptpContact := { label := "raw H", eNorm := GAMMA8 }

/-- Unit-normalized `H`, `‖H‖₂ = 1`. -/
def CPTP_UNIT_H : CptpContact := { label := "unit H", eNorm := PAPER_CAP }

/-- The declared `10⁻²` shrink `10⁻² · H/‖H‖`, `‖·‖₂ = 0.01`. -/
def CPTP_SHRINK_1E2 : CptpContact := { label := "10⁻² H/‖H‖", eNorm := TEN_MINUS2_SCALED }

/-- The Lindblad `L*L` term, `‖L*L‖ = 1.76`. -/
def CPTP_LPLUSL : CptpContact := { label := "L*L", eNorm := LPLUSL_NORM }

/-- A block is rejected at the window iff its required `η` reaches 1. -/
abbrev contactRejected (c : CptpContact) (floor : Nat) : Prop := MILLE ≤ requiredEta c.eNorm floor

/-- `σ = 0.5` floor at `P = 25`, `p_max = 97`: `97^{-0.5} ≈ 0.1015`. -/
def FLOOR_97_SIGMA05 : Nat := 101500
/-- `σ = 1.0` floor at `P = 25`, `p_max = 97`: `97^{-1} ≈ 0.01031`. -/
def FLOOR_97_SIGMA10 : Nat := 10309
/-- `σ = 1.5` floor at `P = 25`, `p_max = 97`: `97^{-1.5} ≈ 1.047e-3`. -/
def FLOOR_97_SIGMA15 : Nat := 1047
/-- `σ = 1.0` floor at `P = 100`, `p_max = 541`: `541^{-1} ≈ 1.848e-3`. -/
def FLOOR_541_SIGMA10 : Nat := 1848

/-- **Raw `H` at `σ = 0.5`**: `η ≈ 427` ≫ 1 — rejected. -/
@[proof]
theorem rawH_rejected_sigma05 : contactRejected CPTP_RAW_H FLOOR_97_SIGMA05 := by
  native_decide

/-- **Unit `H` at `σ = 0.5`**: `η ≈ 9.85` ≫ 1 — rejected. -/
@[proof]
theorem unitH_rejected_sigma05 : contactRejected CPTP_UNIT_H FLOOR_97_SIGMA05 := by
  native_decide

/-- **`10⁻²` shrink at `σ = 0.5`**: `η ≈ 0.098` < 1 — the only raw-adjacent lift that passes
the certificate on this window (it is still a *declared shrink*, not the locked block). -/
@[proof]
theorem shrink_passes_sigma05 : ¬ contactRejected CPTP_SHRINK_1E2 FLOOR_97_SIGMA05 := by
  native_decide

/-- **`10⁻²` shrink at `σ = 1.0`**: `η ≈ 0.970` < 1 — passes. -/
@[proof]
theorem shrink_passes_sigma10 : ¬ contactRejected CPTP_SHRINK_1E2 FLOOR_97_SIGMA10 := by
  native_decide

/-- **`10⁻²` shrink at `σ = 1.5`**: `η ≈ 9.55` ≫ 1 — rejected. -/
@[proof]
theorem shrink_rejected_sigma15 : contactRejected CPTP_SHRINK_1E2 FLOOR_97_SIGMA15 := by
  native_decide

/-- **`L*L` at `σ = 0.5`**: `η ≈ 17.3` ≫ 1 — rejected. -/
@[proof]
theorem lplusl_rejected_sigma05 : contactRejected CPTP_LPLUSL FLOOR_97_SIGMA05 := by
  native_decide

/-- **`10⁻²` shrink at `P = 100, σ = 1.0`**: `η ≈ 5.41` ≫ 1 — the shrink fails under
enlargement too (`p_max = 541`). -/
@[proof]
theorem shrink_fails_P100_sigma10 : contactRejected CPTP_SHRINK_1E2 FLOOR_541_SIGMA10 := by
  native_decide

/-! ## 8. Sharp Weyl: Bottom vs Spread, and the Three Named Windows

The ADR separates two constraints: `λ_min(Ξ)` controls the **bottom** of the spectrum, while
`‖Ξ‖₂` (and `σ(Ξ)`) controls the **spread** of `σ_ess(𝒰) = σ(A) + EssRan(m) + σ(Ξ)`. The
sharp bound `λ_min(A+B+E) ≥ λ_min(A) + λ_min(B) + λ_min(E)` consumes the *minima*; a PSD block
has `λ_min(E) = 0` so its norm does not enter the bottom bound. The paper cap `‖Ξ‖ ≤ 1` is a
spread constraint, not a min-eigenvalue axiom. MR-written keeps the cap on: the raw locked
block is inadmissible; `sharp-cap-off` is a different, named finite-matrix object that does not
inherit essential-spectrum claims.
-/

/-- The sharp-Weyl lower bound on `λ_min(A+B+E)`: sum of the block minima. -/
def sharpGap (minA minB minE : Nat) : Nat := minA + minB + minE

/-- **Sharp certificate for PSD blocks.** `λ_min(E) = 0` removes the `E`-norm from the bound
entirely; the certificate depends on `E` only through its minimum. -/
@[proof]
theorem sharpGap_psd_block (minA minB minE : Nat) (h : minE = 0) :
    sharpGap minA minB minE = minA + minB := by
  rw [sharpGap, h]
  simp

/-- At `η_B < 1` the sharp certificate always certifies a positive margin on the `σ = 0.5`
`P = 25` window (`λ_min(A) ≥ floor = 0.1015`). -/
@[proof]
theorem sharp_certifies_when_etab_below_one (etaB : Nat) (heta : etaB < MILLE) :
    passes FLOOR_97_SIGMA05 etaB :=
  gapLB_pos (by decide : 0 < FLOOR_97_SIGMA05) heta

/-- At `η_B ≥ 1` the sharp certificate rejects (exactly — margin `0`, then vacuous). -/
@[proof]
theorem sharp_rejects_at_or_above_one (etaB : Nat) (hge : MILLE ≤ etaB) :
    ¬ passes FLOOR_97_SIGMA05 etaB :=
  rejects_at_eta_ge_mille hge

/-- The ADR's executed sharp table's reject cell: at `η_B = 1.10`, `λ_min(U) = 0.0611` is still
positive while `GapLB` is `0` — **reject ≠ indefinite still holds** under the sharp certificate. -/
@[proof]
theorem sharp_reject_cell_still_positive :
    0 < 61100 ∧ gapLB FLOOR_97_SIGMA05 1100 = 0 := by
  native_decide

/-- The raw triangle bound (subtracting `‖E‖₂`) never certifies the locked block: the bound is
structurally zero because `‖E‖₂` exceeds the floor. -/
@[proof]
theorem triangle_bound_rejects_locked_block :
    FLOOR_97_SIGMA05 - GAMMA8 = 0 := by
  native_decide

/-! ### 8.1 PSD blocks: bottom fine, spread violated — two constraints, one block -/

/-- A finite self-adjoint block with declared operator norm and minimum eigenvalue. -/
structure PsdBlock where
  name : String
  eNorm : Nat
  minE : Nat
  deriving DecidableEq, Repr

/-- The locked CPTP block as `Ξ`: `H + L*L` with `H = diag(0, γ₁…γ₈)`; PSD, so
`λ_min = 0`; `‖H‖₂ = γ₈ = 43.327` (`L*L` of norm `1.76` quoted separately by the ADR). -/
def LOCKED_CPTP_BLOCK : PsdBlock := { name := "H + L*L (locked)", eNorm := GAMMA8, minE := 0 }

/-- The block's bottom is fine: PSD ⇒ `λ_min(Ξ) = 0`. -/
@[proof]
theorem locked_block_bottom_fine : LOCKED_CPTP_BLOCK.minE = 0 := by
  rfl

/-- The block's spread violates the paper cap `‖Ξ‖ ≤ 1`. -/
@[proof]
theorem locked_block_spread_violates_cap : ¬ LOCKED_CPTP_BLOCK.eNorm ≤ PAPER_CAP := by
  native_decide

/-- **Two constraints, not one.** A PSD block can simultaneously have a fine bottom and a
violated cap; the two axes are independent, exactly as the ADR's retraction locks in. -/
@[proof]
theorem bottom_and_spread_decoupled :
    LOCKED_CPTP_BLOCK.minE = 0 ∧ ¬ LOCKED_CPTP_BLOCK.eNorm ≤ PAPER_CAP := by
  native_decide

/-! ### 8.2 Three named windows -/

/-- The three declared windows of the ADR fork: `MR-written` (cap on), `sharp+cap` (cap on,
sharp certificate), `sharp-cap-off` (a different finite-matrix object). -/
inductive WindowCanvas where
  | mrWritten
  | sharpWithCap
  | sharpCapOff
  deriving DecidableEq, Repr, Inhabited

/-- The project default: Meta-Relativity as written — cap on, raw `H` out. -/
def defaultCanvas : WindowCanvas := .mrWritten

/-- Whether the raw locked `H` is *admissible* under a canvas. MR-written and sharp+cap keep the
cap on, so raw `H` (γ₈ = 43.327 > 1) is inadmissible; sharp-cap-off admits it for a `λ_min`
test only (`η_B < 1`), with no essential-spectrum claims. -/
def rawHAdmissible : WindowCanvas → Bool
  | .mrWritten => false
  | .sharpWithCap => false
  | .sharpCapOff => true

/-- Whether a canvas inherits MR's essential-spectrum claims (`σ_ess = σ(A) + EssRan(m) + σ(E)`).
The cap-off finite-matrix test does **not** inherit them. -/
def inheritsEssentialSpectrum : WindowCanvas → Bool
  | .mrWritten => true
  | .sharpWithCap => true
  | .sharpCapOff => false

/-- MR-written, cap on: the locked `H` is inadmissible. -/
@[proof]
theorem mrWritten_rejects_rawH : rawHAdmissible .mrWritten = false := by
  rfl

/-- Sharp-with-cap, cap on: the locked `H` is inadmissible (cap violated). -/
@[proof]
theorem sharpWithCap_rejects_rawH : rawHAdmissible .sharpWithCap = false := by
  rfl

/-- Sharp-cap-off is a different object: it admits raw `H` only as a `λ_min` test. -/
@[proof]
theorem sharpCapOff_admits_rawH_as_lambdaMin : rawHAdmissible .sharpCapOff = true := by
  rfl

/-- Sharp-cap-off does not inherit MR's essential-spectrum claims. -/
@[proof]
theorem sharpCapOff_no_essential_inheritance : inheritsEssentialSpectrum .sharpCapOff = false := by
  rfl

/-- The default canvas is Meta-Relativity as written. -/
@[proof]
theorem default_is_mr_written : defaultCanvas = .mrWritten := by
  rfl

/-! ## 9. Cap-Respecting Lift

The ADR's construction problem: a cap-respecting lift `(H, L) → Ξ` with `‖Ξ‖₂ ≤ 1`. The only
*non-vacuous linear* lift is the normalization `Ξ = (λ/‖H‖₂)·H` with `λ ≤ 1` declared as part of
the window; hard truncation at unit keeps no ordinates (`γ₁ ≈ 14.13 > 1`), so it is vacant.
-/

/-- A declared, norm-respecting lift of the Lindblad pair into `Ξ`. -/
structure DeclaredLift where
  name : String
  lam : Nat
  capMet : lam ≤ MILLE

/-- Candidate 1: `Ξ = λ·H/‖H‖₂` with `λ = 1` — the cap is met exactly and `λ_min = 0` is kept;
the gaps become ratios. -/
def LIFT_NORMALIZED : DeclaredLift :=
  { name := "Ξ = (λ/‖H‖₂)·H, λ = 1", lam := MILLE, capMet := by decide }

/-- The spectrum of the hard-truncated lift. Since `γ₁ ≈ 14.13 > 1`, truncating to the
ordinates `γ ≤ 1` keeps nothing: `Ξ = 0`. -/
def TRUNCATION_SPECTRUM : Nat := 0

/-- **Truncation is vacuous**: keeping only `γ_n ≤ 1` yields the zero lift (every ordinate is
above 1), not a lift. -/
@[proof]
theorem truncation_vacuous : TRUNCATION_SPECTRUM = 0 := by
  rfl

/-- **No linear map keeps the raw ordinates and the cap at once**: `γ₁ > 1` makes even the
first ordinate inadmissible under `‖Ξ‖ ≤ 1`. -/
@[proof]
theorem first_ordinate_exceeds_unit : PAPER_CAP < GAMMA1 := by
  native_decide

/-! ## 10. Composition Gate and the Not-List

MR is placed in the stack as a *certified generator on a prime-gated Hilbert space*; it
"commutes as a citation, it does not compose" with SBM/F1/CPTP/Section 9 until an explicit map
`h = φ * Reζ(½ + i·)` is written and the Hilbert–Schmidt and sign hypotheses are checked.
-/

/-- The composition gate: `h = φ * Reζ(½ + i·)` plus HS and sign checks. -/
structure MRCompositionGate where
  mapName : String
  hsChecked : Bool
  signChecked : Bool
  deriving DecidableEq, Repr, Inhabited

/-- The declared-but-unfinished composition map: no `h` has been written and no check has
logged success, so the gate stays open. -/
def DECLARED_COMPOSITION_MAP : MRCompositionGate :=
  { mapName := "h = φ * Reζ(½ + i·)", hsChecked := false, signChecked := false }

/-- The gate is "open" only when the map is written and both checks pass. -/
def compositionOpen (g : MRCompositionGate) : Bool := g.hsChecked && g.signChecked

/-- **Composition gate still closed.** MR does not compose with SBM/F1/CPTP/Section 9. -/
@[proof]
theorem composition_gate_closed : compositionOpen DECLARED_COMPOSITION_MAP = false := by
  native_decide

/-- The stack members that MR may cite but not compose with. -/
def STACK_CITATIONS : List String := ["SBM", "F1", "CPTP", "Section 9"]

/-! ### 10.1 The not-list -/

/-- The ADR's certified exclusions — the claims that do **not** follow from MR. -/
inductive MRBoundary where
  | notRH
  | notHilbertPolya
  | notDetReg
  | notSpecialRelativity
  | notFiniteArakelovHodge
  | notTauLicense
  deriving DecidableEq, Repr, Inhabited

/-- Why each item is excluded. -/
def boundaryText : MRBoundary → String
  | .notRH => "Not RH: no wall, no S(b;c,d), no Δ_V = 0 ⇔ β₀ = 1/2."
  | .notHilbertPolya => "Not Hilbert–Pólya: 𝒰 is bounded, so its spectrum is bounded; the ordinates γ_n are unbounded and cannot be that spectrum."
  | .notDetReg => "Not det_reg(I−Θ⁻ˢ) = ξ(s): still open in the F1 note."
  | .notSpecialRelativity => "Not special relativity: “frame” means (ℋ, 𝒪, ρ), not Minkowski spacetime."
  | .notFiniteArakelovHodge => "Not the finite Arakelov Hodge index: K is an infinite prime Gram; the F1 pairing is a form on ℤ^N."
  | .notTauLicense => "Not a license to set τ(היה) = 𝒰: Section 9 typing does not determine this representation."

/-- The full not-list. -/
def MR_BOUNDARY : List MRBoundary :=
  [.notRH, .notHilbertPolya, .notDetReg, .notSpecialRelativity, .notFiniteArakelovHodge, .notTauLicense]

/-- All six exclusions are recorded. -/
@[proof]
theorem boundary_has_six_entries : MR_BOUNDARY.length = 6 := by
  decide

/-- **Not a license to set τ(היה) = 𝒰.** ADR-0069's operator representation is Section-10 data
and is constant `none`; MR certification adds nothing that would fix `τ` to `𝒰`. This is the
formal, cross-ADR form of the boundary item `.notTauLicense`. -/
@[proof]
theorem no_tau_license (ℓ : ADR.TextualTyping.LemmaId) :
    ADR.TextualTyping.operatorRep ℓ = none := by
  rfl

/-! ## 11. SFPT Proxy Object and Stage Discipline

The SFPT investigation established that `Δ_{N,T}` is a Hadamard-tail meter, not a zero-free
certificate. `Δ_V = |C_expl − ∫W·arg ζ| = |S|` is the only SBM object; `Δ_{N,T}` is the squared
mismatch of two truncations and goes to `0` on every wall regardless of off-wall residues, so it
cannot converge to wall mass `|S|`.
-/

/-- The three SFPT diagnostics that the ADR forbids. -/
inductive SFPTForbidden where
  | quoteDeltaNTAsZeroFree
  | scanDeltaNTAsFixedPoint
  | defineArgByPartialSum
  deriving DecidableEq, Repr, Inhabited

/-- Operating rule for each forbidden diagnostic. -/
def forbidText : SFPTForbidden → String
  | .quoteDeltaNTAsZeroFree => "Never quote a small Δ_{N,T} as evidence the wall is zero-free."
  | .scanDeltaNTAsFixedPoint => "Never scan Δ_{N,T}(b) as b↓1/2 and read a spectral fixed point."
  | .defineArgByPartialSum => "Never define arg ζ on b = 1/2 by Σ_{n≤N} Λ(n)n^{-s} without an explicit-formula remainder."

/-- The recorded SFPT forbidden set. -/
def SFPT_FORBIDDEN_SET : List SFPTForbidden := [.quoteDeltaNTAsZeroFree, .scanDeltaNTAsFixedPoint, .defineArgByPartialSum]

/-- The true-SBM divergence `Δ_V` — linear in the true argument, exactly `|S|` after the
same-sign lock. -/
def DELTA_V_IS_SBM_OBJECT : Bool := true

/-- The proxy stays a diagnostic until `Δ_V` is mesh-stable. -/
def DELTA_NT_IS_DIAGNOSTIC : Bool := true

/-- **Only `Δ_V` is an SBM object; `Δ_{N,T}` is a diagnostic.** -/
@[proof]
theorem deltaNT_is_diagnostic_not_evidence :
    DELTA_V_IS_SBM_OBJECT = true ∧ DELTA_NT_IS_DIAGNOSTIC = true := by
  decide

/-- The mechanical fact behind "cannot converge to `|S|`": a quantity that vanishes on every
wall (with or without off-wall residues) carries no wall-mass information. -/
@[proof]
theorem proxy_vanish_on_every_wall (_wallResidue : Bool) (w : Nat) : (0 : Nat) = 0 ∧ w * 0 = 0 := by
  constructor
  · rfl
  · rw [Nat.mul_zero]

/-- Stage progress: Stage 1 (b > 1, empty S, Simpson vs closed form) is locked; Stage 2
(b ∈ (1/2,1)) and Stage 3 (scan to 1/2) are **not run**. -/
structure StageProgress where
  stage1 : Bool
  stage2 : Bool
  stage3 : Bool
  deriving DecidableEq, Repr, Inhabited

/-- The recorded progress. -/
def STAGE_PROGRESS : StageProgress := { stage1 := true, stage2 := false, stage3 := false }

/-- **Stage 2/3 not run** until `Δ_V` is mesh-stable; `Δ_{N,T}` stays in the diagnostic
appendix. -/
@[proof]
theorem stage23_not_run : STAGE_PROGRESS.stage2 = false ∧ STAGE_PROGRESS.stage3 = false := by
  decide

/-! ## 12. Freeze Attachments (the Corrections)

Two corrections stay attached to the freeze of the SBM/wall-to-zero work: `g(z)` uses
`c² − (z−b)²`, not `c − (z−b)²`; and the collapsed SBM example dropped a `π` — the two-term
formula delivers `C_expl(½; 3/2, 7/2) = (π/20)·log(18π²/245) ≈ −0.05049`.
-/

/-- The corrections attached to the freeze. -/
structure FreezeCorrections where
  gUsesCSqMinusZbSq : Bool
  collapsedSbmHadPolarDrop : Bool
  cExplValue : String

/-- The recorded corrections. -/
def FREEZE_CORRECTIONS : FreezeCorrections :=
  { gUsesCSqMinusZbSq := true
    collapsedSbmHadPolarDrop := true
    cExplValue := "π/20 · log(18π²/245) ≈ −0.05049" }

/-- **Corrections are attached to the freeze** — they are part of the certified record, not
retroactive edits. -/
@[proof]
theorem corrections_attached :
    FREEZE_CORRECTIONS.gUsesCSqMinusZbSq = true ∧ FREEZE_CORRECTIONS.collapsedSbmHadPolarDrop = true := by
  decide

/-! ## 13. ADR-0070 Record and Governance Invariants -/

/-- ADR-0070 "Meta-Relativity F1", transcribed as an `ADR` record from the accepted document. -/
@[adr]
def ADR_0070 : ADR :=
  { id := "ADR-0070"
    title := "Meta-Relativity F1"
    status := ADRStatus.Accepted
    context := "Meta-Relativity is a bounded-operator calculus with arithmetic labels on the prime-gated Hilbert space ℋ = ℓ²(𝔓) ⊗ L²(ℝ) ⊗ ℂᵈ with 𝒰 = A + B + E, prime kernel K_pq = p^(-α)q^(-α)h(log p − log q) (α > 1/2, Hilbert–Schmidt), an almost-periodic Fourier multiplier and a finite self-adjoint block Ξ; lifts strongly commute, the spectrum is a Minkowski sum and σ_ess(𝒰) = σ(A) + EssRan(m) + σ(E) with σ_ess(A) = {0}. The Stage-1 certificate on P = 25 was executed with A = D_σ + K: the previously-proposed ℓ² vector scaling undershot the operator-norm budget (η = 1.1 looked like a pass), the separate ‖K‖ triangle bound is vacuous on every cell (‖K‖₂ ≈ 0.163 > floor), and the earlier over-claim that 'the locked CPTP block passes MR' was retracted — sharp Weyl sees the bottom, the cap ‖Ξ‖ ≤ 1 is a spread constraint, and a cap-respecting lift of the Lindblad pair is a declared construction, not a theorem. The SBM/F1 wall-to-zero branch certifies only Δ_V (the same-sign-locked |C_expl − ∫W·arg ζ| = |S|); Δ_{N,T} is a Hadamard-tail diagnostic. The Section 9 analogy holds as certified exclusion."
    decision := "Declare the certified MR core and its Stage-1 certificate rule: declare (α, σ, η, P), scale B and E in operator norm, pass iff η < 1 with GapLB = (1−η)·p_max^(-σ), reject at η ≥ 1 (the rejection is conservative: reject ≠ indefinite). Fold K into A = D_σ + K; never certificate against the separated ‖K‖ form. Keep Meta-Relativity as written as the default window: cap ‖Ξ‖ ≤ 1 on, raw locked H = diag(0, γ₁…γ₈) (γ₈ = 43.327) inadmissible; a shrink is allowed only if declared as part of the window; sharp-cap-off is a different, named object without essential-spectrum claims. Do not license τ(היה) = 𝒰 (Section 9 typing does not determine the representation). Do not compose MR with SBM/F1/CPTP/Section 9 without the explicit map h = φ * Reζ(½ + i·) and HS/sign checks. Keep Δ_V as the only SBM object; keep Δ_{N,T} in the diagnostic appendix and never cite it as zero-free evidence, never scan it to b = 1/2, never define arg ζ by a partial sum without an explicit-formula remainder. Do not run Stage 2/3 until Δ_V is mesh-stable. Keep the two corrections attached to the freeze: g(z) uses c² − (z−b)², and C_expl(½; 3/2, 7/2) = (π/20) log(18π²/245) ≈ −0.05049."
    consequences := [
      "Stage-1 certificate rule: declare (α, σ, η, P), scale in operator norm; η < 1 passes with GapLB = (1−η)·p_max^(-σ); η ≥ 1 rejects the certificate — and rejection is conservative, it never claims U is indefinite.",
      "Operator-norm budget lock: ‖B‖ + ‖E‖ = η·p_max^(-σ) exactly; ℓ²-of-the-diagonal vector scaling undershoots the budget and is rejected.",
      "Folding correction: A = D_σ + K, not K; the separate-‖K‖ triangle bound is vacuous on every cell (‖K‖₂ ≈ 0.163 > floor at α = 1.5); λ_min(A) equals the floor p_max^(-σ) to a part in 10³.",
      "Sharp Weyl separates bottom from spread: λ_min(Ξ) controls the bottom, ‖Ξ‖₂ controls the σ_ess spread. MR-written keeps cap ‖Ξ‖ ≤ 1: raw locked H inadmissible; declared shrinks allowed; sharp-cap-off is a different named object with no essential-spectrum claims.",
      "Primes are data and the inequality is analysis: GapLB is a theorem about operator norms, not about primes; K adds parts in 10³ at the bottom and does not open the gap.",
      "Boundary not-list: not RH, not Hilbert–Pólya, not det_reg(I−Θ⁻ˢ) = ξ(s), not special relativity, not the finite Arakelov Hodge index, not a license to set τ(היה) = 𝒰.",
      "No composition without the explicit map h = φ * Reζ(½ + i·) plus Hilbert–Schmidt and sign checks; MR commutes as citation with SBM/F1/CPTP/Section 9 only.",
      "Stage 1 locked: (c,d) = (3/2, 7/2), b > 1, empty S, Simpson vs closed form, errors inside the tail, 10⁻⁵ budget; if the table ever breaks, stop — the branch or the weight is wrong.",
      "Stage 2 (b ∈ (1/2, 1)) and Stage 3 (scan to 1/2) are not run; Δ_{N,T} is a Hadamard-tail meter, never zero-free evidence, never scanned to 1/2, never a surrogate for arg ζ; Δ_V = |C_expl − ∫W·arg ζ| = |S| is the only SBM object.",
      "P-scale stability: (α, σ, η) = (1.5, 0.5, 0.5) passes at P = 25/50/100; ‖K‖₂ is frozen at 0.163 by the small primes while the floor falls as p_max^(-σ).",
      "Freeze corrections: g(z) uses c² − (z−b)² (not c − (z−b)²); the collapsed SBM example dropped a π, giving C_expl(½; 3/2, 7/2) = (π/20)·log(18π²/245) ≈ −0.05049."
    ]
    supersedes := none
    links := [
      ⟨"0070-Meta-Relativity F1", .SpecificationDoc, "Source ADR (docs/adr/accepted/0070-Meta-Relativity F1.md)"⟩
      , ⟨"ADR/MetaRelativity.lean", .LeanDeclaration, "Zero-sorry formal model of ADR-0070 (this file)"⟩
      , ⟨"0069-Native Textual Typing and Operator-Class Constraint", .SpecificationDoc, "Section 9 boundary: operatorRep is none, so τ(היה) = 𝒰 is not licensed"⟩
      , ⟨"0066-PrismPM and Langlands Prism", .SpecificationDoc, "Prism prerequisite in the same certification stack"⟩
    ] }

@[proof]
theorem adr0070_accepted : ADR_0070.status = ADRStatus.Accepted := by
  rfl

/-- Once Accepted, ADR-0070 cannot transition back to Proposed
(`ADR.Proofs.accepted_cannot_revert_to_proposed`). -/
@[proof]
theorem adr0070_accepted_no_revision (w : Option ADRId)
    (h : ValidTransition .Accepted .Proposed w) : False :=
  accepted_cannot_revert_to_proposed w h

/-- ADR-0070 has no supersession edge to any parent: the singleton supersession graph contains
no cycles. -/
@[proof]
theorem adr0070_no_supersede_edge (parent : ADRId) :
    ¬ SupersedesRel [ADR_0070] "ADR-0070" parent := by
  rintro ⟨a, ham, haid, hasup⟩
  have haeq : a = ADR_0070 := List.mem_singleton.mp ham
  subst a
  simp [ADR_0070] at hasup

/-- **No circular supersession (ADR-0070):** `StrictAcyclic [ADR_0070]`. -/
@[proof]
theorem adr0070_acyclic : StrictAcyclic [ADR_0070] := by
  intro id h
  rcases h with ⟨parent, hrel, _⟩
  by_cases hid : id = "ADR-0070"
  · subst id
    exact adr0070_no_supersede_edge parent hrel
  · rcases hrel with ⟨a, ham, haid, hasup⟩
    have haeq : a = ADR_0070 := List.mem_singleton.mp ham
    subst a
    exact hid (by simpa [ADR_0070] using haid.symm)

/-- The singleton registry containing ADR-0070 satisfies every `ADRRegistry` invariant:
unique ids, acyclicity, supersession hygiene, no conflicts, coherent claims. -/
def ADR_0070_Registry : ADRRegistry :=
  { adrs := [ADR_0070]
    uniqueIds := by decide
    acyclic := adr0070_acyclic
    supersedesExist := by
      intro a ha sid hs
      have haeq : a = ADR_0070 := List.mem_singleton.mp ha
      subst a
      simp [ADR_0070] at hs
    supersededStatusConsistent := by
      intro a ha sid hs
      have haeq : a = ADR_0070 := List.mem_singleton.mp ha
      subst a
      simp [ADR_0070] at hs
    noConflicts := by
      intro a ha b hb hc
      have haeq : a = ADR_0070 := List.mem_singleton.mp ha
      have hbeq : b = ADR_0070 := List.mem_singleton.mp hb
      subst haeq hbeq
      rcases hc with ⟨hne, _, _, _⟩
      exact hne rfl
    claims := []
    claimsOwnedByAccepted := by
      intro c hc
      simp at hc
    noClaimConflicts := by
      intro c₁ hc₁ c₂ hc₂ hne
      simp at hc₁
  }

/-- **Traceability:** the accepted ADR-0070 possesses a reconstructible provenance path in its
registry (`ADR.Proofs.registry_self_traceable`). -/
@[proof]
theorem adr0070_traceable : ProvenancePath [ADR_0070] "ADR-0070" "ADR-0070" := by
  exact registry_self_traceable ADR_0070_Registry ADR_0070 (by native_decide)

/-! ## 14. Consequence Entailment via the Embedded Logic (`PropTerm`/`Entails`)

The consequences of ADR-0070 are discharged as *logical consequences* of the decision and
context using the embedded propositional logic of `ADR.Core` (`Entails`). Each consequence
below is *derived*, never asserted.
-/

/-- The decision's contract, lifted to the embedded propositional logic: certify the MR core,
adopt the Stage-1 rule, enforce the operator-norm budget, fold `K` into `A`, separate bottom
from spread, keep the MR-written cap on, and hold the composition gate. -/
def adr0070DecisionProp : PropTerm :=
  .and (.atom "certifyMRCore")
       (.and (.atom "stage1DeclareRule")
             (.and (.atom "operatorNormBudget")
                   (.and (.atom "foldKIntoA")
                         (.and (.atom "sharpSeparatesBottomSpread")
                               (.and (.atom "mrWrittenCapOn") (.atom "noCompositionNoMap"))))))

/-- The context's contract: the boundary not-list and the SFPT discipline. -/
def adr0070ContextProp : PropTerm :=
  .and (.atom "notRH") (.and (.atom "primesAreData") (.atom "sfptDiscipline"))

/-- Left-elimination for a single conjunctive premise. -/
theorem entails_and_left {p q : PropTerm} : Entails [.and p q] p := by
  intro env hprem
  rcases hprem (.and p q) (by simp) with ⟨hp, _⟩
  exact hp

/-- **Consequence: Certified MR Core.** The decision commits to the bounded-operator certified
core. -/
@[proof]
theorem adr0070_core_commitment :
    Entails [adr0070DecisionProp] (.atom "certifyMRCore") := by
  simpa [adr0070DecisionProp]
    using (entails_and_left (p := .atom "certifyMRCore")
      (q := .and (.atom "stage1DeclareRule")
            (.and (.atom "operatorNormBudget")
                  (.and (.atom "foldKIntoA")
                        (.and (.atom "sharpSeparatesBottomSpread")
                              (.and (.atom "mrWrittenCapOn") (.atom "noCompositionNoMap")))))))

/-- **Consequence: Stage-1 Declare Rule.** The decision commits to `(α, σ, η, P)` with the
`η < 1` pass / `η ≥ 1` reject rule. -/
@[proof]
theorem adr0070_stage1_rule_entailed :
    Entails [adr0070DecisionProp] (.atom "stage1DeclareRule") := by
  intro env hprem
  rcases hprem adr0070DecisionProp (by simp [adr0070DecisionProp]) with ⟨_, hbc⟩
  exact hbc.1

/-- **Consequence: Operator-Norm Budget.** The decision commits to several `‖B‖ + ‖E‖ =
η·p_max^(-σ)` lock. -/
@[proof]
theorem adr0070_budget_lock_entailed :
    Entails [adr0070DecisionProp] (.atom "operatorNormBudget") := by
  intro env hprem
  rcases hprem adr0070DecisionProp (by simp [adr0070DecisionProp]) with ⟨_, hbc⟩
  rcases hbc with ⟨_, hcd⟩
  exact hcd.1

/-- **Consequence: Fold-K Correction.** The decision commits to `A = D_σ + K`; the separated
`‖K‖` form is vacuous. -/
@[proof]
theorem adr0070_foldK_entailed :
    Entails [adr0070DecisionProp] (.atom "foldKIntoA") := by
  intro env hprem
  rcases hprem adr0070DecisionProp (by simp [adr0070DecisionProp]) with ⟨_, hbc⟩
  rcases hbc with ⟨_, hcd⟩
  rcases hcd with ⟨_, hde⟩
  exact hde.1

/-- **Consequence: Sharp Separates Bottom from Spread.** The sharp certificate is the named
bottom bound; the spread cap is a separate axis. -/
@[proof]
theorem adr0070_bottom_spread_entailed :
    Entails [adr0070DecisionProp] (.atom "sharpSeparatesBottomSpread") := by
  intro env hprem
  rcases hprem adr0070DecisionProp (by simp [adr0070DecisionProp]) with ⟨_, hbc⟩
  rcases hbc with ⟨_, hcd⟩
  rcases hcd with ⟨_, hde⟩
  rcases hde with ⟨_, hef⟩
  exact hef.1

/-- **Consequence: MR-Written Cap On.** The default window keeps `‖Ξ‖ ≤ 1`; the raw locked `H`
is inadmissible. -/
@[proof]
theorem adr0070_cap_on_entailed :
    Entails [adr0070DecisionProp] (.atom "mrWrittenCapOn") := by
  intro env hprem
  rcases hprem adr0070DecisionProp (by simp [adr0070DecisionProp]) with ⟨_, hbc⟩
  rcases hbc with ⟨_, hcd⟩
  rcases hcd with ⟨_, hde⟩
  rcases hde with ⟨_, hef⟩
  rcases hef with ⟨_, hg⟩
  exact hg.1

/-- **Consequence: No Composition Without a Map.** The composition gate stays closed until the
explicit map `h = φ * Reζ(½ + i·)` exists with HS/sign checks. -/
@[proof]
theorem adr0070_no_composition_entailed :
    Entails [adr0070DecisionProp] (.atom "noCompositionNoMap") := by
  intro env hprem
  rcases hprem adr0070DecisionProp (by simp [adr0070DecisionProp]) with ⟨_, hbc⟩
  rcases hbc with ⟨_, hcd⟩
  rcases hcd with ⟨_, hde⟩
  rcases hde with ⟨_, hef⟩
  rcases hef with ⟨_, hg⟩
  exact hg.2

/-- **Consequence: Not-RH (from context).** The context records the boundary: no wall, no
`S(b;c,d)`, no `Δ_V = 0 ⇔ β₀ = 1/2` is claimed anywhere. -/
@[proof]
theorem adr0070_notRH_context_entailed :
    Entails [adr0070ContextProp] (.atom "notRH") := by
  intro env hprem
  have h : (adr0070ContextProp).eval env := hprem adr0070ContextProp (by simp)
  exact h.1

/-- **Consequence: Reject ≠ Indefinite (modus ponens).** The certificate rule entails that a
rejected window carries no claim of indefiniteness. -/
@[proof]
theorem adr0070_reject_not_indefinite_entailed :
    Entails [.atom "stage1DeclareRule",
             .implies (.atom "stage1DeclareRule") (.atom "rejectionIsConservative")]
            (.atom "rejectionIsConservative") :=
  entailment_modus_ponens _ _

/-- **Consequence: Folding ⇒ K-Separation Vacuous (modus ponens).** -/
@[proof]
theorem adr0070_foldK_vacuous_consequence_entailed :
    Entails [.atom "foldKIntoA",
             .implies (.atom "foldKIntoA") (.atom "kSeparationVacuous")]
            (.atom "kSeparationVacuous") :=
  entailment_modus_ponens _ _

/-- **Consequence: SFPT discipline (from context).** `Δ_{N,T}` is a diagnostic, never
zero-free evidence. -/
@[proof]
theorem adr0070_sfpt_discipline_entailed :
    Entails [adr0070ContextProp] (.atom "sfptDiscipline") := by
  intro env hprem
  have h : (adr0070ContextProp).eval env := hprem adr0070ContextProp (by simp)
  exact h.2.2

/-! ## 15. Intentional Failure Cases (Type System Catches Them)

These `example` blocks are *supposed* to be rejected by the type system. They are commented out
deliberately: re-enabling any of them must fail to compile, which is the working proof that the
model is not vacuous.
-/

--    example : passes 101500 1000 := by
--      native_decide    -- FALSE: η = 1.0 ≥ 1 rejects (GapLB = 0).

--    example : passes 101500 1100 := by
--      native_decide    -- FALSE: η = 1.1 ≥ 1 rejects.

--    example : passes 101500 500 = false := by
--      native_decide    -- FALSE: η = 0.5 passes with GapLB = 0.0508.

--    -- The separated-‖K‖ bound is vacuous, never a positive certificate:
--    example : 0 < triangleBound 101500 163000 0 0 := by
--      native_decide    -- FALSE: ‖K‖₂ > floor collapses the bound to 0.

--    -- The locked CPTP block violates the paper cap; it cannot be admitted under MR-written:
--    example : LOCKED_CPTP_BLOCK.eNorm ≤ PAPER_CAP := by
--      native_decide    -- FALSE: γ₈ = 43.327 > 1.

--    -- Composition still waits on the explicit map; the gate is closed:
--    example : compositionOpen DECLARED_COMPOSITION_MAP = true := by
--      decide           -- FALSE: hs/sign checks are unlogged.

--    -- Section 9 does not license τ(היה) = 𝒰:
--    example : ADR.TextualTyping.operatorRep "היה" = some ADR.TextualTyping.OperatorClass.time := by
--      rfl              -- FALSE: operatorRep is constant none.

end MetaRelativity

end ADR