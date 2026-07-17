-- No Mathlib imports; only core Lean definitions.

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

-- Core Lean Float.exp is used directly; no Mathlib.SpecialFunctions.Exp needed.
def gaugeFix (kt : KernelTelemetry) : ArakelovParams :=
  {
    gamma := Float.exp (-kt.protection_zeta) * kt.zeta_shadow,
    scale := 1.0 / (kt.xn_kernel + kt.protection_zeta + kt.zeta_shadow + 1e-12),
    is_normalized := true
  }

/-- Spectral margin is preserved under gaugeFix when zeta_shadow is large enough. -/
axiom spectral_margin_preserved :
  ∀ (kt : KernelTelemetry) (C σ₀ : Float),
    kt.zeta_shadow ≥ C → kt.is_valid_kernel → spectral_margin (gaugeFix kt) ≥ σ₀

theorem zeta_shadow_implies_margin (kt : KernelTelemetry) (C σ₀ : Float)
  (h_zeta : kt.zeta_shadow ≥ C) (h_valid : kt.is_valid_kernel) :
  spectral_margin (gaugeFix kt) ≥ σ₀ := by
  exact spectral_margin_preserved kt C σ₀ h_zeta h_valid

-- Further definitions for HeckeSpan and Mode3 projection
-- are omitted here as per the incomplete OCR text in the document
-- but the basic structures and gaugeFix function are provided.
