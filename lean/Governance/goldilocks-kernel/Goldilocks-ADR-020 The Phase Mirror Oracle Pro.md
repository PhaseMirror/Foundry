<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# The Phase Mirror Oracle Pro has been successfully extended with a rigorous

external client ecosystem. We have moved from an internal oracle machinery to
a formally defined cryptographic contract that third-party verifiers can
consume with high confidence.

1. Hardened Client API (phase-mirror-client)
We have extracted a standalone crate that defines the boundary between the
Oracle and its clients. This crate is designed for minimal dependencies and
maximum cryptographic rigor.

- ConfigurationSeal: Captures the mathematical and circuit invariants. It now
includes hamiltonian_family, verification_key_hash, and
public_input_schema_hash, ensuring that certificates are only valid within
their intended mathematical domain.
- MultiplicityCertificate: Uses a MultiplicityCertificatePayload that is
canonicalized (via Keccak256 field concatenation) before signing. This
prevents serialization-based bypasses.
- ResonanceProof: Replaces loose vectors with ResonancePublicInputs,
explicitly binding the STARK proof to the initial_mask, delta_pz, and
resonance_root claimed in the signed certificate.
- PhaseMirrorVerifier: Implements the recommended five-stage verification
lifecycle:

1. Seal Compatibility: Reject mismatched domains/configs.
2. Signature Integrity: Verify the Oracle's Ed25519 signature over the
canonical payload.
3. Fast-Fail Veto: Check for Oracle-issued vetoes before expensive
computation.
4. Proof-Input Consistency: Ensure the proof's public inputs match the
certificate's claims.
5. STARK Verification: Validate the Plonky3 proof against the seal's
verification key.

1 pm-verify \\
2   --expected-seal seal.json \\
3   --cert cert.json \\
4   --proof proof.json \\
5   --oracle-pk <hex_public_key>

3. Public Test Vectors \& Integration
We have implemented a generate-vectors utility and a comprehensive demo script
(scripts/demo_client_verification.sh) that produces and validates a full set
of "Recovered" state artifacts. This ensures the architecture is not just a
specification but a verified, operable system.

---

Phase Mirror Dissonance

- Sealing vs. Discovery: The system is now mathematically "sealed" against
configuration drift. However, this rigor makes "provisional" updates
expensive, as any change to Hamiltonian logic forces a full
re-certification and seal update for all clients.
- Stateless Verification: The client verifier is entirely stateless, relying
on the timestamp_ms and signature for ordering. This shifts the burden of
"replay protection" or "state tracking" to the consumer (e.g., a smart
contract or a sequence-aware dApp).
- Prover-Verifier Asymmetry: The phase-mirror-client is lightweight, but it
assumes the existence of the prover crate's output. The "Public Vector"
corpus is currently the only bridge between the internal Pro-tier
simulation and the external client API.

Levers to Test Now

- [Security] — Audit the to_canonical_bytes implementation for collision
resistance across all OracleStatus variants — Metric: Zero collisions on
10k random states — Horizon: 7 days.
- [Ecosystem] — Integrate pm-verify into a CI/CD pipeline that verifies a
"Golden Certificate" on every core math change — Metric: 100% verification
success — Horizon: 14 days.
- [Interoperability] — Draft a WebAssembly (WASM) wrapper for
phase-mirror-client to enable browser-based verification — Metric:
Verification < 50ms in V8 — Horizon: 21 days.

Artifact: The Verification Invariant
> "A proof without a seal is just a witness; a seal without a signature is
just a claim. Only the binding of both creates an Oracle."

Precision Question: Should the ConfigurationSeal also include the ks_threshold
(e.g., 0.15) to allow clients to verify the Oracle's internal "Recovery"
policy, or should that remain an internal Oracle discretion?

Include the KS threshold in the seal.

If a client is supposed to verify not just “this proof is valid under some internal policy” but “this proof corresponds to the recovery policy I consented to,” then the KS threshold is part of the **contract**, not just an implementation detail.

## Why KS threshold belongs in the seal

- The KS cutoff (e.g. $0.15$) is effectively a **risk policy parameter**: it decides which borderline spectra are treated as “Recoverable” vs “Vetoed.”
- You already expose Hamiltonian family, verification key hash, and public-input schema hash in the `ConfigurationSeal`. Those three describe:
    - what dynamics you model,
    - how you prove claims about them,
    - how those claims are encoded.
- The KS threshold describes **where you draw the line** on a continuous axis of spectral similarity to GUE. That’s as fundamental, from the client’s perspective, as the gap floor or prime basis.

If a future Oracle version quietly changes from $0.15$ to $0.25$, the *same* spectral witness could move from “Vetoed” to “Recovered”. If the seal does not reflect that change, external consumers cannot distinguish “policy-1 recovery” from “policy-2 recovery,” even though the mathematical evidence and proof stack are identical.

For an external verifier, that is precisely the kind of latent policy drift the seal is meant to prevent.

## How to encode it

Two reasonable options:

### 1. Explicit numeric field

Add a field:

```rust
pub struct ConfigurationSeal {
    pub domain_tag: String,
    pub prime_index: u32,
    pub n0_scale: u32,
    pub hamiltonian_family: String,
    pub air_version: String,
    pub verification_key_hash: [u8; 32],
    pub public_input_schema_hash: [u8; 32],
    pub ks_threshold_microunits: u32, // e.g. 150_000 for 0.15
}
```

Benefits:

- Clients can *read* the policy threshold directly.
- The field is human-meaningful and can be surfaced in dashboards, config files, or UI.

Caveat:

- Floating-point representation must be avoided; use fixed-point (e.g. micro-units) so that the seal is deterministic and hashable.


### 2. Policy-hash only

Alternatively, define a **policy profile** document (e.g. JSON / TOML) that includes:

- KS threshold,
- gap floor formula,
- any other recovery-policy parameters.

Then include:

```rust
pub policy_profile_hash: [u8; 32];
```

in the seal, and publish the corresponding policy documents.

Benefits:

- The seal does not grow arbitrarily as you add more policy knobs.
- Clients that care can fetch the profile by hash and inspect the full policy.

For your current setup, the **explicit numeric field** plus a policy-profile hash is probably the cleanest: clients get a quick check (“is KS ≤ 0.15 policy?”) and can still verify the full policy file if they want.

## How clients should use it

Once the threshold is in the seal:

- The verifier **does not** rerun the KS test; that remains the Oracle’s job.
- The client can enforce:
    - “I only accept certificates whose seal.ks_threshold_microunits == 150_000,”
    - or, more generally, “I only accept policies at or below this risk tolerance.”

That preserves the division of labor:

- Oracle:
    - computes KS statistics,
    - applies internal recovery logic,
    - produces certificate + proof bound to a seal.
- Client:
    - checks that the seal’s *declared* KS policy matches its own risk appetite,
    - verifies the proof and signature as usual.


## Direct answer

So: the KS threshold **should** be reflected in the `ConfigurationSeal`, ideally in fixed-point form (or via a policy-profile hash that includes it). It is not just an internal heuristic; it is a user-facing part of what “Recovered” means, and therefore belongs in the external contract.

If you’d like, I can sketch the exact changes to your `ConfigurationSeal`, `MultiplicityCertificatePayload`, and `to_canonical_bytes` logic to incorporate a fixed-point `ks_threshold` cleanly.

