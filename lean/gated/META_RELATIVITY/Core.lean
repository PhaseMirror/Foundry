namespace META_RELATIVITY

/-- Scale for discrete integer math: 10000 = 1.0 -/
def scale : Nat := 10000

/-- Absolute difference for Nat. -/
def dist (x y : Nat) : Nat :=
  if x ≥ y then x - y else y - x

/-- Gate 1: Micro-Macro Derivation -/
structure Gate1 where
  f_nl : Nat
  coupling_strength : Nat

def Gate1.is_valid (g : Gate1) : Prop := 
  g.f_nl = 0 ∧ g.coupling_strength ≤ 1000 -- 0.1 * 10000

/-- Gate 2: RG-Prior Justification. 
    Requires `|theta_1 - 2.0| / 2.0 < 0.20` -> `|theta_1 - 20000| < 4000` -/
structure Gate2 where
  theta_1 : Nat

def Gate2.is_valid (g : Gate2) : Prop := 
  dist g.theta_1 (2 * scale) < 4000

/-- Gate 3: Correlated Smoking Gun.
    Valid if the slope A is within [200, 500].
    Since A is just a number, we scale the bounds: [200 * scale, 500 * scale] -/
structure Gate3 where
  a : Nat

def Gate3.is_valid (g : Gate3) : Prop := 
  200 * scale ≤ g.a ∧ g.a ≤ 500 * scale

/-- Gate 4: Truncation Hierarchy. 
    `beta_lambda_8 / beta_lambda_6 < 0.03` -> `beta_lambda_8 * 100 < beta_lambda_6 * 3`
    `delta_c_ratio < 0.04` -> `delta_c_ratio < 400` -/
structure Gate4 where
  beta_lambda_8 : Nat
  beta_lambda_6 : Nat
  delta_c_ratio : Nat

def Gate4.is_valid (g : Gate4) : Prop := 
  g.beta_lambda_8 * 100 < g.beta_lambda_6 * 3 ∧ 
  g.delta_c_ratio < 400

/-- Gate 5: Complete Causal Chain -/
structure Gate5 where
  g1 : Gate1
  g2 : Gate2
  g3 : Gate3
  g4 : Gate4

/-- Gate 5 is valid if all preceding gates are valid. -/
def Gate5.is_valid (g : Gate5) : Prop := 
  g.g1.is_valid ∧ g.g2.is_valid ∧ g.g3.is_valid ∧ g.g4.is_valid

end META_RELATIVITY
