import F1.ConstructiveAnalysis.Real
import F1.ConstructiveAnalysis.List

structure BeatSpectrumStats where
  peak_frequencies : List ℝ
  mean_spacing : ℝ
  level_repulsion_dip : ℝ

structure KernelTelemetry where
  xn_kernel : ℝ
  wt_max_kernel : ℝ
  protection_zeta : ℝ
  is_valid_kernel : Bool
  zeta_shadow : ℝ
  first_zero_approx : ℝ
  telemetry_version : Nat := 2
  beat_spectrum_stats : BeatSpectrumStats
  gue_deviation : ℝ
