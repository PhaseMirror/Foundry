/-
F1 square — **the reconstruction sums converge to the pairing** (`MomentReconConverge.lean`), the
Mellin-inversion arc, sub-brick I₃b — the weak (pairing) inversion capstone. Along the explicit schedule
`n = (k+1)²`, `δ = k+1`, the reconstruction sum `bernReconSum φ ψ n` — which reads `φ` only through the
finite differences of its moments (I₂) — converges to the pairing `⟨φ,ψ⟩` with an explicit modulus:

    `|⟨φ,ψ⟩ − bernReconSum φ ψ ((k+1)²)| ≤ (5·M_φ.num·L_ψ.num)/(k+1)`   (`bernReconSum_converges`).

So `⟨φ,ψ⟩ = lim_k bernReconSum φ ψ ((k+1)²)`, and the right side is computed entirely from `φ`'s moment
sequence: **the moment transform of `φ` is invertible on its pairing action** — the whole functional
`ψ ↦ ⟨φ,ψ⟩` is recovered from `φ`'s moments alone. The proof divides the multiplied-form reconstruction
energy bound (I₃a) by `2δn = 2(k+1)³`, exactly the determinacy schedule; the `5/8` factor comes from
`δ² + n/4 = (5/4)(k+1)²`, and the final rational inequality is the same
`i − h = 5·M_φ.num·L_ψ.num·(k+1)³·(8·M_φ.den·L_ψ.den − 1) ≥ 0` factoring the determinacy capstone used
(with `φ.L` replaced by `ψ.L`).

WHY (the Sonine route, step 3, the Mellin FRONT). Determinacy (H₈) is the transform pair's injectivity —
the moments *determine* `φ`. This is the constructive inversion of the pairing action: `⟨φ,ψ⟩` is the
limit of quantities read off `φ`'s moments, for every bounded-Lipschitz `ψ`. Together with determinacy
this closes the *weak* form of the moment/Mellin transform pair on the general class.

HONEST SCOPE. The weak (pairing) inversion: `⟨φ,ψ⟩ = lim_k bernReconSum φ ψ ((k+1)²)` with the explicit
rate above. NOT pointwise reconstruction of `φ` from its moments (the strong/uniform inversion), NOT the
full transform-pair surjectivity onto function space, NOT positivity. Step 4 (the band-coupling
positivity) is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MomentReconEnergy
import Foundations.F1.Square.MomentDeterminacy

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **★ THE RECONSTRUCTION SUMS CONVERGE TO THE PAIRING** (weak inversion): along the schedule
    `n = (k+1)²`, `δ = k+1`, the moment-data reconstruction sum is within `(5·M_φ.num·L_ψ.num)/(k+1)` of
    `⟨φ,ψ⟩`, so `bernReconSum φ ψ ((k+1)²) → ⟨φ,ψ⟩`. Divide the reconstruction energy bound (I₃a) by the
    weight `2δn = 2(k+1)³`; the residual rational inequality factors as in the determinacy capstone. -/
theorem bernReconSum_converges (φ ψ : L2Test) (k : Nat) :
    Rle (Rabs (Rsub (innerI φ ψ)
          (bernReconSum φ ψ ((k + 1) * (k + 1))
            (Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k)))))
        (ofQ (⟨((5 * (φ.M.num * ψ.L.num)).toNat : Int), k + 1⟩ : Q) (Nat.succ_pos k)) := by
  have hn : 0 < (k + 1) * (k + 1) := Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k)
  have hδd : 0 < (⟨((k + 1 : Nat) : Int), 1⟩ : Q).den := Nat.one_pos
  have hδn : 0 ≤ (⟨((k + 1 : Nat) : Int), 1⟩ : Q).num := Int.ofNat_nonneg _
  have hEB := bernOp_recon_energy_bound φ ψ ((k + 1) * (k + 1)) hn
    (⟨((k + 1 : Nat) : Int), 1⟩ : Q) hδd hδn
  -- reciprocal weight `R = 2(k+1)³` as a `Nat`
  have hcnum : (mul (mul (⟨2, 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
      (⟨(((k + 1) * (k + 1) : Nat) : Int), 1⟩ : Q)).num
      = ((2 * (k + 1) * ((k + 1) * (k + 1)) : Nat) : Int) := by
    show (2 * ((k + 1 : Nat) : Int)) * (((k + 1) * (k + 1) : Nat) : Int)
        = ((2 * (k + 1) * ((k + 1) * (k + 1)) : Nat) : Int)
    push_cast; ring_uor
  have hR : 0 < 2 * (k + 1) * ((k + 1) * (k + 1)) :=
    Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos k)) hn
  refine Rle_trans (Rle_of_Rmul_ofQ_le (2 * (k + 1) * ((k + 1) * (k + 1))) hR _ hcnum _ hEB) ?_
  refine Rle_ofQ_ofQ _ (Nat.succ_pos k) ?_
  have hC : ((5 * (φ.M.num * ψ.L.num)).toNat : Int) = 5 * (φ.M.num * ψ.L.num) :=
    Int.toNat_of_nonneg (by have := Int.mul_nonneg φ.hMn ψ.hLn; omega)
  have hMD : (1 : Int) ≤ (φ.M.den : Int) * (ψ.L.den : Int) := by
    have : 1 ≤ φ.M.den * ψ.L.den := Nat.mul_le_mul φ.hMd ψ.hLd
    exact_mod_cast this
  have hK : (0 : Int) ≤ (k : Int) + 1 := by omega
  show Qle (mul (⟨(1 : Int), 2 * (k + 1) * ((k + 1) * (k + 1))⟩ : Q)
              (mul (mul φ.M ψ.L)
                (add (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) (⟨((k + 1 : Nat) : Int), 1⟩ : Q))
                  (⟨(((k + 1) * (k + 1) : Nat) : Int), 4⟩ : Q))))
           (⟨((5 * (φ.M.num * ψ.L.num)).toNat : Int), k + 1⟩ : Q)
  simp only [Qle, mul, add]
  rw [hC]; push_cast
  have hfac :
      5 * (φ.M.num * ψ.L.num) * (2 * ((k : Int) + 1) * (((k : Int) + 1) * ((k : Int) + 1))
          * ((φ.M.den : Int) * (ψ.L.den : Int) * 4))
        - 1 * (φ.M.num * ψ.L.num * (((k : Int) + 1) * ((k : Int) + 1) * 4
            + ((k : Int) + 1) * ((k : Int) + 1) * 1)) * ((k : Int) + 1)
      = 5 * (φ.M.num * ψ.L.num) * (((k : Int) + 1) * ((k : Int) + 1) * ((k : Int) + 1))
          * (8 * ((φ.M.den : Int) * (ψ.L.den : Int)) - 1) := by ring_uor
  have hnn : (0 : Int) ≤ 5 * (φ.M.num * ψ.L.num)
      * (((k : Int) + 1) * ((k : Int) + 1) * ((k : Int) + 1))
      * (8 * ((φ.M.den : Int) * (ψ.L.den : Int)) - 1) :=
    Int.mul_nonneg (Int.mul_nonneg (by have := Int.mul_nonneg φ.hMn ψ.hLn; omega)
      (Int.mul_nonneg (Int.mul_nonneg hK hK) hK)) (by omega)
  omega

end Multiplicity.UOR.Bridge.F1Square.Square
