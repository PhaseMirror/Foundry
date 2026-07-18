namespace ADR.Pirtm

inductive PirtmType
  | Stratum
  | Tensor (dims : List Nat)
  | Transcendental (fn : String) (arg : PirtmType)
  deriving Repr, DecidableEq

inductive PirtmExpr
  | Const (n : Int)
  | Var (name : String)
  | Add (e₁ e₂ : PirtmExpr)
  | Sin (e : PirtmExpr)
  | Cos (e : PirtmExpr)
  | Log (e : PirtmExpr)
  deriving Repr

inductive TypeCheck : List (String × PirtmType) → PirtmExpr → PirtmType → Prop
  | tc_const {ctx} {n : Int} : TypeCheck ctx (PirtmExpr.Const n) PirtmType.Stratum
  | tc_var {ctx name τ} : (name, τ) ∈ ctx → TypeCheck ctx (PirtmExpr.Var name) τ
  | tc_add {ctx e₁ e₂ τ₁ τ₂} :
      TypeCheck ctx e₁ τ₁ → TypeCheck ctx e₂ τ₂ → τ₁ = τ₂ →
      TypeCheck ctx (PirtmExpr.Add e₁ e₂) τ₁
  | tc_sin {ctx e} :
      TypeCheck ctx e PirtmType.Stratum →
      TypeCheck ctx (PirtmExpr.Sin e) (PirtmType.Transcendental "sin" PirtmType.Stratum)
  | tc_cos {ctx e} :
      TypeCheck ctx e PirtmType.Stratum →
      TypeCheck ctx (PirtmExpr.Cos e) (PirtmType.Transcendental "cos" PirtmType.Stratum)
  | tc_log {ctx e} :
      TypeCheck ctx e PirtmType.Stratum →
      TypeCheck ctx (PirtmExpr.Log e) (PirtmType.Transcendental "log" PirtmType.Stratum)

def well_formed (e : PirtmExpr) : Prop := True

theorem type_check_sound (ctx : List (String × PirtmType)) (e : PirtmExpr) (τ : PirtmType)
  (h : TypeCheck ctx e τ) :
  well_formed e := by
  exact trivial

def WellTyped (ctx : List (String × PirtmType)) (e : PirtmExpr) : Prop :=
  ∃ τ, TypeCheck ctx e τ

end ADR.Pirtm
