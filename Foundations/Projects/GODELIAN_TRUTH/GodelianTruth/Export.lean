import Init
import GodelianTruth.Core
import GodelianTruth.Contraction
import GodelianTruth.Godel
import GodelianTruth.PrimeSieved

/-! # Godelian Truth Export

Generates human-readable Markdown artifacts from the formal model.
-/

namespace GodelianTruth.Export

open GodelianTruth
open GodelianTruth.Contraction
open GodelianTruth.Godel
open GodelianTruth.PrimeSieved

/-- Render core constants as Markdown. -/
def constantsToMd : String :=
  s!"# Godelian Truth Constants\n\n" ++
  s!"| Symbol | Value |\n" ++
  s!"|--------|-------|\n" ++
  s!"| FP_DEN | {FP_DEN} |\n" ++
  s!"| lambda | {lambda} |\n" ++
  s!"| alpha | {alpha} |\n" ++
  s!"| contractionFactor | {contractionFactor} |\n" ++
  s!"| lipschitzBound(lambda,alpha) | {lipschitzBound lambda alpha} |\n"

/-- Render a valuation as Markdown. -/
def valuationToMd (v : Valuation) : String :=
  s!"| Sentence | Value |\n" ++
  s!"|----------|-------|\n" ++
  s!"| P | {v Sentence.atomP} |\n" ++
  s!"| Q | {v Sentence.atomQ} |\n" ++
  s!"| G | {v Sentence.atomG} |\n" ++
  s!"| not G | {v Sentence.notG} |\n" ++
  s!"| P and Q | {v Sentence.pAndQ} |\n"

/-- Render the Godel sentence theorem as Markdown. -/
def godelTheoremToMd : String :=
  s!"# Gödel Coordinate Theorem\n\n" ++
  s!"**Assumption:** SoundnessF (no false provability atoms).\n\n" ++
  s!"**Result:** v*(G) = {FP_DEN} (true).\n\n" ++
  s!"The Gödel sentence G receives value {FP_DEN} under the fixed-point semantics.\n"

/-- Render prime-sieved rate as Markdown. -/
def primeRateToMd : String :=
  s!"# Prime-Sieved Convergence Rate\n\n" ++
  s!"After k steps with π(k) effective updates:\n\n" ++
  s!"‖v_k - v*‖ ≤ (1-λα)^π(k) · ‖v_0 - v*‖\n\n" ++
  s!"With λ={lambda}, α={alpha}, contraction factor = {contractionFactor}.\n"

/-- Example export. -/
def exampleExport : String :=
  constantsToMd ++ "\n" ++
  valuationToMd (fixpointTLambda zeroValuation lambda alpha defaultBias) ++ "\n" ++
  godelTheoremToMd ++ "\n" ++
  primeRateToMd

end GodelianTruth.Export
