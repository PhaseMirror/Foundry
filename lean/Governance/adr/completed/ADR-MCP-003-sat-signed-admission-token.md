# ADR-MCP-003: Signed Admission Token (SAT) — Issuance, Verification, and Key Management

**Status:** Accepted  
**Date:** 2026-05-22  
**Deciders:** commander-core, infra-config, MCP server layer

---

## Context

The SAT protocol (Step 5 of the ALP policy plane) requires a cryptographic token
issued by commander-core and verified by each MCP server before tool execution.
The token format is governed by `SignedAdmissionToken.schema.json`. This ADR
records the signature scheme decision and all lifecycle parameters required
before Rust issuance code is written.

---

## Decision

### Signature Scheme: Ed25519

- **Library (Rust):** `ed25519-dalek`
- **Library (Python):** `PyNaCl` (`nacl.signing.VerifyKey`)
- **Rationale:** Ed25519 makes commander-core the sole issuer by cryptographic
  constraint. Any party holding only the public key can verify but cannot issue.
  HMAC-SHA256 was rejected because symmetric keys allow any verifier to forge tokens.

### Token Lifecycle

| Parameter | Value | Enforcement |
|---|---|---|
| `sat_ttl_seconds` | 5 | Schema conditional in McpRegistry.schema.json |
| Single-use | true | Verifier maintains in-memory UUID replay cache, pruned at TTL expiry |
| Clock skew tolerance | ±2s | Verifier rejects if `now > expires_at + 2` |
| Replay cache TTL | 10s | 2× token TTL to absorb skew on both sides |

### Key Distribution

- commander-core holds the **private key** at runtime; never written to disk unencrypted.
- Each MCP server receives the **public key** at startup via environment variable
  `COMMANDER_SAT_PUBLIC_KEY` (hex-encoded 32-byte Ed25519 public key).
- Key rotation requires restarting all MCP servers with the new public key.
  Rotation cadence: **90 days or on compromise**, whichever is sooner.
- Rotation procedure must be documented in `docs/ops/sat-key-rotation.md`
  before any production deployment.

### Canonical Signing Payload

Signature is computed over the canonical JSON serialization of all SAT fields
**excluding** the `signature` field itself, with keys sorted lexicographically
and no insignificant whitespace.

**Constraints (canonical_json_constraints):**
- All schema field names **MUST** be ASCII-only. This ensures that Rust's `BTreeMap` (byte-wise UTF-8) and Python's `sort_keys=True` (Unicode codepoint) produce identical sorting outcomes.

---

## SAT Delivery Mechanism

To ensure portability across transports and adherence to standard JSON-RPC 2.0, the SAT will be delivered **In-band**:
1. The SAT is injected as a reserved field named `_sat` within the MCP `arguments` object of the `tools/call` request.
2. MCP servers requiring ALP admission **MUST** extract and verify the `_sat` field before processing any other arguments.
3. The `_sat` field **MUST** be stripped by the server middleware before passing the remaining arguments to the tool handler.

---

## Key Management

### Keypair Source
- **Private Key**: `commander-core` reads from `COMMANDER_SAT_PRIVATE_KEY` environment variable.
- **Public Key**: MCP servers read from `COMMANDER_SAT_PUBLIC_KEY` environment variable.

### Fail-Closed Behavior
- If `COMMANDER_SAT_PUBLIC_KEY` is absent at MCP server startup, the process **MUST** exit with a non-zero status. No soft-degradation is allowed.
- If a tool call arrives without a SAT, it is rejected with 403 Forbidden.

### Replay Cache Durability
- **Phase 3**: In-memory replay cache is accepted. Given the 5s TTL, the window for replay after a server restart is minimal.
- **Phase 4+**: Persistent replay cache (Redis or file-backed) will be evaluated if TTL requirements increase.

---

## Consequences

- commander-core gains a hard dependency on `ed25519-dalek`.
- Python MCP servers gain a hard dependency on `PyNaCl`.
- A key bootstrap procedure is required before integration tests can run.
- Token forgery requires private key compromise — lateral movement from a
  compromised MCP server cannot produce valid tokens.
- Key rotation is an operational event, not a code change. Document the runbook
  before go-live.

---

## Rejected Alternatives

| Option | Reason rejected |
|---|---|
| HMAC-SHA256 | Symmetric — any verifier can issue; no issuer constraint |
| JWT (RS256) | Larger dependency surface; RSA key sizes add friction in Rust |
| Opaque bearer token | No self-contained verifiability; requires central token store |
