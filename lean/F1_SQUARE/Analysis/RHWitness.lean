/-
F1 square — **the witness of RH, constructed**: the manifest sum-of-nonnegatives form of the Li
coefficients on the critical-line locus.

The Riemann Hypothesis, in Li/Keiper form, is `λₙ ≥ 0 for all n`, where the per-zero contribution is
`1 − (1−1/ρ)ⁿ` and `λₙ = Σ_ρ Re[1 − (1−1/ρ)ⁿ] = Σ_ρ (1 − Re(wₙ,ρ))` with `wρ = 1 − 1/ρ` the zero's
Cayley factor. THIS FILE constructs the witness object and proves it works, **conditional on the
critical-line hypothesis** — i.e. it exhibits the genuine sum-of-squares structure that makes RH's
forward direction (`RH ⟹ λₙ ≥ 0`) manifest.

THE CONSTRUCTION (no `sqrt`, choice-free, axiom-clean):
- the Cayley factor of an on-line zero has UNIT MODULUS: `Re ρ = ½ ⟹ |ρ−1|² = |ρ|²` (`liRatio_on_line`,
  `ZeroGeometry`), so `|wρ|² = |ρ−1|²/|ρ|² = 1`;
- unit modulus survives EVERY power, by the Atlas composition norm: `|wⁿ|² = (|w|²)ⁿ = 1ⁿ = 1`
  (`cnormSq_npow` over the Brahmagupta–Fibonacci identity `cnormSq_mul = |zw|²=|z|²|w|²`, the §6.3/§9
  two-square law);
- a unit-modulus complex has real part `≤ 1`: `Re(u)² ≤ |u|² = 1 ⟹ Re(u) ≤ 1` (`Rle_of_Rmul_self_le`,
  the squared-modulus comparison — no `sqrt`);
- hence each Li term `1 − Re(wⁿ)` is `≥ 0` MANIFESTLY (`witnessTerm_nonneg`), and any finite sum of
  them — the truncated `λₙ` on the on-line locus — is `≥ 0` (`witnessSum_nonneg`, `rh_witness`).

WHAT THIS IS AND IS NOT. This is the genuine witness of RH's EASY direction: given the zeros on the
line, `λₙ ≥ 0` is a manifest sum of non-negatives, exhibited here as a constructive object. It is NOT
a proof of RH: its hypothesis — every Cayley factor of unit modulus (`AllZerosOnLine`,
`onLine_is_unit_modulus`) — IS RH, and is never discharged. The HARD direction (`λₙ ≥ 0 ⟹` zeros on
the line, equivalently producing the positivity WITHOUT the hypothesis) is the open content; the crux
fields stay `none`. Producing the witness UNCONDITIONALLY is exactly solving RH.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.LiGrowth

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Powers of a unit-modulus factor stay unit modulus (the Atlas composition norm at work).
-- ===========================================================================

/-- `Rnpow` respects `Req` in the base. -/
theorem Rnpow_congr {x y : Real} (h : Req x y) : ∀ n, Req (Rnpow x n) (Rnpow y n)
  | 0 => Req_refl one
  | (k + 1) => Rmul_congr h (Rnpow_congr h k)

/-- `1ⁿ = 1`. -/
theorem Rnpow_one : ∀ n, Req (Rnpow one n) one
  | 0 => Req_refl one
  | (k + 1) => Req_trans (Rmul_congr (Req_refl one) (Rnpow_one k)) (Rmul_one one)

/-- **Unit modulus is preserved by every power**: `|w|² = 1 ⟹ |wⁿ|² = 1`. The Atlas composition norm
    (`cnormSq_npow`, iterated `|zw|²=|z|²|w|²`) carries the unit modulus of the Cayley factor through
    to `wⁿ` for every `n` — the structural fact behind "an on-line zero contributes a bounded,
    oscillatory term." -/
theorem cnormSq_Cnpow_unit {w : Complex} (h : Req (cnormSq w) one) (n : Nat) :
    Req (cnormSq (Cnpow w n)) one :=
  Req_trans (cnormSq_npow w n) (Req_trans (Rnpow_congr h n) (Rnpow_one n))

/-- **The half-plane strengthening**: `|w|² ≤ 1 ⟹ |wⁿ|² ≤ 1` for every `n`. The non-negativity of the
    witness needs only the CLOSED condition `|w|² ≤ 1` — i.e. `Re ρ ≥ ½`, the zero on OR right of the
    critical line (`liRatio_right_of_line`/`liRatio_on_line`) — not unit modulus. The composition norm
    is monotone under powers (`cnormSq_npow` + `Rnpow_le_Rnpow`), so the whole closed half-plane is
    covered. (`= 1`, the line, is the boundary case `cnormSq_Cnpow_unit`.) -/
theorem cnormSq_Cnpow_le_one {w : Complex} (h : Rle (cnormSq w) one) (n : Nat) :
    Rle (cnormSq (Cnpow w n)) one :=
  Rle_trans (Rle_of_Req (cnormSq_npow w n))
    (Rle_trans (Rnpow_le_Rnpow (cnormSq_nonneg w) h n) (Rle_of_Req (Rnpow_one n)))

-- ===========================================================================
-- The per-zero witness term `1 − Re(wⁿ)` is manifestly non-negative on the line.
-- ===========================================================================

/-- **THE PER-ZERO WITNESS**: if the Cayley factor `w` lies in the closed unit disk `|w|² ≤ 1` (its
    zero on OR right of the critical line, `Re ρ ≥ ½`), then the `n`-th Li term `1 − Re(wⁿ)` is `≥ 0`
    — manifestly, with NO `sqrt`. The argument: `Re(wⁿ)² ≤ Re(wⁿ)² + Im(wⁿ)² = |wⁿ|² ≤ 1`, and
    `Re(wⁿ)² ≤ 1` with the squared comparison gives `Re(wⁿ) ≤ 1`. This is the manifest
    `1 − cos(nθ) ≥ 0` of Li's criterion, realized constructively, on the whole closed half-plane. -/
theorem witnessTerm_nonneg {w : Complex} (h : Rle (cnormSq w) one) (n : Nat) :
    Rnonneg (Rsub one (Cnpow w n).re) := by
  have h1 : Rle (Rmul (Cnpow w n).re (Cnpow w n).re) (cnormSq (Cnpow w n)) := by
    show Rle (Rmul (Cnpow w n).re (Cnpow w n).re)
      (Radd (Rmul (Cnpow w n).re (Cnpow w n).re) (Rmul (Cnpow w n).im (Cnpow w n).im))
    exact Rle_self_Radd_right (Rnonneg_Rmul_self (Cnpow w n).im)
  have h2 : Rle (Rmul (Cnpow w n).re (Cnpow w n).re) (Rmul one one) :=
    Rle_trans h1 (Rle_trans (cnormSq_Cnpow_le_one h n) (Rle_of_Req (Req_symm (Rmul_one one))))
  exact Rnonneg_Rsub_of_Rle (Rle_of_Rmul_self_le Rnonneg_one h2)

-- ===========================================================================
-- The witness assembled: `λₙ` on the on-line locus is a sum of non-negatives.
-- ===========================================================================

/-- The Li coefficient's **witness form** at index `n`, over a finite family of Cayley factors `ws`:
    `Σ_w (1 − Re(wⁿ))`. With `ws` the zeros' Cayley factors `{1−1/ρ}`, this is the manifest
    sum-of-nonnegatives representation of `λₙ` on the critical-line locus. -/
def witnessSum (ws : List Complex) (n : Nat) : Real :=
  match ws with
  | [] => zero
  | w :: rest => Radd (Rsub one (Cnpow w n).re) (witnessSum rest n)

/-- **THE WITNESS IS NON-NEGATIVE** (the assembly): if every Cayley factor in `ws` lies in the closed
    unit disk (`|w|² ≤ 1`, the zero on or right of the line), the witness sum is `≥ 0` for every `n` —
    a finite sum of the manifest non-negatives `witnessTerm_nonneg`. -/
theorem witnessSum_nonneg : ∀ (ws : List Complex) (n : Nat),
    (∀ w, w ∈ ws → Rle (cnormSq w) one) → Rnonneg (witnessSum ws n)
  | [], _, _ => Rnonneg_zero
  | (w :: rest), n, h =>
      Rnonneg_Radd (witnessTerm_nonneg (h w (List.Mem.head rest)) n)
        (witnessSum_nonneg rest n (fun w' hw' => h w' (List.Mem.tail w hw')))

-- ===========================================================================
-- The honest bridge: the witness's hypothesis IS RH.
-- ===========================================================================

/-- **THE HYPOTHESIS IS RH (squared-modulus form)**: every zero on the critical line has its Cayley
    factor of unit modulus — `|ρ−1|² = |ρ|²`, i.e. `|1−1/ρ|² = 1` — for every zero. This is exactly
    the `AllZerosOnLine` premise of the witness, transported to the factor (`allOnLine_ratios_one`).
    So the witness's antecedent is precisely RH. -/
theorem onLine_is_unit_modulus (isZero : Complex → Prop) (h : AllZerosOnLine isZero) :
    ∀ z, isZero z → Req (csubOneNormSq z) (cnormSq z) :=
  allOnLine_ratios_one isZero h

/-- **THE RH WITNESS (conditional), as one statement.** Given the zeros' Cayley factors all in the
    closed unit disk (`|w|² ≤ 1`, every zero on or right of the line), the Li coefficient's manifest
    sum-of-nonnegatives form `Σ (1 − Re(wⁿ))` is `≥ 0` for every `n`. This is the witness, exhibited as
    a constructive object built from the Atlas composition norm. The hypothesis is never discharged —
    producing the witness WITHOUT it is the hard direction (RH itself) — so the crux fields stay
    `none`. -/
theorem rh_witness (ws : List Complex) (n : Nat)
    (h : ∀ w, w ∈ ws → Rle (cnormSq w) one) : Rnonneg (witnessSum ws n) :=
  witnessSum_nonneg ws n h

/-- **THE ON-LINE FACE (exact RH).** The boundary specialization: every Cayley factor of UNIT modulus
    (`|w|² = 1`, every zero exactly ON the critical line — RH proper) gives the non-negative witness.
    This is `RH ⟹ λₙ ≥ 0` in its pure form; `rh_witness` generalizes it to the closed half-plane. By
    the functional equation a zero `ρ` is mirrored by `1−ρ`, so the half-plane hypothesis can hold for
    ALL zeros only when every zero is on the line — which is why the closed-disk witness does not
    secretly weaken the open content: discharging it is still exactly RH. The crux fields stay
    `none`. -/
theorem rh_witness_onLine (ws : List Complex) (n : Nat)
    (h : ∀ w, w ∈ ws → Req (cnormSq w) one) : Rnonneg (witnessSum ws n) :=
  witnessSum_nonneg ws n (fun w hw => Rle_of_Req (h w hw))

end UOR.Bridge.F1Square.Analysis
