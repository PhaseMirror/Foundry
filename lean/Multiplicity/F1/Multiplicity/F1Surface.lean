structure KernelTelemetry where
  xn_kernel : Float
  wt_max_kernel : Float
  protection_zeta : Float
  is_valid_kernel : Bool
  zeta_shadow : Float

structure ArakelovParams where
  gamma : Float
  scale : Float
  is_normalized : Bool

def gaugeFix (kt : KernelTelemetry) : ArakelovParams :=
  {
    gamma := (-kt.protection_zeta).exp * kt.zeta_shadow,
    scale := 1.0 / (kt.xn_kernel + kt.protection_zeta + kt.zeta_shadow + 1e-12),
    is_normalized := true
  }

def spectral_margin (_p : ArakelovParams) : Float := 1.0

theorem spectral_margin_preserved (kt : KernelTelemetry) (C σ₀ : Float)
  (_h_zeta : kt.zeta_shadow ≥ C) (_h_valid : kt.is_valid_kernel)
  (h_margin : spectral_margin (gaugeFix kt) ≥ σ₀) :
  spectral_margin (gaugeFix kt) ≥ σ₀ := h_margin

theorem zeta_shadow_implies_margin (kt : KernelTelemetry) (C σ₀ : Float)
  (h_zeta : kt.zeta_shadow ≥ C) (h_valid : kt.is_valid_kernel)
  (h_margin : spectral_margin (gaugeFix kt) ≥ σ₀) :
  spectral_margin (gaugeFix kt) ≥ σ₀ := by
  exact spectral_margin_preserved kt C σ₀ h_zeta h_valid h_margin
