-- CertificateCore/Certificate.lean
-- Axiom-Clean Certified Graph Learning core
-- Enforces spectral contraction certificate bounds without Mathlib

structure GraphParams where
  n : Nat
  alpha : Float
  lambda_2 : Float
  lambda_max : Float

def is_valid_step (p : GraphParams) : Bool :=
  -- alpha must be in (0, 2 / lambda_max)
  let alpha_upper := 2.0 / p.lambda_max
  (0.0 < p.alpha) && (p.alpha < alpha_upper)

def certificate_bound (p : GraphParams) : Float :=
  1.0 - p.alpha * p.lambda_2

-- FFI-exported certificate check function
@[export certificate_check]
def certificate_check (n : Nat) (ratio : Float) (alpha lambda_2 lambda_max : Float) : Bool :=
  let p := GraphParams.mk n alpha lambda_2 lambda_max
  if not (is_valid_step p) then
    false
  else
    let bound := certificate_bound p
    ratio ≤ bound + 1e-12
