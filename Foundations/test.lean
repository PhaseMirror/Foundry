import Multiplicity.Spine
def test (a : Nat) : 0 < 2 ^ a := Nat.pos_pow_of_pos a (by decide)
