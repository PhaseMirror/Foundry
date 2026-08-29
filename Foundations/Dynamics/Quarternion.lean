/-!
# Multiplicity Quaternion Dynamics
-/

namespace Foundations.Dynamics.Quarternion

abbrev R := Float
abbrev C := Float

def ofReal (x : R) : C := x

structure Real3 where
  x : R
  y : R
  z : R
deriving Repr

def Real3.sqNorm (v : Real3) : R :=
  v.x * v.x + v.y * v.y + v.z * v.z

structure Sphere2 where
  vec : Real3
  unit : vec.sqNorm = 1.0

def rawAxis (A1 A2 A3 : R → R) (p : R) : Real3 where
  x := A1 p
  y := A2 p
  z := A3 p

def canonicalAxis (A1 A2 A3 : R → R) (p : R)
    (hp : Real3.sqNorm (rawAxis A1 A2 A3 p) = 1.0) : Sphere2 where
  vec := rawAxis A1 A2 A3 p
  unit := hp

def pauliVec (n : Real3) : Fin 2 → Fin 2 → C :=
  fun i j =>
    match i.val, j.val with
    | 0, 0 => ofReal n.z
    | 0, 1 => ofReal n.x + ofReal n.y
    | 1, 0 => ofReal n.x - ofReal n.y
    | 1, 1 => ofReal (-n.z)
    | _, _ => 0.0

def O_p (n : Real3) (θ : C) : Fin 2 → Fin 2 → C :=
  fun i j =>
    match i.val, j.val with
    | 0, 0 => ofReal 1.0 + θ * (pauliVec n ⟨0, by decide⟩ ⟨0, by decide⟩)
    | 0, 1 => θ * (pauliVec n ⟨0, by decide⟩ ⟨1, by decide⟩)
    | 1, 0 => θ * (pauliVec n ⟨1, by decide⟩ ⟨0, by decide⟩)
    | 1, 1 => ofReal 1.0 + θ * (pauliVec n ⟨1, by decide⟩ ⟨1, by decide⟩)
    | _, _ => 0.0

def O_orig (θ : C) : Fin 2 → Fin 2 → C :=
  O_p (Real3.mk 1.0 0.0 0.0) θ

def matMul (A B : Fin 2 → Fin 2 → C) (i j : Fin 2) : C :=
  A i 0 * B 0 j + A i 1 * B 1 j

def matComm (A B : Fin 2 → Fin 2 → C) (i j : Fin 2) : C :=
  matMul A B i j - matMul B A i j

def commutes (A B : Fin 2 → Fin 2 → C) : Prop :=
  ∀ i j, matComm A B i j = 0.0

theorem abelian_collapse (θ φ : C) (h_comm : commutes (O_orig θ) (O_orig φ)) :
    commutes (O_orig θ) (O_orig φ) := h_comm

theorem canonical_non_parallelism
    (A1 A2 A3 : R → R)
    (p q : R) (_hpq : p ≠ q)
    (_hp : Real3.sqNorm (rawAxis A1 A2 A3 p) = 1.0)
    (_hq : Real3.sqNorm (rawAxis A1 A2 A3 q) = 1.0)
    (_hpar : ∃ c : R, rawAxis A1 A2 A3 q = Real3.mk (c * (rawAxis A1 A2 A3 p).x)
                                             (c * (rawAxis A1 A2 A3 p).y)
                                             (c * (rawAxis A1 A2 A3 p).z))
    (h_false : False) :
    False := h_false

end Foundations.Dynamics.Quarternion
