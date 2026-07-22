import Core.universal_constant.Core
import Core.universal_constant.Contraction

open UMCPAROM

theorem dist_mul_right (a b c : Nat) : dist (a * c) (b * c) = dist a b * c := by
  unfold dist
  split
  · next h =>
    have h2 : b * c ≤ a * c := Nat.mul_le_mul_right c h
    rw [if_pos h2, Nat.mul_sub_right_distrib]
  · next h =>
    have h2 : ¬(a * c ≥ b * c) := by
      intro h_contra
      have h3 : a * c < b * c := Nat.mul_lt_mul_of_lt_of_pos (Nat.lt_of_not_ge h) (by omega)
      omega
    rw [if_neg h2, Nat.mul_sub_right_distrib]

theorem dist_mul_left (a b c : Nat) : dist (c * a) (c * b) = c * dist a b := by
  unfold dist
  split
  · next h =>
    have h2 : c * b ≤ c * a := Nat.mul_le_mul_left c h
    rw [if_pos h2, Nat.mul_sub_left_distrib]
  · next h =>
    have h2 : ¬(c * a ≥ c * b) := by
      intro h_contra
      have h3 : c * a < c * b := Nat.mul_lt_mul_of_lt_of_pos (Nat.lt_of_not_ge h) (by omega)
      omega
    rw [if_neg h2, Nat.mul_sub_left_distrib]

theorem dist_add_add_le (a b c d : Nat) : dist (a + c) (b + d) ≤ dist a b + dist c d := by
  unfold dist
  omega

theorem umc_joint_contraction_proof (sys : JointSystem) (s1 s2 : UMCState) :
  joint_norm (update sys s1) (update sys s2) ≤ 
  max (sys.rhoX + sys.c1) (sys.rhoLam + sys.c2) * joint_norm s1 s2 := by
  unfold joint_norm update
  have h1 : dist (sys.rhoX * s1.x + sys.c2 * s1.lam) (sys.rhoX * s2.x + sys.c2 * s2.lam) ≤ 
            dist (sys.rhoX * s1.x) (sys.rhoX * s2.x) + dist (sys.c2 * s1.lam) (sys.c2 * s2.lam) := 
    dist_add_add_le _ _ _ _
  have h2 : dist (sys.rhoLam * s1.lam + sys.c1 * s1.x) (sys.rhoLam * s2.lam + sys.c1 * s2.x) ≤ 
            dist (sys.rhoLam * s1.lam) (sys.rhoLam * s2.lam) + dist (sys.c1 * s1.x) (sys.c1 * s2.x) := 
    dist_add_add_le _ _ _ _
  rw [dist_mul_left, dist_mul_left] at h1
  rw [dist_mul_left, dist_mul_left] at h2
  have h3 : sys.rhoX * dist s1.x s2.x + sys.c2 * dist s1.lam s2.lam +
            (sys.rhoLam * dist s1.lam s2.lam + sys.c1 * dist s1.x s2.x) = 
            (sys.rhoX + sys.c1) * dist s1.x s2.x + (sys.rhoLam + sys.c2) * dist s1.lam s2.lam := by omega
  omega
