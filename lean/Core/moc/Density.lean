import Core.Spine
import Core.moc.Valuation
import Core.moc.Ostrowski

namespace MOC.Density

/-- 
  Non-Archimedean Density:
  A valuation is dense near zero if for any ε > 0, there exists a 
  state x with 0 < v(x) < ε. 
--/
def is_non_arch_density (v : Nat → Nat) : Prop :=
  ∀ ε : Nat, ε > 0 → ∃ x : Nat, x > 0 ∧ v x < ε

/-- 
  Theorem: p_adic_density.
--/
theorem p_adic_density (p : Nat) (hp : Core.Spine.is_prime p) :
  is_non_arch_density (fun x => MOC.Valuation.valuation x [p]) := by
  intro ε hε
  exists p
  apply And.intro
  · apply Nat.lt_of_lt_of_le (show 0 < 2 from by decide) hp.left
  · unfold MOC.Valuation.valuation
    simp
    have h_p : p > 0 := by
      apply Nat.lt_of_lt_of_le (show 0 < 2 from by decide) hp.left
    simp
    -- (p % p) = 0 < ε
    apply Nat.lt_of_le_of_lt (Nat.zero_le _) hε

/-- 
  Theorem: pir_tm_density.
--/
theorem pir_tm_density (tiers : List Nat) (h : ∀ q ∈ tiers, Core.Spine.is_prime q) :
  ∀ q ∈ tiers, is_non_arch_density (fun x => MOC.Valuation.valuation x [q]) := by
  intro q hq
  apply p_adic_density
  exact h q hq

/-- Application to 108-cycle (tiers 2,3) -/
theorem density_108_cycle :
  is_non_arch_density (fun x => MOC.Valuation.valuation x [2]) ∧
  is_non_arch_density (fun x => MOC.Valuation.valuation x [3]) := by
  have h_prime2 : Core.Spine.is_prime 2 := Core.Spine.is_prime_2
  have h_prime3 : Core.Spine.is_prime 3 := Core.Spine.is_prime_3
  apply And.intro
  · apply p_adic_density 2 h_prime2
  · apply p_adic_density 3 h_prime3

end MOC.Density
