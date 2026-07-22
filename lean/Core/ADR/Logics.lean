import ADR.Core

namespace ADR.Logics

inductive Literal where
  | context  : String → Literal
  | decision : String → Literal
  | conseq   : String → Literal
  | and      : Literal → Literal → Literal
  | or       : Literal → Literal → Literal
  | implies  : Literal → Literal → Literal
  | bottom   : Literal
  deriving Repr, DecidableEq, Inhabited

namespace Literal

def toString : Literal → String
  | .context s  => s!"[Ctx] {s}"
  | .decision s => s!"[Dec] {s}"
  | .conseq s   => s!"[Con] {s}"
  | .and a b    => s!"({toString a} ∧ {toString b})"
  | .or a b     => s!"({toString a} ∨ {toString b})"
  | .implies a b => s!"({toString a} → {toString b})"
  | .bottom     => "⊥"

instance : ToString Literal where toString := Literal.toString

def ofADR (ctx dec c : String) : Literal :=
  .and (.context ctx) (.and (.decision dec) (.conseq c))

def eval (v : String → Bool) : Literal → Bool
  | .context s  => v s
  | .decision s => v s
  | .conseq s   => v s
  | .and a b    => eval v a ∧ eval v b
  | .or a b     => eval v a ∨ eval v b
  | .implies a b => eval v a → eval v b
  | .bottom     => False

def entails (ctx dec consequence : Literal) (v : String → Bool) : Prop :=
  eval v ctx = true ∧ eval v dec = true → eval v consequence = true

structure ConsequenceClause where
  literal : Literal
  rationale : String
  deriving Repr

instance : Inhabited ConsequenceClause where
  default := { literal := .bottom, rationale := "" }

structure GovernancePolicy where
  clauses : List ConsequenceClause
  deriving Repr

def GovernancePolicy.empty : GovernancePolicy := { clauses := [] }

def GovernancePolicy.add (p : GovernancePolicy) (c : ConsequenceClause) : GovernancePolicy :=
  { p with clauses := c :: p.clauses }

def GovernancePolicy.coversConsequences (p : GovernancePolicy) (adr : ADR) : Bool :=
  adr.consequences.all (fun c =>
    p.clauses.any (fun clause => clause.literal.toString.contains c)
  )

def GovernancePolicy.isEntailed (p : GovernancePolicy) (ctx dec conseq : Literal) (v : String → Bool) : Prop :=
  ∃ clause ∈ p.clauses, entails ctx dec clause.literal v

def ofStringsEntails (ctx dec c : String) (v : String → Bool) : Prop :=
  entails (.context ctx) (.decision dec) (.conseq c) v

end Literal
end ADR.Logics
