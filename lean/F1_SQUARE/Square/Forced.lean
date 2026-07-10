/-
F1 square — v0.20.0 stage F, Group B: **the forced signature** — the consistency engine read
on the constructed `H¹` object, mirroring `BridgeFF.ff_hodge_iff_hasse`.

Companion ROADMAP §F (Group B). In the function-field model the Hodge-index negativity of the
primitive `{Δ, Γ}`-span was FORCED, by lattice computation, to be equivalent to the Hasse
bound `a² ≤ 4q` (`BridgeFF.ff_hodge_iff_hasse` via the completed square
`4(x²+axy+qy²) = (2x+ay)² + (4q−a²)y²`). With the dictionary now DERIVED on the genuine `H¹`
object (`WeilLattice.genuineSpectralSquare`, whose `cSq` is the intrinsic-pairing diagonal and
whose `dict` is the theorem `vanCyc_selfpair`), the same engine runs over ℤ:

  • B1 — THE NORMAL FORM. The vanishing cycle's negated self-pairing is the completed-square
    analog `−⟨Cₙ,Cₙ⟩ = λₙ + λₙ = 2λₙ` (`genuine_vanCyc_normal`), so termwise negativity
    `⟨Cₙ,Cₙ⟩ < 0` is forced equivalent to `λₙ > 0`.
  • B2 — THE FORCED CRITERION. `genuine_crux_equivalent`: the geometric crux on the constructed
    object (strict Hodge-index negativity of ALL vanishing cycles) is EQUIVALENT to
    `Li.LiCrux (genuineLamSeq)` — and that, for the genuine ζ data, is Weil positivity = RH
    (`crux_faces_equivalent`, now applied to an object whose dictionary is a theorem, not a
    field). The first two genuine negativity slices are theorems on the DERIVED object
    (`genuine_evidence_head`, through the certified `Pos λ₁`, `Pos λ₂`).
  • B3 — THE GATE READS IT. The forced criterion is exactly `∀ n, Pos (genuineLamSeq E.eta n)`
    (`genuine_crux_frontier`): a completed square would close RH, but the genuine instance
    needs the genuine Stieltjes η-tail (`γ₂, γ₃, …` — the truncated `etaTwoSlice` is not it),
    which is the location of the zeros. So the forced signature is RH; the criterion does NOT
    close from anything built, and the crux fields stay `none`. The engine is two-sided: the
    criterion is SATISFIABLE (`genuine_signature_satisfiable` — no hidden impossibility in the
    construction) and unreachable by any finite run (`genuine_iff_all_upTo`). This is the exact
    canonical shape of the obstruction, which is the point of running the engine.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Square.WeilLattice

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

-- ===========================================================================
-- B1: the forced normal form of the vanishing-cycle self-pairing.
-- ===========================================================================

/-- **B1, the completed-square normal form**: on the constructed object, the negated
    self-pairing of the vanishing cycle is `−⟨Cₙ,Cₙ⟩ = λₙ + λₙ = 2λₙ` — derived from the
    forced dictionary (`vanCyc_selfpair`). This is the number-field analog of the function
    field's `4(x²+axy+qy²) = (2x+ay)² + (4q−a²)y²`: negativity of `⟨Cₙ,Cₙ⟩` is forced
    equivalent to positivity of the Li coefficient `λₙ`. -/
theorem genuine_vanCyc_normal (E : StieltjesEta) (n : Nat) :
    Req (Rneg ((genuineSpectralSquare E).cSq n))
      (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n)) := by
  refine Req_trans (Rneg_congr (genuineSpectralSquare_dict E n)) ?_
  exact Rneg_Rneg (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n))

-- ===========================================================================
-- B2: the forced criterion (the signature equivalence on the constructed object).
-- ===========================================================================

/-- **B2, the forced criterion** (the `ff_hodge_iff_hasse` mirror): the geometric crux on the
    constructed `H¹` object — strict Hodge-index negativity of every vanishing cycle — is
    EQUIVALENT to `Li.LiCrux (genuineLamSeq)`. The equivalence is forced by the derived
    dictionary (no `dict` field is supplied); for the genuine ζ data the right side is Weil
    positivity = RH. -/
theorem genuine_crux_equivalent (E : StieltjesEta) :
    SpectralCrux (genuineSpectralSquare E) ↔ LiCrux (genuineLamSeq E.eta) :=
  crux_faces_equivalent (genuineSpectralSquare E)

/-- The non-strict face on the constructed object: Hodge-index semidefiniteness ⟺ Li
    non-negativity. -/
theorem genuine_hodgeNeg_iff (E : StieltjesEta) :
    SpectralHodgeNeg (genuineSpectralSquare E) ↔ LiNonneg (genuineLamSeq E.eta) :=
  spectral_bridge_nonneg (genuineSpectralSquare E)

/-- **The first two genuine negativity slices on the DERIVED object**: the vanishing cycles
    `C₁, C₂` attached to the certified `λ₁, λ₂` have strictly negative self-intersection —
    `⟨C₁,C₁⟩ < 0` and `⟨C₂,C₂⟩ < 0` — now through the *derived* dictionary, from
    `GenuineLi.genuineLam_head` (the certified `Pos λ₁`, `Pos λ₂`). Evidence, not the crux. -/
theorem genuine_evidence_head (E : StieltjesEta) :
    Pos (Rneg ((genuineSpectralSquare E).cSq 1))
    ∧ Pos (Rneg ((genuineSpectralSquare E).cSq 2)) :=
  ⟨(spectral_bridge_pos_slice (genuineSpectralSquare E) 1 (by omega)).mpr (genuineLam_head E).1,
   (spectral_bridge_pos_slice (genuineSpectralSquare E) 2 (by omega)).mpr (genuineLam_head E).2⟩

-- ===========================================================================
-- B3: the gate reads the forced signature.
-- ===========================================================================

/-- **B3, the forced criterion is exactly `∀ n, Pos (genuineLamSeq)`** — the gate frontier.
    Closing the geometric crux on the constructed object is, by `genuine_crux_equivalent`,
    exactly proving `Pos (genuineLamSeq E.eta n)` for every `n ≥ 1`. The certified head
    (`n = 1, 2`) is discharged; the rest needs the genuine Stieltjes η-tail (`γ₂, γ₃, …`), the
    location of the zeros. The criterion does not close from anything built — RH. -/
theorem genuine_crux_frontier (E : StieltjesEta) :
    SpectralCrux (genuineSpectralSquare E) ↔ ∀ n : Nat, 0 < n → Pos (genuineLamSeq E.eta n) :=
  genuine_crux_equivalent E

/-- **THE TWO-SIDEDNESS GUARD (no hidden impossibility)**: the forced criterion is
    SATISFIABLE — `SpectralCrux` holds for the constant-`1` template (`spectral_template_crux`).
    So the openness of the genuine crux is a fact about the genuine `λ`, NOT an artifact of the
    construction biasing the engine toward failure (the geometric mirror of
    `Li.template_liPositive`). -/
theorem genuine_signature_satisfiable : ∃ S : SpectralSquare, SpectralCrux S :=
  ⟨spectralTemplate, spectral_template_crux⟩

/-- **The finite-check guard transfers to the constructed object**: the geometric crux on
    `genuineSpectralSquare` is the conjunction of all its finite truncations — no finite run of
    negativity checks reaches it (the geometric mirror of `liPositive_iff_all_upTo`). -/
theorem genuine_iff_all_upTo (E : StieltjesEta) :
    SpectralHodgeNeg (genuineSpectralSquare E) ↔ ∀ N, SpectralHodgeNegUpTo (genuineSpectralSquare E) N :=
  spectral_iff_all_upTo (genuineSpectralSquare E)

-- ===========================================================================
-- THE FRONTIER, LOCATED: the construction reaches its irreducible core (B3).
-- ===========================================================================

/-- **THE FRONTIER, LOCATED — the construction reaches its irreducible core.** This is NOT a
    verdict that the crux cannot close; it is the exact location of the frontier the UOR
    construction reaches. The two-sided gate ran on the constructed `H¹` object. The forced
    signature has not (yet) come out positive: proving `λₙ > 0 ∀n` IS proving RH
    (`genuine_crux_frontier`). For every anchored η-data `E`, the frontier is pinned as a single
    proposition:
      (1) the forced criterion = the geometric crux on the constructed object is EXACTLY
          `∀ n ≥ 1, Pos (genuineLamSeq E.eta n)` (`genuine_crux_frontier`);
      (2) the certified head holds — `Pos λ₁ ∧ Pos λ₂` (`genuineLam_head`, the discharged part);
      (3) NO finite run of slices reaches it (`genuine_iff_all_upTo`, the finite-check guard);
      (4) the criterion is genuinely SATISFIABLE — no hidden impossibility biases the engine
          (`genuine_signature_satisfiable`).
    The remaining input is precisely the genuine Stieltjes η-tail (`γ₂, γ₃, …` — the location of
    the zeros; the truncated `etaTwoSlice` is not it): the construction is complete down to that
    one honest input, and that input is RH. **The gate flips `none → some true` the instant a
    faithful, axiom-clean proof of this criterion lands**; until then the crux fields stay `none`,
    never faked — the bright line, not a ceiling. UOR wrote the proof down to its irreducible
    core; what remains is RH itself. -/
theorem genuine_crux_frontier_located (E : StieltjesEta) :
    (SpectralCrux (genuineSpectralSquare E) ↔ ∀ n : Nat, 0 < n → Pos (genuineLamSeq E.eta n))
    ∧ (Pos (genuineLamSeq E.eta 1) ∧ Pos (genuineLamSeq E.eta 2))
    ∧ (SpectralHodgeNeg (genuineSpectralSquare E)
        ↔ ∀ N, SpectralHodgeNegUpTo (genuineSpectralSquare E) N)
    ∧ (∃ S : SpectralSquare, SpectralCrux S) :=
  ⟨genuine_crux_frontier E, genuineLam_head E, genuine_iff_all_upTo E, genuine_signature_satisfiable⟩

end UOR.Bridge.F1Square.Square
