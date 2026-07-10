/-
F1 square — v0.21.0 stage G, brick **G1 (Gate A, the faithful match)**: the atlas pairing fixed by
atlas structure, the match-is-RH identity, and the two-sided no-smuggling guards.

ROADMAP §8 (Stage 1) and §4.1/§5. Gate A is the exact identity `‖ι Cₙ‖²_L = 2λₙ` between two
INDEPENDENTLY defined closed forms: the pairing `atlasPair` from the atlas rule `ι` (no zeros, no
`λ` — the §5 faithfulness invariant), and `λ = genuineLamSeq` from the Stieltjes data. Because Gate
B is free (`atlasPair_psd`), **Gate A proven IS RH** (`gateA_is_liNonneg`): a successful match
exhibits `2λₙ` as the manifest sum of squares `gramOf ι D n n`, and that exhibition is the proof
(§4.1). It is never asserted.

THE NO-SMUGGLING DISCIPLINE (§5). The pairing is `atlasPair ι D = gramOf ι D`, a function of the
atlas rule `ι` ALONE — it takes no `StieltjesEta`/`SpectralSquare`, so `λ` cannot be baked in (the
smuggling corner `atlasPair := −2λ` of §4.1 is excluded at the type level). Two theorems make the
match a genuine non-trivial constraint, not a definitional one:
- `gateA_satisfiable`: the match is NOT vacuously false (the template `2 = 1² + 1²` is realized);
- `gateA_can_fail`: the match is NOT definitionally true (the zero embedding fails to realize the
  template).

So a match is content, not fiat. `scripts/honesty_audit.sh` is extended with the structural
no-smuggling check (the metric analog of `intrinsicH1_dict`'s "no false dictionary can be
supplied"): the pairing definitions never reference `λ`. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.AtlasRule

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

-- ===========================================================================
-- The Gate-A pairing, fixed by atlas structure (λ-free).
-- ===========================================================================

/-- **THE GATE-A PAIRING**, fixed by atlas structure: `atlasPair ι D = gramOf ι D`, the embedding
    Gram. Defined from the atlas rule `ι` ALONE — no `λ`, no spectral data (the §5 no-smuggling
    invariant, enforced by the signature taking no `StieltjesEta`/`SpectralSquare`). -/
def atlasPair (ι : AtlasRule) (D : Nat) : Nat → Nat → Real := gramOf ι D

/-- **Gate B is free** for the Gate-A pairing: it is a sum of squares, hence `WeilPSD`. -/
theorem atlasPair_psd (ι : AtlasRule) (D : Nat) : WeilPSD (atlasPair ι D) :=
  WeilPSD_gramOf ι D

/-- **GATE A**: the atlas pairing matches the genuine diagonal `−⟨Cₙ,Cₙ⟩ = 2λₙ`. -/
def GateA (E : StieltjesEta) (ι : AtlasRule) (D : Nat) : Prop :=
  RealizesDiag (genuineSpectralSquare E) ι D

/-- **§4.1: GATE A, PROVEN UNDER (free) GATE B, IS RH.** A successful match exhibits `2λₙ` as the
    manifest sum of squares `gramOf ι D n n`, i.e. proves `LiNonneg (genuineLamSeq)`. The difficulty
    did not leave Gate A. NEVER asserted. -/
theorem gateA_is_liNonneg (E : StieltjesEta) (ι : AtlasRule) (D : Nat) (h : GateA E ι D) :
    LiNonneg (genuineLamSeq E.eta) :=
  embeds_to_liNonneg (genuineSpectralSquare E) ι D h

-- ===========================================================================
-- The two-sided no-smuggling guards: the match is a real, non-trivial constraint.
-- ===========================================================================

/-- **No-smuggling guard #1 (SATISFIABLE):** Gate A is not vacuously false — the template spectral
    square (`−⟨Cₙ,Cₙ⟩ = 2`) is realized by the constant embedding into `ℝ²` (`2 = 1² + 1²`). -/
theorem gateA_satisfiable :
    ∃ (S : SpectralSquare) (ι : AtlasRule) (D : Nat), RealizesDiag S ι D := by
  refine ⟨spectralTemplate, (fun _ _ => one), 2, ?_⟩
  intro n _
  -- gramOf (fun _ _ => one) 2 n n = (0 + 1·1) + 1·1 ≈ 1 + 1 ; Rneg (cSq n) = −−(1+1) ≈ 1 + 1
  have hzo : Req (Radd zero one) one := Req_trans (Radd_comm zero one) (Radd_zero one)
  have hL : Req (Radd (Radd zero (Rmul one one)) (Rmul one one)) (Radd one one) :=
    Radd_congr (Req_trans (Radd_congr (Req_refl zero) (Rmul_one one)) hzo) (Rmul_one one)
  exact Req_trans hL (Req_symm (Rneg_neg (Radd one one)))

/-- **No-smuggling guard #2 (NON-TRIVIAL):** Gate A is not definitionally true — the zero embedding
    does NOT realize the template (its diagonal `0` cannot equal `2`). So a match is content, not
    fiat; the smuggling corner is excluded. -/
theorem gateA_can_fail :
    ∃ (S : SpectralSquare) (ι : AtlasRule) (D : Nat), ¬ RealizesDiag S ι D := by
  refine ⟨spectralTemplate, (fun _ _ => zero), 1, ?_⟩
  intro h
  have h1 := h 1 (by omega)
  -- gramOf (fun _ _ => zero) 1 1 1 = 0 + 0·0 ≈ 0 ; Rneg (cSq 1) ≈ 1 + 1
  have hg : Req (Radd zero (Rmul zero zero)) (Radd zero zero) :=
    Radd_congr (Req_refl zero) (Rmul_zero zero)
  have hc : Req (Rneg (spectralTemplate.cSq 1)) (Radd one one) := Rneg_neg (Radd one one)
  have hbad : Req (Radd zero zero) (Radd one one) :=
    Req_trans (Req_symm hg) (Req_trans h1 hc)
  exact not_Pos_zero_double (Pos_congr (Req_symm hbad) (Pos_Radd_self Pos_one))

end UOR.Bridge.F1Square.Square
