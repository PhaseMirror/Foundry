import Multiplicity.F1.Analysis.Real

/-
F1 square — the constructive real number interface, re-exported from the
`UOR.Bridge.F1Square.Analysis` development into the `F1.ConstructiveAnalysis`
namespace Multiplicity.for use by the analytic bridge.

This is a thin wrapper with zero duplication: all definitions and theorems
live in `F1.Analysis.Real` (`UOR.Bridge.F1Square.Analysis`); this module
only re-exports them under the analytic-bridge namespace.
-/

namespace Multiplicity.F1.ConstructiveAnalysis
export UOR.Bridge.F1Square.Analysis (Real Req Pos Radd Rneg zero one half Rle Rnonneg Rmul Rsub RofNat ofQ RlogNat Pos_congr Req_refl Req_symm Req_trans Radd_comm Radd_zero Radd_neg Rmul_comm Rmul_zero Rone_mul Rsub_zero Rneg_Rneg Rneg_congr Radd_congr Rmul_congr Rsub_congr Rle_refl Rle_trans Rle_antisymm Rle_total Qle_refl Qle_trans Qle_antisymm Qlt_iff_le_not_eq Qbound_den_pos)
end Multiplicity.F1.ConstructiveAnalysis
