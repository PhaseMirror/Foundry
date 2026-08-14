def dt : Float := 0.1

@[export verify_contraction]
def verifyContraction (α β γ : Float) : Bool :=
  let L := Float.abs (1.0 - dt * α) + dt * β * γ
  L < 1.0
