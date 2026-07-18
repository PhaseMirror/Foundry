namespace Core.RenormalizationAlpha

/--
The Multiplicity-Renormalizing Alpha acts on prime-indexed multiplicity profiles.
Here we formalize the linear prime-diffusion model on a finite window.
-/
structure AlphaParams (R : Type) where
  gamma : R
  beta : R

/--
Abstract structure for the RG phase classification based on the 
largest eigenvalue approximation lambda_max = 1 - gamma + 2 * beta
-/
class RGSpectrum (R : Type) where
  add : R → R → R
  sub : R → R → R
  mul : R → R → R
  two : R
  one : R
  lt : R → R → Prop
  eq : R → R → Prop

/--
Classifies the RG flow regime based on (gamma, beta).
-/
def isFilterPhase {R : Type} [S : RGSpectrum R] (p : AlphaParams R) : Prop :=
  S.lt (S.mul S.two p.beta) p.gamma

def isRunawayPhase {R : Type} [S : RGSpectrum R] (p : AlphaParams R) : Prop :=
  S.lt p.gamma (S.mul S.two p.beta)

def isCriticalManifold {R : Type} [S : RGSpectrum R] (p : AlphaParams R) : Prop :=
  S.eq (S.mul S.two p.beta) p.gamma

/--
The lambda_max approximation for large N.
-/
def lambdaMaxApprox {R : Type} [S : RGSpectrum R] (p : AlphaParams R) : R :=
  S.add (S.sub S.one p.gamma) (S.mul S.two p.beta)

/--
Theorem: In the critical manifold, lambda_max_approx = 1
-/
theorem critical_lambda_one {R : Type} [S : RGSpectrum R] (p : AlphaParams R) 
  (h_critical : isCriticalManifold p) 
  (h_sub_add_cancel : ∀ a c b, S.eq b c → S.eq (S.add (S.sub a c) b) a) : 
  S.eq (lambdaMaxApprox p) S.one := by
  
  unfold lambdaMaxApprox
  unfold isCriticalManifold at h_critical
  exact h_sub_add_cancel S.one p.gamma (S.mul S.two p.beta) h_critical

end Core.RenormalizationAlpha
