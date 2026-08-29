import Foundations.WordLove.Core
import Foundations.WordLove.Proofs

/-!
# Word Love Examples (ADR-0031)

Concrete instantiations, corpora examples, and multi-token aggregate pipelines
demonstrating the Word Love formalization across Hebrew semantic tokens.

## Corpus Examples Included

1. **Love (אַהֲבָה - Ahavah)**: $13 = 13^1$, reduced $4 = 2^2$.
2. **One (אֶחָד - Echad)**: $13 = 13^1$, reduced $4 = 2^2$.
3. **Grace / Lovingkindness (חֶסֶד - Hesed)**: $72 = 2^3 \cdot 3^2$, reduced $9 = 3^2$.
4. **Truth (אֱמֶת - Emet)**: $441 = 3^2 \cdot 7^2$, reduced $9 = 3^2$.
5. **Peace / Wholeness (שָׁלוֹם - Shalom)**: $376 = 2^3 \cdot 47^1$, reduced $7 = 7^1$.
6. **Life (חַיִּים - Hayyim)**: $68 = 2^2 \cdot 17^1$, reduced $5 = 5^1$.

## Pipelines Formalized

- **Echad ↔ Ahavah Multiplicative Binding**:
  $13 \times 13 = 169 = 13^2$, $\Omega = 2$.
- **Divine Covenant Ensemble (Ahavah + Hesed + Emet)**:
  $13 \times 72 \times 441 = 412,776 = 2^3 \cdot 3^4 \cdot 7^2 \cdot 13^1$, $\Omega = 10$.
-/

namespace Foundations.WordLove.Examples

open Foundations.WordLove

/-! ### Extended Corpus of Semantic Tokens -/

/-- Life (Hayyim). -/
def tokenHayyim : SemanticToken :=
  { id := "hayyim", name := "Life", hebrew := "חיים", transliteration := "hayyim",
    description := "The vital dynamic principle of being and renewal" }

/-- Standard Encoding of Hayyim: 68. -/
def encHayyimStd : Encoding :=
  { token := tokenHayyim, scheme := GematriaScheme.Standard, value := 68, positive := by decide }

/-- Reduced Encoding of Hayyim: 5. -/
def encHayyimRed : Encoding :=
  { token := tokenHayyim, scheme := GematriaScheme.Reduced, value := 5, positive := by decide }

/-! ### Trajectories -/

/-- Trajectory for Standard Ahavah. -/
def trajAhavahStd : Trajectory := Trajectory.ofEncoding encAhavahStd

/-- Trajectory for Reduced Ahavah. -/
def trajAhavahRed : Trajectory := Trajectory.ofEncoding encAhavahRed

/-- Trajectory for Standard Echad. -/
def trajEchadStd : Trajectory := Trajectory.ofEncoding encEchadStd

/-- Trajectory for Reduced Echad. -/
def trajEchadRed : Trajectory := Trajectory.ofEncoding encEchadRed

/-- Trajectory for Standard Hesed. -/
def trajHesedStd : Trajectory := Trajectory.ofEncoding encHesedStd

/-- Trajectory for Standard Emet. -/
def trajEmetStd : Trajectory := Trajectory.ofEncoding encEmetStd

/-- Trajectory for Standard Shalom. -/
def trajShalomStd : Trajectory := Trajectory.ofEncoding encShalomStd

/-- Trajectory for Standard Hayyim. -/
def trajHayyimStd : Trajectory := Trajectory.ofEncoding encHayyimStd

/-! ### Aggregated Multi-Token Pipelines -/

/-- Pipeline: Ahavah + Echad (Love and Unity).
    Multiplicity: {13 ↦ 2}, Ω = 2. -/
def pipelineLoveAndUnity : PrimeMultiplicity :=
  combineTrajectories trajAhavahStd trajEchadStd

/-- Pipeline: Love + Grace (Ahavah + Hesed).
    Multiplicity: {2 ↦ 3, 3 ↦ 2, 13 ↦ 1}, Ω = 6. -/
def pipelineLoveAndGrace : PrimeMultiplicity :=
  combineTrajectories trajAhavahStd trajHesedStd

/-- Pipeline: Divine Covenant Ensemble (Ahavah + Hesed + Emet).
    Multiplicity: {2 ↦ 3, 3 ↦ 4, 7 ↦ 2, 13 ↦ 1}, Ω = 10. -/
def pipelineDivineCovenant : PrimeMultiplicity :=
  PrimeMultiplicity.add (combineTrajectories trajAhavahStd trajHesedStd) trajEmetStd.invariant

/-- Pipeline: Holistic Harmony (Ahavah + Shalom + Hayyim).
    Multiplicity: {2 ↦ 5, 13 ↦ 1, 17 ↦ 1, 47 ↦ 1}, Ω = 8. -/
def pipelineHarmony : PrimeMultiplicity :=
  PrimeMultiplicity.add (combineTrajectories trajAhavahStd trajShalomStd) trajHayyimStd.invariant

/-! ### Pipeline Invariant Verification Theorems -/

@[wordlove_proof]
theorem pipeline_love_unity_factors :
    pipelineLoveAndUnity = PrimeMultiplicity.single 13 2 := by
  rfl

@[wordlove_proof]
theorem pipeline_love_unity_omega :
    pipelineLoveAndUnity.omega = 1 := by
  rfl

@[wordlove_proof]
theorem pipeline_love_unity_Omega :
    pipelineLoveAndUnity.Omega = 2 := by
  rfl

@[wordlove_proof]
theorem pipeline_covenant_factors :
    pipelineDivineCovenant = { factors := [
      { prime := 2, exponent := 3 },
      { prime := 3, exponent := 4 },
      { prime := 7, exponent := 2 },
      { prime := 13, exponent := 1 }
    ] } := by
  rfl

@[wordlove_proof]
theorem pipeline_covenant_omega :
    pipelineDivineCovenant.omega = 4 := by
  rfl

@[wordlove_proof]
theorem pipeline_covenant_Omega :
    pipelineDivineCovenant.Omega = 10 := by
  rfl

@[wordlove_proof]
theorem pipeline_harmony_factors :
    pipelineHarmony = { factors := [
      { prime := 2, exponent := 5 },
      { prime := 13, exponent := 1 },
      { prime := 17, exponent := 1 },
      { prime := 47, exponent := 1 }
    ] } := by
  rfl

@[wordlove_proof]
theorem pipeline_harmony_Omega :
    pipelineHarmony.Omega = 8 := by
  rfl

end Foundations.WordLove.Examples
