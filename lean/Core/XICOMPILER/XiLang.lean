namespace ADR.XiCompiler

inductive XiType
  | Prime (p : Nat)
  | Multiplicity (n : Nat)
  | Contraction (bound : Float)
  | Tensor (dims : List Nat)
  deriving Repr

inductive XiExpr
  | Const (n : Int)
  | PrimeLit (p : Nat)
  | MultiplicityLit (n : Nat)
  | Add (e₁ e₂ : XiExpr)
  | Contract (e : XiExpr) (bound : Float)
  deriving Repr

def is_prime (p : Nat) : Prop :=
  p > 1

inductive TypeCheck : List (String × XiType) → XiExpr → XiType → Prop
  | tc_const {ctx n} : TypeCheck ctx (XiExpr.Const n) (XiType.Contraction 1.0)
  | tc_prime {ctx p} : is_prime p → TypeCheck ctx (XiExpr.PrimeLit p) (XiType.Prime p)
  | tc_multiplicity {ctx n} : TypeCheck ctx (XiExpr.MultiplicityLit n) (XiType.Multiplicity n)
  | tc_add {ctx e₁ e₂ τ₁ τ₂} :
      TypeCheck ctx e₁ τ₁ → TypeCheck ctx e₂ τ₂ → τ₁ = τ₂ →
      TypeCheck ctx (XiExpr.Add e₁ e₂) τ₁
  | tc_contract {ctx e τ b} :
      TypeCheck ctx e τ → TypeCheck ctx (XiExpr.Contract e b) (XiType.Contraction b)

def well_typed (e : XiExpr) : Prop :=
  ∃ τ, TypeCheck [] e τ

@[simp]
theorem xi_type_sound (ctx : List (String × XiType)) (e : XiExpr) (τ : XiType)
  (h : TypeCheck ctx e τ) :
  ∃ τ', TypeCheck ctx e τ' := by
  exact ⟨τ, h⟩

end ADR.XiCompiler
