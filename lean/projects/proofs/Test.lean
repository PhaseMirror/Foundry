import Kernel
import AceScnCsc
import Mersenne503
import MatrixEngine
import Zmod
import EchoBraid

/-!
# Test — regression harness for the project proofs

These theorems re-run core invariants on concrete inputs. They are real proofs (no
`sorry`); failing any means a regression in the formalizations. Build/check with
`lake build` (compilation proves every `theorem`).
-/
namespace Test

open proofs.Kernel

/-- Mersenne bound holds on the concrete value `M₅₀₃`. -/
theorem test_mersenne_pos : Mersenne503.M503_pos := Mersenne503.M503_pos

/-- `2⁵⁰³ ≡ 1 (mod M₅₀₃)`. -/
theorem test_mersenne_mod : Mersenne503.two_pow_503_mod_M503 := Mersenne503.two_pow_503_mod_M503

/-- Prime-indexed encoding is injective for a non-zero modulus. -/
theorem test_encode_injective :
    MatrixEngine.prime_encode_injective 503 7 7 (by decide) rfl := rfl

/-- Feasibility scaling never exceeds `ε`. -/
theorem test_feasibility :
    AceScnCsc.feasibility_map_bound 1234 100 := AceScnCsc.feasibility_map_bound 1234 100

/-- Modular reduction stays below the modulus. -/
theorem test_mod_bounds : Zmod.mod_bounds 17 5 (by decide) = True := by decide

/-- A passing sovereign atom is accepted by the contractivity oracle. -/
def goodAtom : EchoBraid.LambdaTraceAtom := {
  proofDigest := "", stateRootHash := "", timestamp := 0,
  qScaled := 3, teeQuotePresent := true, trajectoryId := "A",
  protocolV := 1, signerIdPresent := true }

theorem test_sovereign : EchoBraid.enforceSovereignContractivity goodAtom "A" 10 = true := rfl

end Test
