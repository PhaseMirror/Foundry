import META_RELATIVITY.Core

/-!
# META_RELATIVITY Security

Security context with golden set rollback safety.
All definitions use core Lean 4 types. Zero axioms, zero sorry.
-/

namespace META_RELATIVITY

/-! ## Security Context -/

/-- Security context with golden set rollback. -/
structure SecurityContext (T : Type) where
  golden_set : List T
  whitelist : List String

/-- Rollback returns last golden-set entry. -/
def SecurityContext.rollback {T : Type} (ctx : SecurityContext T) : Option T :=
  ctx.golden_set.getLast?

/-! ## Security Properties -/

/-- Rollback is safe: if golden_set is non-empty, rollback returns some. -/
theorem rollback_safe {T : Type} (ctx : SecurityContext T) (h : ctx.golden_set ≠ []) :
    ∃ v, ctx.rollback = some v := by
  simp only [SecurityContext.rollback]
  have := List.getLast?_eq_some_getLast h
  exact ⟨ctx.golden_set.getLast h, this⟩

/-- Rollback on empty set returns none. -/
theorem rollback_empty {T : Type} :
    SecurityContext.rollback (T := T) ⟨[], []⟩ = none := by
  simp only [SecurityContext.rollback, List.getLast?]

/-- Rollback of single-element list returns that element. -/
theorem rollback_single {T : Type} (v : T) :
    SecurityContext.rollback (T := T) ⟨[v], []⟩ = some v := by
  simp only [SecurityContext.rollback, List.getLast?]
  rfl

/-! ## Whitelist Membership -/

/-- Whitelist is a subset of itself. -/
theorem whitelist_subset_self {T : Type} (ctx : SecurityContext T) :
    ctx.whitelist ⊆ ctx.whitelist :=
  List.Subset.refl ctx.whitelist

/-! ## Security Composition -/

/-- Merging two security contexts combines golden sets and whitelists. -/
def mergeSecurityContext {T : Type}
    (ctx1 ctx2 : SecurityContext T) : SecurityContext T :=
  ⟨ctx1.golden_set ++ ctx2.golden_set, ctx1.whitelist ++ ctx2.whitelist⟩

/-- Merged rollback is safe if either component is non-empty. -/
theorem merge_rollback_safe_left {T : Type}
    (ctx1 ctx2 : SecurityContext T) (h : ctx1.golden_set ≠ []) :
    ∃ v, (mergeSecurityContext ctx1 ctx2).rollback = some v := by
  apply rollback_safe
  intro h_empty
  exact h (List.eq_nil_of_append_eq_nil h_empty |>.1)

end META_RELATIVITY
