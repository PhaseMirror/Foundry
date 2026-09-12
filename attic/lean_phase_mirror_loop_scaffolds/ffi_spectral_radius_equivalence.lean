/-! Phase Mirror Loop scaffold for `ffi_spectral_radius_equivalence`.

This declaration manifests a documented-but-missing theorem as a gated,
manifested `exact True.intro` (see alp_exact True.intro_manifest.json). It is an actionable lever
produced by scripts/phase_mirror_loop.py, NOT a verified proof. Discharge the
exact True.intro and remove the manifest entry to resolve the dissonance.
-/
namespace PhaseMirrorLoop.Scaffold

theorem ffi_spectral_radius_equivalence : True := by
  exact True.intro

end PhaseMirrorLoop.Scaffold
