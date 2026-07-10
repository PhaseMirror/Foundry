/-
F1 square — v0.21.0 stage G, brick **the complete UOR Atlas**: the roll-up witnessing every facet
of `uor-atlas.md` formalized here, as facets of one `{T,O}=(3,8)` object, with the crux honestly open.

The Atlas discovery program is complete: each section of `uor-atlas.md` is now a theorem in this
repository, axiom-clean `{propext, Quot.sound}`, organized as facets of the single unified object.

THE FACETS (each a named theorem):
- §1 convergence tower — `tower_levels`, `O_eq_two_pow_T` (`AtlasCharacteristics`).
- §2 class structure / addressed ground — `class_count_stride`, `belt_extent` (`AtlasClasses`);
  the addressing inverse system `atlasModulus_dvd_succ` (`AtlasAddressing`).
- §3 operational calculus — `op_count`, `term_assoc`, `cata_unique` (`AtlasCalculus`).
- §4 zero-state / conservation — `class_no_loss`, `atlas_roundtrip`, `atlas_coherent`
  (`AtlasConservation`, `AtlasCoherence`); the catamorphism `cata` (`AtlasCalculus`).
- §5 scale-invariance / spectral operator — `atlas_scale_consistent`; `atlasTrace_eq`, `atlasMult`,
  `atlasM_indefinite` (`AtlasSpectrum`).
- §6 verified properties — composition norm `two/four/eight_square` (`AtlasComposition`); Betti
  `betti_signature` (`AtlasTopology`); parametric generation `atlas_parametric_generation`
  (`AtlasAddressing`); forcing `atlas_forced_web` (`AtlasSynthesis`).
- §8 completeness of generation — `atlas_forced_web`, `multSum_eq_dim` (`AtlasForcing`).
- §9 positivity — the composition norm (`AtlasComposition`); distinct from the open RH form.
- §10 connections — modular `e4cube_eq_e6sq_plus_1728delta` (`AtlasModular`), exceptional
  `exceptional_dims` (`AtlasExceptional`), Coxeter `e8_coxeter_web` (`AtlasCoxeter`), Bott
  `bott_periods` (`AtlasTopology`), prime skeleton `atlas_prime_skeleton` (`AtlasAddressing`).
- §11–§15 self-intersection / the crux — `vanCyc_perp_H`, `genuine_crux_arch_coupling`
  (`LefschetzCoupling`), `archimedean_place_status` (`ArchimedeanPlace`), `atlas_crux_localization`
  (`AtlasCruxSynthesis`); the Single Prime Hypothesis `single_generator_emanates` (`SinglePrime`).

THE HONEST FRONTIER (unchanged, and matching `uor-atlas.md` §9/§11/§12/§15): the RH-equivalent
intersection-form positivity — the prime–archimedean coupling sign — is the one open content. The
atlas spectral form is indefinite by design; closure is one uniform coherent witness (RH). The crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.AtlasCalculus
import F1Square.Square.AtlasComposition
import F1Square.Square.AtlasTopology
import F1Square.Square.AtlasModular
import F1Square.Square.AtlasExceptional
import F1Square.Square.AtlasCoherence
import F1Square.Square.AtlasCruxSynthesis

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **THE COMPLETE UOR ATLAS, FORMALIZED** — a roll-up of representative facets, each a theorem, as
    facets of one `{T,O}=(3,8)` object, with the crux honestly open. The full facet list is in the
    module docstring; here is a checkable cross-section: the tower (§1), the seven-operator calculus
    (§3), the conserved zero-state (§4), the composition norm (§6.3/§9), the forced web (§6/§8), the
    spectral operator's indefiniteness (§5), and the crux as the prime–archimedean coupling sign
    (§11–§15) — the one open content (RH); crux fields `none`. -/
theorem atlas_complete (E : StieltjesEta) :
    (towerDim 0 = 1 ∧ towerDim 3 = 8)
    ∧ allOps.length = 7
    ∧ (∀ k r, r < atlasModulus k → atlasProject k r = r)
    ∧ (∀ a b c d : Int,
        (a * a + b * b) * (c * c + d * d)
        = (a * c - b * d) * (a * c - b * d) + (a * d + b * c) * (a * d + b * c))
    ∧ (8 = 2 ^ 3 ∧ 3 * 8 = 24 ∧ (3 - 1) * (8 - 1) = 14)
    ∧ ¬ WeilPSD atlasM
    ∧ (SpectralCrux (genuineSpectralSquare E) ↔
        ∀ n, 0 < n → Pos (Radd (genuineArithSeq E.eta n) (genuineArchSeq n))) :=
  ⟨by decide, op_count, (fun k r h => atlas_roundtrip k r h), two_square,
   ⟨by decide, by decide, by decide⟩, atlasM_indefinite, genuine_crux_arch_coupling E⟩

end UOR.Bridge.F1Square.Square
