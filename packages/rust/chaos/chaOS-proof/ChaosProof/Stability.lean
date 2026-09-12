-- No Mathlib imports; core Lean 4 Float is used directly.

-- Convex wrapper Φ(z) = log(1 + e^z)
noncomputable def phi (z : Float) : Float := Float.log (1 + Float.exp z)

-- Lyapunov candidate V = Φ(-R)
noncomputable def v_lyapunov (r_val : Float) : Float := phi (-r_val)

-- Fejér monotonicity
def is_fejer_monotone (v_prev v_next : Float) (tol : Float) : Prop :=
  v_next - v_prev <= tol

-- Spectral radius contractivity axiom (Placeholder for spectral property)
axiom spectral_radius_contractive (T : Matrix n n Float) (eta : Float) : Prop
