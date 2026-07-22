import Init

namespace CulturalMath

-- Congruence relation
def Cong (a b n : Nat) : Prop := a % n = b % n

theorem cong_refl (a n : Nat) : Cong a a n := rfl
theorem cong_symm {a b n : Nat} (h : Cong a b n) : Cong b a n := h.symm
theorem cong_trans {a b c n : Nat} (h1 : Cong a b n) (h2 : Cong b c n) : Cong a c n :=
  h1.trans h2

theorem cong_add {a b c d n : Nat} (h1 : Cong a c n) (h2 : Cong b d n) :
    Cong (a + b) (c + d) n := by
  simp [Cong] at h1 h2 ⊢
  rw [Nat.add_mod, Nat.add_mod c d n, h1, h2]

theorem cong_mul {a b c d n : Nat} (h1 : Cong a c n) (h2 : Cong b d n) :
    Cong (a * b) (c * d) n := by
  simp [Cong] at h1 h2 ⊢
  rw [Nat.mul_mod, Nat.mul_mod c d n, h1, h2]

-- Proportional reasoning: a/b = c/d iff a*d = b*c
def proportional (a b c d : Nat) : Prop := a * d = b * c

theorem proportional_refl (a b : Nat) : proportional a b a b :=
  Nat.mul_comm a b

theorem proportional_symm {a b c d : Nat} (h : proportional a b c d) :
    proportional c d a b := by
  unfold proportional at h ⊢
  have h1 : c * b = b * c := Nat.mul_comm c b
  have h2 : d * a = a * d := Nat.mul_comm d a
  rw [h1, h2]; exact h.symm

-- Multiplicity value
def multiplicityVal (s : List (Nat × Nat)) : Nat :=
  s.foldl (fun acc (p, e) => acc * p ^ e) 1

theorem multiplicityVal_singleton (p e : Nat) :
    multiplicityVal [(p, e)] = p ^ e := by
  simp [multiplicityVal]

-- Pythagorean triples
structure PythTriple where
  a : Nat
  b : Nat
  c : Nat
  witness : a * a + b * b = c * c

def triple_345 : PythTriple where
  a := 3; b := 4; c := 5
  witness := by omega

def triple_51213 : PythTriple where
  a := 5; b := 12; c := 13
  witness := by omega

def triple_81517 : PythTriple where
  a := 8; b := 15; c := 17
  witness := by omega

end CulturalMath
