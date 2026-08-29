/-!
# Foundations.CNL.Core — Controlled Natural Language (CNL) & Prime Operator Words

Formalizes the Controlled Natural Language grammar, token-to-prime semantic mapping,
and deterministic word compilation pipeline.
-/

namespace Foundations.CNL

/-- Controlled natural language token alphabet. -/
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
  deriving DecidableEq, Repr

/-- Semantic mapping from CNL tokens to prime operators. -/
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

/-- Prime operator word structure. -/
inductive Word where
  | Ap   : Nat → Word
  | Comp : Word → Word → Word
  deriving DecidableEq, Repr

/-- Auxiliary fold helper for word compilation. -/
def compileTokensAux (acc : Word) (ts : List Token) : Word :=
  match ts with
  | [] => acc
  | t :: ts' => compileTokensAux (Word.Comp acc (Word.Ap (tokenToPrime t))) ts'

/-- Compile a list of tokens into an executable prime operator word. -/
def compileTokens (ts : List Token) : Option Word :=
  match ts with
  | [] => none
  | t :: ts' => some (compileTokensAux (Word.Ap (tokenToPrime t)) ts')

/-- Grammar subset representing valid, certified CNL commands. -/
inductive ValidCommand : List Token → Prop where
  | deploy_service : ValidCommand [Token.Deploy, Token.WebService, Token.Cluster]
  | scale_service  : ValidCommand [Token.Scale, Token.WebService, Token.With, Token.Replicas, Token.Num3]
  | revoke_it      : ValidCommand [Token.Revoke, Token.WebService]

/-- Theorem: DeployService compiles deterministically to the composite prime word (2 * 5) * 7. -/
theorem deploy_compiles_correctly :
    compileTokens [Token.Deploy, Token.WebService, Token.Cluster] =
    some (Word.Comp (Word.Comp (Word.Ap 2) (Word.Ap 5)) (Word.Ap 7)) := rfl

/-- Theorem: RevokeService compiles deterministically to 19 * 5. -/
theorem revoke_compiles_correctly :
    compileTokens [Token.Revoke, Token.WebService] =
    some (Word.Comp (Word.Ap 19) (Word.Ap 5)) := rfl

/-- Theorem: ScaleService compiles deterministically to the 5-prime operator word. -/
theorem scale_compiles_correctly :
    compileTokens [Token.Scale, Token.WebService, Token.With, Token.Replicas, Token.Num3] =
    some (Word.Comp (Word.Comp (Word.Comp (Word.Comp (Word.Ap 3) (Word.Ap 5)) (Word.Ap 11)) (Word.Ap 13)) (Word.Ap 17)) := rfl

/-- Theorem: All valid commands compile successfully to well-defined operator words. -/
theorem valid_commands_compile (s : List Token) (h : ValidCommand s) :
    ∃ w, compileTokens s = some w := by
  cases h
  · exact ⟨_, deploy_compiles_correctly⟩
  · exact ⟨_, scale_compiles_correctly⟩
  · exact ⟨_, revoke_compiles_correctly⟩

end Foundations.CNL
