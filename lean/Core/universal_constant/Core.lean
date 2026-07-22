namespace UMCPAROM

/-- Scale: 10000 = 1.0 -/
def scale : Nat := 10000

/-- Absolute difference between two Nat values -/
def dist (x y : Nat) : Nat :=
  if x ≥ y then x - y else y - x

/-- Bounded 1D Multiplicity Cell -/
structure UMCState where
  x : Nat
  lam : Nat
  deriving Repr

/-- Joint System Dynamics -/
structure JointSystem where
  -- Core uncoupled contractions
  rhoX : Nat
  rhoLam : Nat
  -- Cross-coupling bounds
  c1 : Nat
  c2 : Nat
  -- Invariant required for contractivity (spectral gap constraint)
  h_contractive : rhoX + c2 < scale ∧ rhoLam + c1 < scale
  deriving Repr

/-- Discrete update mapping -/
def update (sys : JointSystem) (s : UMCState) : UMCState :=
  { x := sys.rhoX * s.x + sys.c2 * s.lam,
    lam := sys.rhoLam * s.lam + sys.c1 * s.x }

end UMCPAROM
