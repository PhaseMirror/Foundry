import MOC.Core

inductive Token where
  | Deploy
  | Scale
  | Revoke
  | WebService
  | Cluster
  | With
  | Replicas
  | Num3
  | All
  deriving DecidableEq

def tokenToPrime (t : Token) : Nat :=
  match t with
  | Token.Deploy => 2
  | Token.Scale => 3
  | Token.WebService => 5
  | Token.Cluster => 7
  | Token.With => 11
  | Token.Replicas => 13
  | Token.Num3 => 17
  | Token.Revoke => 19
  | Token.All => 1

def compileTokensAux (acc : MOCWord) (ts : List Token) : MOCWord :=
  match ts with
  | [] => acc
  | t :: ts' => compileTokensAux (MOCWord.Comp acc (MOCWord.Ap (tokenToPrime t))) ts'

def compileTokens (ts : List Token) : Option MOCWord :=
  match ts with
  | [] => none
  | t :: ts' => some (compileTokensAux (MOCWord.Ap (tokenToPrime t)) ts')

-- A Safe Sentence is one that avoids topological expansion (avoids Token.All)
-- We define a subset of grammar that represents valid CNL commands
inductive ValidCommand : List Token → Prop where
  | deploy_service : ValidCommand [Token.Deploy, Token.WebService, Token.Cluster]
  | scale_service : ValidCommand [Token.Scale, Token.WebService, Token.With, Token.Replicas, Token.Num3]
  | revoke_it : ValidCommand [Token.Revoke, Token.WebService]

-- Theorem: All Valid Commands compile to a valid MOCWord that satisfies Contraction < 1.0 (10000)
theorem valid_commands_contract (s : List Token) (h : ValidCommand s) :
  ∃ w, compileTokens s = some w ∧ EvalNF_c w < 10000 := by
  cases h
  · -- deploy_service
    exact ⟨MOCWord.Comp (MOCWord.Comp (MOCWord.Ap 2) (MOCWord.Ap 5)) (MOCWord.Ap 7), by decide⟩
  · -- scale_service
    exact ⟨MOCWord.Comp (MOCWord.Comp (MOCWord.Comp (MOCWord.Comp (MOCWord.Ap 3) (MOCWord.Ap 5)) (MOCWord.Ap 11)) (MOCWord.Ap 13)) (MOCWord.Ap 17), by decide⟩
  · -- revoke_it
    exact ⟨MOCWord.Comp (MOCWord.Ap 19) (MOCWord.Ap 5), by decide⟩

-- Theorem: All Valid Commands satisfy Resonance Tension >= 1.0 (10000)
theorem valid_commands_resonate (s : List Token) (h : ValidCommand s) :
  ∃ w, compileTokens s = some w ∧ EvalNF_rsc w ≥ 10000 := by
  cases h
  · exact ⟨MOCWord.Comp (MOCWord.Comp (MOCWord.Ap 2) (MOCWord.Ap 5)) (MOCWord.Ap 7), by decide⟩
  · exact ⟨MOCWord.Comp (MOCWord.Comp (MOCWord.Comp (MOCWord.Comp (MOCWord.Ap 3) (MOCWord.Ap 5)) (MOCWord.Ap 11)) (MOCWord.Ap 13)) (MOCWord.Ap 17), by decide⟩
  · exact ⟨MOCWord.Comp (MOCWord.Ap 19) (MOCWord.Ap 5), by decide⟩

-- Theorem: A command containing Token.All is strictly expansive (c >= 10000) if it's the only token
theorem all_is_expansive :
  ∃ w, compileTokens [Token.All] = some w ∧ EvalNF_c w ≥ 10000 := by
  exact ⟨MOCWord.Ap 1, by decide⟩
