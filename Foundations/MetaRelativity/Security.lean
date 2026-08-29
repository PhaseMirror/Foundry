import Foundations.MetaRelativity.Core

/-!
# Foundations.MetaRelativity.Security — Golden Set Rollback Safety

Formalizes the security context with golden set rollback safety.
-/

namespace Foundations.MetaRelativity

structure SecurityContext (T : Type) where
  golden_set : List T
  whitelist : List String

def SecurityContext.rollback {T : Type} (ctx : SecurityContext T) : Option T :=
  ctx.golden_set.getLast?

theorem rollback_safe {T : Type} (ctx : SecurityContext T) (h : ctx.golden_set ≠ []) :
    ∃ v, ctx.rollback = some v := by
  simp only [SecurityContext.rollback]
  have := List.getLast?_eq_some_getLast h
  exact ⟨ctx.golden_set.getLast h, this⟩

theorem rollback_empty {T : Type} :
    SecurityContext.rollback (T := T) ⟨[], []⟩ = none := by
  simp only [SecurityContext.rollback, List.getLast?]

theorem rollback_single {T : Type} (v : T) :
    SecurityContext.rollback (T := T) ⟨[v], []⟩ = some v := by
  simp only [SecurityContext.rollback, List.getLast?]
  rfl

theorem whitelist_subset_self {T : Type} (ctx : SecurityContext T) :
    ctx.whitelist ⊆ ctx.whitelist :=
  List.Subset.refl ctx.whitelist

def mergeSecurityContext {T : Type}
    (ctx1 ctx2 : SecurityContext T) : SecurityContext T :=
  ⟨ctx1.golden_set ++ ctx2.golden_set, ctx1.whitelist ++ ctx2.whitelist⟩

theorem merge_rollback_safe_left {T : Type}
    (ctx1 ctx2 : SecurityContext T) (h : ctx1.golden_set ≠ []) :
    ∃ v, (mergeSecurityContext ctx1 ctx2).rollback = some v := by
  apply rollback_safe
  intro h_empty
  exact h (List.eq_nil_of_append_eq_nil h_empty |>.1)

end Foundations.MetaRelativity
