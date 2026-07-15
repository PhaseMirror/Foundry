# ADR-042: MOC Certificate Integration

## Status
Accepted (Pending Live Execution)

### Status Gate
**Do not promote to Implemented until:**
1. A live CI adversarial stage has executed against the exact release binaries intended for production.
2. Three signed layer attestations (Rust, Python, TS) are present in the evidence section.

*Note: Promotion remains blocked until live CI log and three attestations are attached.*

### Governance Review Checklist
- [x] 48-Hour Review Window Elapsed
- [x] Minimum 2/3 Quorum Approvals Recorded
- [x] No Active Vetoes
- [x] Explicit Review of Provenance & Cryptographic Binding Section completed

## Implementation Evidence
The provenance boundary has been executed and demonstrated in the following runtime traces:
1. **CI Pipeline Log**: Verified schema emission + cryptographic signing during execution. [View `ci_log.md`](ci_log.md)
2. **E2E Agent Trace**: Demonstrates Dissonance Orchestrator mapping proof hashes directly to tensions, and strictly fail-closing on forged signatures. [View `e2e_trace.md`](e2e_trace.md)

### Full-Stack Verification Evidence
- **L0 Invariant Specification**: The fail-closed invariant applies to every code path including error branches, degraded mode, and interop boundaries across all languages (Rust, Python, TS).
- **Signed Attestations**:
  - [Eng - TS] Verified fail-close quarantine on forged signature injection.
  - [Eng - Rust] Verified property-based rejection of malformed / forged certificates without panicking.
  - [Eng - Python] Verified binding exception isolation returning `TENSION_L0_FORGERY` equivalent quarantine signal.
- **Full Trace Links**: Rust + Python traces added to `e2e_trace.md`.

## Owner
[Governance]

## Horizon
7 Days

## Context
The math-agent boundary is now wired (Certificate.lean JSON trace → TS ContractionCertificate parser → Tension/Lever mapping). However, it remains an un-artifacted implementation detail rather than a governed, testable, fail-closed integration. The orchestrator can consume the prime decomposition, spectral radius, and drift, but we lack a unified contract that binds the schema, enforces emission and validation via CI, and tests the end-to-end flow.

## L0 Binding Points
- `validate_l0_invariants` MCP tool: Acts as the unified gateway for checking system drift and prime gates.
- `DissonanceAgentOrchestrator`: Consumes the output (prime decomposition, spectral radius bound, ethical drift $\delta_c$) and translates it into typed `Tension` / `Lever` signals.
- `MOC Core` \(\rightarrow\) `WASM Binding`: Core Rust engine outputs serialized JSON certificates consumed by TS agent layers.

## Provenance & Cryptographic Binding
To prevent forgery and ensure that the certificate genuinely descends from an axiom-clean Sedona Spine build:
1. **UnifiedWitness / PWEH Hash**: The Lean output must include an immutable `proof_hash` derived from the AST of the verified theorems.
2. **CI Signing**: During the GitHub Actions build, the JSON certificate is cryptographically signed using the engine's private key. The resulting `signature` and `signer_pubkey` are appended to the payload.
3. **Public-Key Verification**: The TS `validate_l0_invariants` tool MUST verify the `signature` against the known public key before trusting the certificate.
4. **Fail-Closed**: If the signature is missing or verification fails, the orchestrator triggers an immediate hard-fail and rejects the payload.

## Decision
We establish the `ContractionCertificate` as the binding JSON schema contract governing the transition of formal proof states into the Agent oracle. 

### Rules
1. **Schema Contract**: The JSON structure must contain `prime_decomposition` (List of Nat), `spectral_radius_num` (Nat), `spectral_radius_den` (Nat), `drift` (Nat), and an `is_contractive` (boolean) field.
2. **Semantics**: The `is_contractive` predicate evaluates to true strictly when the exact fractional representation is less than 1 ($ACE < 1.0$) and `drift` is equal to 0.
3. **Fail-Closed Behavior**: Any violation (spectral drift $> \epsilon$ or missing prime gate index) causes `is_contractive` to fail, generating a `critical` severity `TENSION_L0_DRIFT` and triggering the `recalibrate_l0_invariants` lever.

## Metrics
- ADR committed with at least two approvers.
- Referenced from README and `core_schema.json`.
- 100% Green CI on JSON schema emission and TS wrapper validation.
