import F1.Analysis.PsiLine

namespace UOR.Bridge.F1Square.Analysis

private theorem corrT_le_teldiff_test (n : Nat) :
    Qle (corrT n) (Qsub (corrTel n) (corrTel (n + 1))) := by
  simp only [corrT, corrTel, Qsub, Qle, add, neg]
  push_cast
  have hnn : (0 : Int) ≤ 400 * (4 * (n : Int) + 1)
      * ((4 * (n : Int) - 1) * (4 * (n : Int) - 1) + 380) := by
    refine Int.mul_nonneg (Int.mul_nonneg (by decide) (by omega)) ?_
    have hsq : (0 : Int) ≤ (4 * (n : Int) - 1) * (4 * (n : Int) - 1) := by
      rcases Int.le_total 0 (4 * (n : Int) - 1) with h | h
      · exact Int.mul_nonneg h h
      · have h' : (0 : Int) ≤ -(4 * (n : Int) - 1) := by omega
        have hh : (0 : Int) ≤ (-(4 * (n : Int) - 1)) * (-(4 * (n : Int) - 1)) := Int.mul_nonneg h' h'
        simpa using hh
    omega
  exact hnn
