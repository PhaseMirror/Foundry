import F1.Analysis.GammaZeroBracket

set_option maxRecDepth 1000000
set_option maxHeartbeats 4000000

namespace UOR.Bridge.F1Square.Analysis
private def corrT (n : Nat) : Q := ⟨400 * (4 * n + 1), (4 * n - 1) * (4 * n - 1) + 380⟩
private def corrTel (n : Nat) : Q := ⟨400, (4 * n - 3) * (4 * n - 3) + 380⟩

private theorem corrT_le_teldiff (n : Nat) :
    Qle (corrT n) (Qsub (corrTel n) (corrTel (n + 1))) := by
  simp only [corrT, corrTel, Qsub, Qle, add, neg]
  push_cast
  sorry
