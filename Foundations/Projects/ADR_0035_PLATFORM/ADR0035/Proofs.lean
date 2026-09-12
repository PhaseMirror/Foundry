import ADR0035.Core
import ADR0035.LayerBGate

/-!
# ADR0035.Proofs

Formal Verification Theorems for ADR-0035 (Global Research Platform):
1. `missing_layer_b_forces_zero_tokens`: Minting is impossible without a Layer B tag.
2. `unratified_layer_b_forces_zero_tokens`: Minting is impossible with an unratified Layer B tag.
3. `local_verification_preserves_token_count`: Local verification does not increment tokens.
4. `local_witness_is_private_only`: Local verification produces private witnesses only.
5. `service_inactive_without_layer_b`: Public oracle cannot activate without Layer B.
6. `production_mode_lock_preserved`: FeMoco envelope (69 qudits) and mode lock remain invariant.
-/

namespace ADR0035

/--
Theorem 1: `missing_layer_b_forces_zero_tokens`
When Layer B tag is absent (`layerBTag = none`), any attempt to mint public MSC
tokens strictly evaluates to `none` (fail-closed halt).
-/
theorem missing_layer_b_forces_zero_tokens
    (st : PlatformState) (cert : MSCCertSchema)
    (hNone : st.layerBTag = none) :
    attemptPublicMint st cert = none := by
  dsimp [attemptPublicMint]
  rw [hNone]

/--
Theorem 2: `unratified_layer_b_forces_zero_tokens`
If a Layer B tag is present but fails ratification (`isLayerBRatified tag = false`),
public minting strictly evaluates to `none`.
-/
theorem unratified_layer_b_forces_zero_tokens
    (st : PlatformState) (tag : LayerBTag) (cert : MSCCertSchema)
    (hSome : st.layerBTag = some tag)
    (hUnratified : isLayerBRatified tag = false) :
    attemptPublicMint st cert = none := by
  dsimp [attemptPublicMint]
  rw [hSome]
  dsimp
  rw [hUnratified]
  rfl

/--
Theorem 3: `local_verification_preserves_token_count`
Running local verification (`verify_all.sh`) never increments the minted token count.
-/
theorem local_verification_preserves_token_count
    (st : PlatformState) (treeHash logsHash : String) :
    (localVerificationStep st treeHash logsHash).1.tokensMintedCount = st.tokensMintedCount := by
  dsimp [localVerificationStep]

/--
Theorem 4: `local_witness_is_private_only`
The witness produced by local verification is strictly marked `isPrivateOnly = true`.
-/
theorem local_witness_is_private_only
    (st : PlatformState) (treeHash logsHash : String) :
    (localVerificationStep st treeHash logsHash).2.isPrivateOnly = true := by
  dsimp [localVerificationStep]

/--
Theorem 5: `service_inactive_without_layer_b`
The public verification service cannot be activated without an established Layer B tag.
-/
theorem service_inactive_without_layer_b
    (st : PlatformState)
    (hNone : st.layerBTag = none) :
    (attemptActivateVerificationService st).isPublicVerificationActive = false := by
  dsimp [attemptActivateVerificationService]
  rw [hNone]

/--
Theorem 6: `production_mode_lock_preserved`
Local verification transitions preserve the FeMoco 69-qudit envelope.
-/
theorem production_mode_lock_preserved
    (st : PlatformState) (treeHash logsHash : String) :
    (localVerificationStep st treeHash logsHash).1.femocoQuditEnvelope = st.femocoQuditEnvelope := by
  dsimp [localVerificationStep]

end ADR0035
