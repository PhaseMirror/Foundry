/-!
# Foundations.UniversalConstant.Core — Joint System Contraction & Metric Bounds

Formalizes discrete UMC joint state dynamics, metric scaling, and combined contraction bounds.
-/

namespace Foundations.UniversalConstant

/-- Scale factor: 10000 = 1.0 -/
def scale : Nat := 10000

/-- Absolute discrete distance on Nat. -/
def dist (x y : Nat) : Nat :=
  if x ≥ y then x - y else y - x

/-- Bounded 1D Multiplicity Cell state. -/
structure UMCState where
  x   : Nat
  lam : Nat
  deriving Repr, DecidableEq

/-- Joint System Dynamics parameters. -/
structure JointSystem where
  rhoX          : Nat
  rhoLam        : Nat
  c1            : Nat
  c2            : Nat
  h_contractive : rhoX + c2 < scale ∧ rhoLam + c1 < scale
  deriving Repr

/-- Discrete update mapping. -/
def update (sys : JointSystem) (s : UMCState) : UMCState :=
  { x := sys.rhoX * s.x + sys.c2 * s.lam,
    lam := sys.rhoLam * s.lam + sys.c1 * s.x }

/-- Fixed-weight joint norm. -/
def joint_norm (s1 s2 : UMCState) : Nat :=
  dist s1.x s2.x + dist s1.lam s2.lam

/-- Theorem: Distance distributes with multiplication on the right. -/
theorem dist_mul_right (a b c : Nat) : dist (a * c) (b * c) = dist a b * c := by
  unfold dist
  by_cases h : a ≥ b
  · have h2 : a * c ≥ b * c := Nat.mul_le_mul_right c h
    have h1 : (if a * c ≥ b * c then a * c - b * c else b * c - a * c) = a * c - b * c := if_pos h2
    have h3 : (if a ≥ b then a - b else b - a) = a - b := if_pos h
    rw [h1, h3, Nat.mul_sub_right_distrib]
  · have h4 : (if a ≥ b then a - b else b - a) = b - a := if_neg h
    by_cases hc : c = 0
    · subst hc
      simp
    · have h2 : ¬(a * c ≥ b * c) := by
        intro h_ge
        have hlt : a < b := by omega
        have : a * c < b * c := Nat.mul_lt_mul_of_pos_right hlt (Nat.pos_of_ne_zero hc)
        omega
      have h1 : (if a * c ≥ b * c then a * c - b * c else b * c - a * c) = b * c - a * c := if_neg h2
      rw [h1, h4, Nat.mul_sub_right_distrib]

/-- Theorem: Distance distributes with multiplication on the left. -/
theorem dist_mul_left (a b c : Nat) : dist (c * a) (c * b) = c * dist a b := by
  have h1 : c * a = a * c := Nat.mul_comm c a
  have h2 : c * b = b * c := Nat.mul_comm c b
  have h3 : c * dist a b = dist a b * c := Nat.mul_comm c (dist a b)
  rw [h1, h2, h3, dist_mul_right]

/-- Theorem: Subadditive distance triangle inequality under joint addition. -/
theorem dist_add_add_le (a b c d : Nat) : dist (a + c) (b + d) ≤ dist a b + dist c d := by
  unfold dist
  split <;> split <;> split <;> omega

/-- Theorem: Joint contraction bound on discrete state update. -/
theorem umc_joint_contraction (sys : JointSystem) (s1 s2 : UMCState) :
    joint_norm (update sys s1) (update sys s2) ≤
    (sys.rhoX + sys.c1 + sys.rhoLam + sys.c2) * joint_norm s1 s2 := by
  unfold joint_norm update
  dsimp
  have h1 : dist (sys.rhoX * s1.x + sys.c2 * s1.lam) (sys.rhoX * s2.x + sys.c2 * s2.lam) ≤
            dist (sys.rhoX * s1.x) (sys.rhoX * s2.x) + dist (sys.c2 * s1.lam) (sys.c2 * s2.lam) :=
    dist_add_add_le _ _ _ _
  have h2 : dist (sys.rhoLam * s1.lam + sys.c1 * s1.x) (sys.rhoLam * s2.lam + sys.c1 * s2.x) ≤
            dist (sys.rhoLam * s1.lam) (sys.rhoLam * s2.lam) + dist (sys.c1 * s1.x) (sys.c1 * s2.x) :=
    dist_add_add_le _ _ _ _
  rw [dist_mul_left, dist_mul_left] at h1
  rw [dist_mul_left, dist_mul_left] at h2
  have h_add := Nat.add_le_add h1 h2
  have h_distrib : (sys.rhoX + sys.c1 + sys.rhoLam + sys.c2) * (dist s1.x s2.x + dist s1.lam s2.lam) =
      (sys.rhoX + sys.c1 + sys.rhoLam + sys.c2) * dist s1.x s2.x + (sys.rhoX + sys.c1 + sys.rhoLam + sys.c2) * dist s1.lam s2.lam :=
    Nat.mul_add _ _ _
  have h_dx : sys.rhoX * dist s1.x s2.x + sys.c1 * dist s1.x s2.x = (sys.rhoX + sys.c1) * dist s1.x s2.x := by
    rw [Nat.add_mul]
  have h_dlam : sys.rhoLam * dist s1.lam s2.lam + sys.c2 * dist s1.lam s2.lam = (sys.rhoLam + sys.c2) * dist s1.lam s2.lam := by
    rw [Nat.add_mul]
  have h_le_x : (sys.rhoX + sys.c1) * dist s1.x s2.x ≤ (sys.rhoX + sys.c1 + sys.rhoLam + sys.c2) * dist s1.x s2.x :=
    Nat.mul_le_mul_right (dist s1.x s2.x) (by omega)
  have h_le_lam : (sys.rhoLam + sys.c2) * dist s1.lam s2.lam ≤ (sys.rhoX + sys.c1 + sys.rhoLam + sys.c2) * dist s1.lam s2.lam :=
    Nat.mul_le_mul_right (dist s1.lam s2.lam) (by omega)
  omega

end Foundations.UniversalConstant
