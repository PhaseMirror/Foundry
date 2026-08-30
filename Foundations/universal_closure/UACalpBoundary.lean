/-!
# Foundations.UacAlpBoundary.Core — UAC–ALP Boundary & Proof-Debt Interlock

Formalizes the trust perimeter between Universal Access Control (UAC) and Axiom-Clean Lawful Proofs (ALP):
1. INV-UAC-01: Fail-closed proof-debt interlock latching.
2. INV-UAC-02: State mutation authorization requires explicit axiom-clean ALP witness.
3. INV-UAC-03: Violation signal latches L0_HALT.
4. INV-UAC-04: Prime-indexed token decomposition and reassembly identity.
-/

namespace Foundations.UacAlpBoundary

/-- Hardware Interlock status. -/
inductive InterlockStatus where
  | Normal
  | L0_HALT
  deriving Repr, DecidableEq, Inhabited

/-- Proof debt record associated with a permission token. -/
structure ProofDebt where
  debtCount     : Nat
  isUncertified : Bool
  deriving Repr, DecidableEq, Inhabited

/-- Permission Token presenting access claims across the boundary. -/
structure Token where
  tokenId   : Nat
  proofDebt : ProofDebt
  expiry    : Nat
  signature : Nat
  deriving Repr, DecidableEq, Inhabited

/-- UAC Gatekeeper State. -/
structure UACState where
  interlock       : InterlockStatus
  activeTokens    : List Token
  driftWarning    : Bool
  rhoViolation    : Bool
  deriving Repr, DecidableEq, Inhabited

/-- ALP Certificate indicating verified formal proof status. -/
structure ALPCertificate where
  theoremId   : Nat
  isAxiomClean: Bool
  witnessHash : Nat
  deriving Repr, DecidableEq, Inhabited

/-- Hardware Interlock step evaluation. -/
def evaluateInterlock (st : UACState) : InterlockStatus :=
  if st.interlock == InterlockStatus.L0_HALT then
    InterlockStatus.L0_HALT
  else if st.driftWarning || st.rhoViolation then
    InterlockStatus.L0_HALT
  else
    InterlockStatus.Normal

/-- UAC Authorize decision function. -/
def uacAuthorize (st : UACState) (tok : Token) (cert : ALPCertificate) : InterlockStatus × Bool :=
  let nextInterlock := evaluateInterlock st
  if nextInterlock == InterlockStatus.L0_HALT then
    (InterlockStatus.L0_HALT, false)
  else if tok.proofDebt.debtCount > 0 || tok.proofDebt.isUncertified then
    (InterlockStatus.L0_HALT, false)
  else if !cert.isAxiomClean then
    (InterlockStatus.L0_HALT, false)
  else
    (InterlockStatus.Normal, true)

/-- Theorem 1 (INV-UAC-01): Any proof debt forces immediate L0_HALT latch. -/
theorem no_authorization_with_proof_debt
    (st : UACState) (tok : Token) (cert : ALPCertificate)
    (hDebt : tok.proofDebt.debtCount > 0) :
    uacAuthorize st tok cert = (InterlockStatus.L0_HALT, false) := by
  dsimp [uacAuthorize]
  split
  · rfl
  · split
    · rfl
    · rename_i _ hNotDebt
      have hDebtBool : (tok.proofDebt.debtCount > 0 || tok.proofDebt.isUncertified) = true := by
        simp [hDebt]
      contradiction

/-- Theorem 2 (INV-UAC-01b): Uncertified tokens force immediate L0_HALT latch. -/
theorem no_authorization_uncertified
    (st : UACState) (tok : Token) (cert : ALPCertificate)
    (hUncert : tok.proofDebt.isUncertified = true) :
    uacAuthorize st tok cert = (InterlockStatus.L0_HALT, false) := by
  dsimp [uacAuthorize]
  split
  · rfl
  · split
    · rfl
    · rename_i _ hNotDebt
      have hDebtBool : (tok.proofDebt.debtCount > 0 || tok.proofDebt.isUncertified) = true := by
        simp [hUncert]
      contradiction

/-- Theorem 3 (INV-UAC-02): State mutation authorization strictly requires axiom-clean certificate. -/
theorem authorization_requires_axiom_clean
    (st : UACState) (tok : Token) (cert : ALPCertificate)
    (hAuth : (uacAuthorize st tok cert).2 = true) :
    cert.isAxiomClean = true := by
  dsimp [uacAuthorize] at hAuth
  split at hAuth
  · contradiction
  · split at hAuth
    · contradiction
    · split at hAuth
      · contradiction
      · rename_i _ _ hClean
        cases hCleanBool : cert.isAxiomClean
        · simp [hCleanBool] at hClean
        · rfl

/-- Theorem 4 (INV-UAC-03): Violation signal strictly latches L0_HALT. -/
theorem interlock_latches_on_violation (st : UACState) (hVio : st.rhoViolation = true) :
    evaluateInterlock st = InterlockStatus.L0_HALT := by
  dsimp [evaluateInterlock]
  split
  · rfl
  · split
    · rfl
    · rename_i _ hNot
      have hOr : (st.driftWarning || st.rhoViolation) = true := by simp [hVio]
      contradiction

/-- Prime-indexed token representation. -/
structure PrimeToken where
  graphemeCode : Nat
  primeModulus : Nat
  deriving Repr, DecidableEq, Inhabited

/-- Decompose list of grapheme codes into prime tokens. -/
def decomposeGraphemes (codes : List Nat) : List PrimeToken :=
  codes.map (fun c => { graphemeCode := c, primeModulus := c * 2 + 3 })

/-- Reassemble prime tokens back to grapheme codes. -/
def reassembleTokens (tokens : List PrimeToken) : List Nat :=
  tokens.map (·.graphemeCode)

/-- Theorem 5 (INV-UAC-04): Grapheme decomposition and reassembly is strictly the identity. -/
theorem decompose_reassemble_identity (codes : List Nat) :
    reassembleTokens (decomposeGraphemes codes) = codes := by
  dsimp [reassembleTokens, decomposeGraphemes]
  rw [List.map_map]
  have hComp : ((fun (x : PrimeToken) => x.graphemeCode) ∘ (fun (c : Nat) => ({ graphemeCode := c, primeModulus := c * 2 + 3 } : PrimeToken))) = id := by
    funext x
    rfl
  rw [hComp]
  exact List.map_id codes

end Foundations.UacAlpBoundary
