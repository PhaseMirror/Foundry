import Foundations.Analysis.Metric

/-! # Limits -/

namespace Foundations.Analysis

def SeqLimit {α : Type} [MetricSpace α] (x : Nat → α) (a : α) : Prop :=
  SeqConv x a

/-- Limits definition sanity check. -/
theorem seq_limit_def {α : Type} [MetricSpace α] (x : Nat → α) (a : α) :
    SeqLimit x a ↔ SeqConv x a := by
  rfl

end Foundations.Analysis
