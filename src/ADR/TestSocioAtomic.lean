import ADR.SocioAtomic

open SocioAtomic

def test_multiplicity : Bool :=
  let m1 : Multiplicity := ⟨1.0⟩
  let m2 : Multiplicity := ⟨0.0⟩
  (compute_multiplicity m1 == 3.0) && (compute_multiplicity m2 == 1.0)

def test_civic_state : Bool :=
  let factors := #[1.0, 2.0, 3.0, 4.0]
  -- lambda_m = 0.5, factors_sum = 10.0, res = 2.0, emb = 1.5 => 15.0
  let state := calculate_civic_state 0.5 factors 2.0 1.5
  state == 15.0

#eval test_multiplicity
#eval test_civic_state
