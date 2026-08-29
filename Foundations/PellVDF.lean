class VDFGroup (G : Type) where
  mul : G → G → G
  pow : G → Nat → G
  pow_add : ∀ g a b, pow g (a + b) = mul (pow g a) (pow g b)
  pow_mul : ∀ g a b, pow g (a * b) = pow (pow g a) b

theorem weso_proof_sound {G : Type} [VDFGroup G] (g output π : G) (l r T q : Nat)
  (h_pi : π = VDFGroup.pow g q)
  (h_div : 2^T = q * l + r)
  (h_verif : VDFGroup.mul (VDFGroup.pow π l) (VDFGroup.pow g r) = output) :
  output = VDFGroup.pow g (2^T) := by
  rw [← h_verif]
  rw [h_pi]
  rw [← VDFGroup.pow_mul]
  rw [← VDFGroup.pow_add]
  rw [← h_div]
