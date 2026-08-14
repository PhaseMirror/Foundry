structure PwehReceipt where
  s_integrity : String
  last_prime_move : Nat
  policy_root_hash : String
  crmf_certificate : String
  lambda_m_resonance_score : Float

def isValidHash (s : String) : Bool :=
  s.length == 64 && s.toList.all (fun c => c ∈ ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'])

def isValidResonanceScore (r : Float) : Bool :=
  0.0 ≤ r && r ≤ 1.0

def validateReceipt (r : PwehReceipt) : Bool :=
  isValidHash r.s_integrity &&
  isValidHash r.policy_root_hash &&
  isValidHash r.crmf_certificate &&
  isValidResonanceScore r.lambda_m_resonance_score

theorem receipt_validation_soundness (r : PwehReceipt) :
  validateReceipt r = true → 
  (isValidHash r.s_integrity = true ∧ isValidHash r.policy_root_hash = true ∧ 
   isValidHash r.crmf_certificate = true ∧ isValidResonanceScore r.lambda_m_resonance_score = true) := by
  intro h; simp [validateReceipt] at h; exact ⟨h.1.1.1, h.1.1.2, h.1.2, h.2⟩
