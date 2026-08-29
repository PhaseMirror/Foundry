import Init
import AlphaFunction.Core

/-! # Alpha Function — Diagnostics

Structured diagnostics schema for alpha function evaluation.
-/

namespace AlphaFunction.Diagnostics

open AlphaFunction.Core

/-- Convergence flags. -/
structure ConvergenceFlags where
  integral : Bool
  series : Bool
  deriving Repr

/-- Performance metrics. -/
structure PerformanceMetrics where
  nodes_used : Nat
  terms_used : Nat
  compute_time_ns : Nat
  deriving Repr

/-- Full diagnostics record. -/
structure AlphaDiagnostics where
  convergence_flags : ConvergenceFlags
  estimated_error : Float
  computation_path : String
  performance : PerformanceMetrics
  deriving Repr

/-- Default diagnostics. -/
def defaultDiagnostics : AlphaDiagnostics := {
  convergence_flags := { integral := false, series := false },
  estimated_error := 0.0,
  computation_path := "series",
  performance := { nodes_used := 0, terms_used := 0, compute_time_ns := 0 }
}

/-- Merge diagnostics from hybrid evaluation. -/
def mergeDiagnostics (d1 d2 : AlphaDiagnostics) : AlphaDiagnostics := {
  convergence_flags := {
    integral := d1.convergence_flags.integral ∨ d2.convergence_flags.integral,
    series := d1.convergence_flags.series ∨ d2.convergence_flags.series
  },
  estimated_error := if d1.estimated_error > d2.estimated_error then d1.estimated_error else d2.estimated_error,
  computation_path := "hybrid",
  performance := {
    nodes_used := d1.performance.nodes_used + d2.performance.nodes_used,
    terms_used := d1.performance.terms_used + d2.performance.terms_used,
    compute_time_ns := d1.performance.compute_time_ns + d2.performance.compute_time_ns
  }
}

/-- Verified diagnostics properties. -/
theorem merge_computation_path (d1 d2 : AlphaDiagnostics) :
  (mergeDiagnostics d1 d2).computation_path = "hybrid" := rfl

theorem default_diagnostics_error : defaultDiagnostics.estimated_error = 0.0 := rfl

end AlphaFunction.Diagnostics
