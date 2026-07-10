namespace GOLDILOCKS

/-- The Goldilocks Prime p = 2^64 - 2^32 + 1 -/
def p : Nat := 2^64 - 2^32 + 1

instance : NeZero p := ⟨by decide⟩

/-- Goldilocks Finite Field -/
abbrev Field := Fin p

instance : Coe Nat Field where
  coe n := ⟨n % p, Nat.mod_lt _ (by decide)⟩

instance : Sub Field where
  sub a b := ⟨(a.val + (p - b.val)) % p, Nat.mod_lt _ (by decide)⟩

def Field.pow (base : Field) : Nat → Field
  | 0 => (1 : Field)
  | k + 1 => base * Field.pow base k

instance : HPow Field Nat Field where
  hPow base exp := Field.pow base exp

end GOLDILOCKS
