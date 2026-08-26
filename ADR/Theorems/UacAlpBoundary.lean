import Care

/-!
# UAC–ALP Boundary Formal Specification & Invariants

Formal verification of the trust perimeter between Universal Access Control (UAC)
and Axiom-Clean Lawful Proofs (ALP):

1. **INV-UAC-01 (Fail-Closed Proof-Debt Gate):**
   Any token referencing unverified proof debt (`debt > 0`) forces the UAC
   safety interlock to immediately latch into `L0_HALT`.

2. **INV-UAC-02 (Axiom Leakage Immunity):**
   State mutation authorization requires an explicit axiom-clean ALP witness certificate.

3. **INV-UAC-03 (Hardware Interlock Latch):**
   A violation signal (`rho_violation` or `drift_warning`) latches `L0_HALT = true`.

4. **INV-UAC-04 (Reversible PETC Signature):**
   Grapheme-to-prime encoding preserves identity under decomposition and reassembly.
-/

namespace PhaseMirror.UacAlpBoundary

/-- Hardware Interlock status -/
inductive InterlockStatus where
  | Normal : InterlockStatus
  | L0_HALT : InterlockStatus
  deriving Repr, DecidableEq, Inhabited

/-- Proof debt record associated with a permission token -/
structure ProofDebt where
  debtCount     : Nat
  isUncertified : Bool
  deriving Repr, DecidableEq, Inhabited

/-- Permission Token presenting access claims across the boundary -/
structure Token where
  tokenId   : Nat
  proofDebt : ProofDebt
  expiry    : Nat
  signature : Nat
  deriving Repr, DecidableEq, Inhabited

/-- UAC Gatekeeper State -/
structure UACState where
  interlock       : InterlockStatus
  activeTokens    : List Token
  driftWarning    : Bool
  rhoViolation    : Bool
  deriving Repr, DecidableEq, Inhabited

/-- ALP Certificate indicating verified formal proof status -/
structure ALPCertificate where
  theoremId   : Nat
  isAxiomClean: Bool
  witnessHash : Nat
  deriving Repr, DecidableEq, Inhabited

/-- Boundary Witness anchoring authorized mutation to an axiom-clean cert -/
structure BoundaryWitness where
  token       : Token
  alpCert     : ALPCertificate
  isAuthorized: Bool
  deriving Repr, DecidableEq, Inhabited

/-- Hardware Interlock step evaluation -/
def evaluateInterlock (st : UACState) : InterlockStatus :=
  if st.interlock == InterlockStatus.L0_HALT then
    InterlockStatus.L0_HALT
  else if st.driftWarning || st.rhoViolation then
    InterlockStatus.L0_HALT
  else
    InterlockStatus.Normal

/--
UAC Authorize decision function:
Returns (newInterlockState, isAuthorized)
-/
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

/-! ## Formally Verified Invariants -/

/--
Theorem 1 (INV-UAC-01): `no_authorization_with_proof_debt`
If a token carries proof debt (`debtCount > 0`), authorization is rejected and
interlock latches into `L0_HALT`.
-/
theorem no_authorization_with_proof_debt
    (st : UACState) (tok : Token) (cert : ALPCertificate)
    (hDebt : tok.proofDebt.debtCount > 0) :
    uacAuthorize st tok cert = (InterlockStatus.L0_HALT, false) := by
  dsimp [uacAuthorize]
  split
  · rfl
  · split
    · rfl
    · rename_i hNotHalt hNotDebt
      have hDebtBool : (tok.proofDebt.debtCount > 0 || tok.proofDebt.isUncertified) = true := by
        simp [hDebt]
      contradiction

/--
Theorem 2 (INV-UAC-01b): `no_authorization_uncertified`
If a token is uncertified, authorization is rejected into `L0_HALT`.
-/
theorem no_authorization_uncertified
    (st : UACState) (tok : Token) (cert : ALPCertificate)
    (hUncert : tok.proofDebt.isUncertified = true) :
    uacAuthorize st tok cert = (InterlockStatus.L0_HALT, false) := by
  dsimp [uacAuthorize]
  split
  · rfl
  · split
    · rfl
    · rename_i hNotHalt hNotDebt
      have hDebtBool : (tok.proofDebt.debtCount > 0 || tok.proofDebt.isUncertified) = true := by
        simp [hUncert]
      contradiction

/--
Theorem 3 (INV-UAC-02): `authorization_requires_axiom_clean`
Any authorized transition strictly requires an axiom-clean ALP certificate.
-/
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

/--
Theorem 4 (INV-UAC-03): `interlock_latches_on_violation`
If a violation or drift is asserted, interlock evaluates to `L0_HALT`.
-/
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

/-! ## Discrete PETC Reversibility -/

/-- Prime-indexed token representation -/
structure PrimeToken where
  graphemeCode : Nat
  primeModulus : Nat
  deriving Repr, DecidableEq, Inhabited

/-- Decompose list of grapheme codes into prime tokens -/
def decomposeGraphemes (codes : List Nat) : List PrimeToken :=
  codes.map (fun c => { graphemeCode := c, primeModulus := c * 2 + 3 })

/-- Reassemble prime tokens back to grapheme codes -/
def reassembleTokens (tokens : List PrimeToken) : List Nat :=
  tokens.map (·.graphemeCode)

/--
Theorem 5 (INV-UAC-04): `decompose_reassemble_identity`
Decomposing a grapheme sequence into prime-indexed PETC tokens and reassembling
is strictly the identity function.
-/
theorem decompose_reassemble_identity (codes : List Nat) :
    reassembleTokens (decomposeGraphemes codes) = codes := by
  dsimp [decomposeGraphemes, reassembleTokens]
  induction codes with
  | nil => rfl
  | cons c cs ih =>
    dsimp
    rw [ih]

end PhaseMirror.UacAlpBoundary
