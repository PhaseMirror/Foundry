/-!
# Universal Multiplicity Constant — WHT Epistasis (Pure Lean 4 Core)
-/

namespace Multiplicity.WHTEpistasis

def prime_labels : List Nat := [2, 3, 5, 7, 11, 13]

def spectral_weight (zeta : List Bool) : Nat :=
  let pairs := zeta.zip prime_labels
  pairs.foldl (fun acc (b, p) => if b then acc * p else acc) 1

theorem prime_labels_len : prime_labels.length = 6 := rfl

theorem spectral_weight_empty : spectral_weight [] = 1 := rfl

end Multiplicity.WHTEpistasis
