/-
F1 square — **the Bombieri–Lagarias pipeline**: the constructive RH witness wired, end to end, to the
genuine Li sequence — the complete forward direction `RH ⟹ λₙ ≥ 0` as one kernel-checked artifact,
with the single classical input carried honestly as an explicit hypothesis (no axiom, no smuggling).

The witness (`RHWitness.lean`) proves the per-zero contribution `1 − Re((1−1/ρ)ⁿ)` is a manifest
non-negative when the zero's Cayley factor lies in the closed unit disk, and any finite sum of them is
`≥ 0` (`witnessSum_nonneg`). The reflection/symmetry bricks (`Reflection.lean`) pin "in the disk" to
"on the critical line". What was missing was the bridge to the ACTUAL coefficient `genuineLamSeq`: the
**Bombieri–Lagarias 1999 representation**, `λₙ = Σ_ρ (1 − Re((1−1/ρ)ⁿ))`, the limit of finite partial
witness sums over the nontrivial zeros.

THIS FILE supplies that bridge, honestly. `BLZeroSum` packages the two genuine classical facts as
hypotheses (a structure, NOT axioms):
- `onLine_unit` — under RH every enumerated zero's Cayley factor has unit modulus (`liRatio_on_line`
  transported through the Cayley map). A geometric fact about the zeros; it is NOT `λₙ ≥ 0`.
- `bl` — `[CLASSICAL, Bombieri–Lagarias 1999]` the genuine `λₙ` is the limit of the partial witness
  sums over the enumerated zeros. An EQUALITY (true regardless of RH); it does NOT assert any sign.

Neither field is the conclusion, so the pipeline is non-circular. The new CONSTRUCTIVE content is
`Rnonneg_Rlim` (non-negativity passes to a Bishop limit) plus the wiring: under RH every partial
witness sum is `≥ 0` (the witness), so their limit — `λₙ` — is `≥ 0`. The result
`bl_rh_implies_liNonneg : BLZeroSum E → AllZerosOnLine → LiNonneg (genuineLamSeq)` is axiom-clean
`{propext, Quot.sound}`: the classical content lives in the hypothesis `BLZeroSum`, visible to
`#print axioms`, and the RH content is the explicit `AllZerosOnLine`. Closing the crux would require
INHABITING `BLZeroSum` (classical, available) AND discharging `AllZerosOnLine` (RH, open) — so the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RHWitness
import Core.F1.Analysis.CayleyMap
import Core.F1.Analysis.Reflection
import Core.F1.Analysis.Complete
import Core.F1.Analysis.GenuineLi
import Core.F1.Li

namespace UOR.Bridge.F1Square.Analysis

/-- **Non-negativity passes to a Bishop limit**: if every `X k ≥ 0` then `Rlim X h ≥ 0`. The limit's
    `n`-th approximant is `(X (4n+3)).seq (4n+3) ≥ −1/(4n+4) ≥ −1/(n+1)`, so the regularity floor is
    met at every index. The constructive core of the BL pipeline (a sum of non-negatives, taken to its
    convergent limit, stays non-negative). -/
theorem Rnonneg_Rlim {X : Nat → Real} (h : RReg X) (hX : ∀ k, Rnonneg (X k)) :
    Rnonneg (Rlim X h) := by
  intro n
  have hbc := hX (4 * n + 3) (4 * n + 3)
  have hbd : 0 < (neg (Qbound (4 * n + 3))).den := by show 0 < 4 * n + 3 + 1; omega
  have hab : Qle (neg (Qbound n)) (neg (Qbound (4 * n + 3))) := by
    simp only [Qle, neg, Qbound]; push_cast; omega
  rw [Rlim_seq]
  exact Qle_trans hbd hab hbc

end UOR.Bridge.F1Square.Analysis

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **The Bombieri–Lagarias zero-sum interface for the genuine Li sequence.** The two genuine
    classical facts, as explicit hypotheses (a structure, not axioms):

    * `zeroCayley k` — the Cayley factor `1 − 1/ρₖ` of the `k`-th enumerated nontrivial zero;
    * `onLine_unit` — under RH each has unit modulus (`liRatio_on_line` through the Cayley map);
    * `reg` / `bl` — `[CLASSICAL, Bombieri–Lagarias 1999]` `λₙ` is the (convergent) limit of the finite
      partial witness sums `Σ_{k<M} (1 − Re((zeroCayley k)ⁿ))` over the zeros.

    `bl` is an EQUALITY (no sign claim) and `onLine_unit` is a geometric fact — neither is `λₙ ≥ 0`,
    so deriving Li-nonnegativity from this interface is non-circular. -/
structure BLZeroSum (E : StieltjesEta) where
  /-- the nontrivial zero set (abstract; the genuine analytic object) -/
  isZero : Complex → Prop
  /-- the Cayley factor `1 − 1/ρₖ` of the `k`-th enumerated zero -/
  zeroCayley : Nat → Complex
  /-- under RH every enumerated Cayley factor has unit modulus (`liRatio_on_line`, transported) -/
  onLine_unit : AllZerosOnLine isZero → ∀ k, Req (cnormSq (zeroCayley k)) one
  /-- the partial witness sums converge (BL convergence) -/
  reg : ∀ n, RReg (fun M => witnessSum ((List.range M).map zeroCayley) n)
  /-- `[CLASSICAL, Bombieri–Lagarias 1999]`: `λₙ` is the limit of the partial zero witness sums -/
  bl : ∀ n, 0 < n →
    Req (genuineLamSeq E.eta n)
        (Rlim (fun M => witnessSum ((List.range M).map zeroCayley) n) (reg n))

/-- **THE FORWARD DIRECTION, CONSTRUCTIVELY, END TO END**: `RH ⟹ λₙ ≥ 0` for the genuine Li sequence.
    Under `AllZerosOnLine`, every enumerated Cayley factor has unit modulus (`onLine_unit`), so each is
    in the closed disk and every finite partial witness sum is `≥ 0` (`witnessSum_nonneg`); the limit
    is `≥ 0` (`Rnonneg_Rlim`); and `λₙ` IS that limit (`bl`). The classical Bombieri–Lagarias content
    is the hypothesis `BLZeroSum` (visible to `#print axioms`, not an axiom); the RH content is the
    explicit `AllZerosOnLine`. Axiom-clean; the crux fields stay `none` (inhabiting `BLZeroSum` is
    classical, discharging `AllZerosOnLine` is RH). -/
theorem bl_rh_implies_liNonneg (E : StieltjesEta) (B : BLZeroSum E)
    (hRH : AllZerosOnLine B.isZero) : LiNonneg (genuineLamSeq E.eta) := by
  intro n hn
  have hunit := B.onLine_unit hRH
  have hpart : ∀ M, Rnonneg (witnessSum ((List.range M).map B.zeroCayley) n) := by
    intro M
    refine witnessSum_nonneg _ n ?_
    intro w hw
    obtain ⟨k, _, hk⟩ := List.mem_map.mp hw
    exact Rle_of_Req (hk ▸ hunit k)
  have hlim : Rnonneg
      (Rlim (fun M => witnessSum ((List.range M).map B.zeroCayley) n) (B.reg n)) :=
    Rnonneg_Rlim (B.reg n) hpart
  exact Rnonneg_congr (Req_symm (B.bl n hn)) hlim

/-- **The `onLine_unit` leg, DISCHARGED — `BLZeroSum` from genuine zero data.** This constructor
    builds a `BLZeroSum` whose Cayley factors are the GENUINE constructive Cayley transforms
    `liRatio ρₖ = 1 − 1/ρₖ` (`CayleyMap.lean`) of an enumerated zero family, with `onLine_unit`
    DERIVED (`cnormSq_liRatio_on_line`) rather than assumed: on the line `|1−1/ρ|² = 1` is a
    consequence of the Li growth-ratio geometry (`liRatio_on_line`), not an independent input.

    The inputs that remain are exactly the genuine classical core (no RH, no positivity hidden):
    * `zeroEnum`/`henum` — an enumeration of the nontrivial zeros (the genuine analytic zero set);
    * `cw`/`hcw` — per-zero positivity witnesses for `|ρₖ|²` (`ρₖ ≠ 0`, a true geometric fact, since
      nontrivial zeros have `0 < Re < 1`);
    * `reg`/`bl` — `[CLASSICAL, Bombieri–Lagarias 1999]` the partial witness sums converge and `λₙ` is
      their limit (an EQUALITY; no sign claim).

    So the BL interface is shrunk to its irreducible classical content; `onLine_unit` is no longer a
    hypothesis. Feeding this to `bl_rh_implies_liNonneg` still needs `AllZerosOnLine` (RH), so the crux
    fields stay `none`. -/
def blZeroSum_ofZeros (E : StieltjesEta)
    (isZero : Complex → Prop)
    (zeroEnum : Nat → Complex)
    (cw : Nat → Nat)
    (hcw : ∀ j, Qlt (Qbound (cw j)) ((CnormSq (zeroEnum j)).seq (cw j)))
    (henum : ∀ j, isZero (zeroEnum j))
    (reg : ∀ n, RReg (fun M =>
      witnessSum ((List.range M).map (fun j => liRatio (zeroEnum j) (cw j) (hcw j))) n))
    (bl : ∀ n, 0 < n → Req (genuineLamSeq E.eta n)
      (Rlim (fun M =>
        witnessSum ((List.range M).map (fun j => liRatio (zeroEnum j) (cw j) (hcw j))) n) (reg n))) :
    BLZeroSum E where
  isZero := isZero
  zeroCayley := fun j => liRatio (zeroEnum j) (cw j) (hcw j)
  onLine_unit := fun hRH j =>
    cnormSq_liRatio_on_line (zeroEnum j) (cw j) (hcw j) (hRH (zeroEnum j) (henum j))
  reg := reg
  bl := bl

/-- **The forward direction from genuine zero data**: with `onLine_unit` discharged via the Cayley
    map, `RH ⟹ λₙ ≥ 0` follows from the genuine classical core alone (the zero enumeration and the BL
    zero-sum). A convenience wrapper around `bl_rh_implies_liNonneg ∘ blZeroSum_ofZeros`; the RH input
    `AllZerosOnLine` is still required and never discharged, so the crux fields stay `none`. -/
theorem bl_rh_implies_liNonneg_ofZeros (E : StieltjesEta)
    (isZero : Complex → Prop) (zeroEnum : Nat → Complex) (cw : Nat → Nat)
    (hcw : ∀ j, Qlt (Qbound (cw j)) ((CnormSq (zeroEnum j)).seq (cw j)))
    (henum : ∀ j, isZero (zeroEnum j))
    (reg : ∀ n, RReg (fun M =>
      witnessSum ((List.range M).map (fun j => liRatio (zeroEnum j) (cw j) (hcw j))) n))
    (bl : ∀ n, 0 < n → Req (genuineLamSeq E.eta n)
      (Rlim (fun M =>
        witnessSum ((List.range M).map (fun j => liRatio (zeroEnum j) (cw j) (hcw j))) n) (reg n)))
    (hRH : AllZerosOnLine isZero) : LiNonneg (genuineLamSeq E.eta) :=
  bl_rh_implies_liNonneg E (blZeroSum_ofZeros E isZero zeroEnum cw hcw henum reg bl) hRH

/-- **The Voros dichotomy interface — the reverse direction.** Extends `BLZeroSum` with the genuine
    classical fact for `λₙ ≥ 0 ⟹ RH`:

    * `dichotomy` — `[CLASSICAL, Voros 2006 / Li 1997]` Voros's strict dichotomy as a CONSTRUCTIVE
      disjunction: each zero is EITHER on the critical line OR forces a negative Li coefficient at some
      `n` (an off-line zero contributes a Li term of modulus `r(ρ)ⁿ → ∞`, `liTerm_dominates`, whose
      exponential oscillation breaks positivity — no third option). Stated as `∨` so the reverse
      direction is choice-free (no `by_contra`).

    Carried as an explicit hypothesis; it is the reverse companion to `bl`, and it is not the
    conclusion (it is a per-zero alternative, not a claim about all `λₙ`). -/
structure LiBridge (E : StieltjesEta) extends BLZeroSum E where
  /-- `[CLASSICAL, Voros (MPAG 2006) / Lagarias (Ann. Inst. Fourier 2007)]`: Voros's tempered-vs-
      exponential dichotomy — each zero is on the line, OR some `λₙ < 0`. The off-line ⟹ negative step
      is ASYMPTOTIC: an off-line zero's contribution grows like `r(ρ)ⁿ` (steepest descent / Darboux)
      and overtakes the smooth `(n/2)log n` trend only at enormous `n` — a literature estimate puts the
      threshold at `n ≳ T²/t` for a zero `½+t±iT` (≈ `10²⁵` given RH verified to `T₀ ≈ 2.4·10¹²`), which
      is exactly why no finite computation reaches a violation. The reverse direction needs only the
      EXISTENCE `∃n`, which the asymptotic theorem supplies — so this `∃n` interface is the faithful
      minimal form. (Quantitative threshold surfaced by the v0.21.0+ literature survey, arXiv
      2204.01036; the asymptotic dichotomy itself is Voros/Lagarias.) -/
  dichotomy : ∀ ρ, isZero ρ →
    OnCriticalLine ρ ∨ (∃ n, 0 < n ∧ Pos (Rneg (genuineLamSeq E.eta n)))

/-- **THE REVERSE DIRECTION**: `λₙ ≥ 0 ∀n ⟹ RH` (every zero on the critical line). For each zero, the
    Voros dichotomy gives on-line or a negative coefficient; under `LiNonneg` the latter is impossible
    (`not_Pos_of_Rnonneg_neg`), so the zero is on the line. Choice-free. -/
theorem liNonneg_implies_onLine (E : StieltjesEta) (L : LiBridge E)
    (h : LiNonneg (genuineLamSeq E.eta)) : AllZerosOnLine L.isZero := by
  intro ρ hρ
  obtain hon | ⟨n, hn, hpos⟩ := L.dichotomy ρ hρ
  · exact hon
  · exact absurd hpos (not_Pos_of_Rnonneg_neg
      (Rnonneg_congr (Req_symm (Rneg_neg (genuineLamSeq E.eta n))) (h n hn)))

/-- **LI'S CRITERION FOR THE GENUINE SEQUENCE, BOTH DIRECTIONS**: `λₙ ≥ 0 ∀n ⟺ RH`. Forward is the
    witness pipeline (`bl_rh_implies_liNonneg`); reverse is the Voros dichotomy
    (`liNonneg_implies_onLine`). Both classical inputs — Bombieri–Lagarias (`bl`) and Voros
    (`offline_forces_neg`) — are explicit hypotheses of `LiBridge`, visible to `#print axioms`; the
    equivalence itself is axiom-clean `{propext, Quot.sound}`. This makes precise, as one statement,
    that proving `LiNonneg (genuineLamSeq)` IS proving RH. Inhabiting `LiBridge` is classical;
    discharging either side is RH — the crux fields stay `none`. -/
theorem li_criterion (E : StieltjesEta) (L : LiBridge E) :
    LiNonneg (genuineLamSeq E.eta) ↔ AllZerosOnLine L.isZero :=
  ⟨liNonneg_implies_onLine E L, bl_rh_implies_liNonneg E L.toBLZeroSum⟩

/-- **LI'S CRITERION IN THE WITNESS'S OWN GEOMETRY**: for a reflection-closed zero set,
    `λₙ ≥ 0 ∀n ⟺ every zero's Cayley factor lies in the closed unit disk` (`|1−1/ρ|² ≤ 1`). This is
    the most natural geometric phrasing of RH on this substrate — it composes `li_criterion`
    (`LiNonneg ⟺ AllZerosOnLine`) with the set-level closure `allInClosedDisk_iff_allOnLine`
    (`closed-disk ⟺ on-line`, the functional-equation reflection at work). The closed-disk side is
    exactly the hypothesis the manifest sum-of-nonnegatives witness (`witnessSum_nonneg`) consumes —
    so this says, precisely, that the witness applies to the whole zero set iff Li-positivity holds.
    Discharging either side is RH; the crux fields stay `none`. -/
theorem li_criterion_disk (E : StieltjesEta) (L : LiBridge E)
    (hcl : ReflClosed L.isZero) :
    LiNonneg (genuineLamSeq E.eta) ↔ (∀ z, L.isZero z → InClosedDisk z) :=
  Iff.trans (li_criterion E L) (allInClosedDisk_iff_allOnLine L.isZero hcl).symm

end UOR.Bridge.F1Square.Square
