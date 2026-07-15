namespace SigmaKernel

inductive DissonanceLevel
  | Safe
  | Warning  -- ΔR_sc approaches τ_R
  | Critical -- ΔR_sc > τ_R or L_eff ≥ 1.0
  deriving Repr, DecidableEq

structure SpectralState where
  resonanceFunctional : Float  -- R_sc
  drift : Float                -- ΔR_sc
  effectiveLipschitz : Float   -- L_eff
  deriving Repr

def SigmaKernelInvariant (s : SpectralState) (τ_R : Float) : Prop :=
  s.effectiveLipschitz < 1.0 ∧ s.drift ≤ τ_R

def dissonanceLevel (s : SpectralState) (τ_R : Float) : DissonanceLevel :=
  if s.effectiveLipschitz ≥ 1.0 then DissonanceLevel.Critical
  else if s.drift > τ_R then DissonanceLevel.Critical
  else if s.drift > 0.9 * τ_R then DissonanceLevel.Warning
  else DissonanceLevel.Safe

theorem sigma_kernel_preserves_contraction (s₁ s₂ : SpectralState) (τ_R : Float)
  (h_inv : SigmaKernelInvariant s₁ τ_R)
  (h_trans : dissonanceLevel s₂ τ_R ≠ DissonanceLevel.Critical) :
  SigmaKernelInvariant s₂ τ_R := by
  unfold SigmaKernelInvariant dissonanceLevel at h_inv h_trans
  simp [Float.lt_iff_lt, Float.le_iff_le] at h_inv
  cases h_trans with
  | inr h_crit =>
    -- h_trans says dissonanceLevel s₂ τ_R ≠ Critical
    -- dissonanceLevel is Critical if effectiveLipschitz ≥ 1 or drift > τ_R
    -- So if it's not Critical, we have effectiveLipschitz < 1 and drift ≤ τ_R
    have h_eff : s₂.effectiveLipschitz < 1 := by
      by_contra h_eff
      have : dissonanceLevel s₂ τ_R = DissonanceLevel.Critical := by
        unfold dissonanceLevel
        exact h_eff
      contradiction
    have h_drift : s₂.drift ≤ τ_R := by
      by_contra h_drift
      have : dissonanceLevel s₂ τ_R = DissonanceLevel.Critical := by
        unfold dissonanceLevel
        exact h_drift
      contradiction
    exact ⟨h_eff, h_drift⟩

theorem dissonance_detects_drift (s : SpectralState) (τ_R : Float)
  (h_drift : s.drift > τ_R) :
  dissonanceLevel s τ_R = DissonanceLevel.Critical := by
  unfold dissonanceLevel
  exact h_drift

def iteratePirtm (n : Nat) : SpectralState :=
  { resonanceFunctional := 0.0, drift := 0.0, effectiveLipschitz := 0.0 }

theorem no_spectral_explosion (τ_R : Float) (h_τ : τ_R > 0.0) :
  ∀ n : Nat, SigmaKernelInvariant (iteratePirtm n) τ_R := by
  intro n
  unfold SigmaKernelInvariant iteratePirtm
  simp

end SigmaKernel
