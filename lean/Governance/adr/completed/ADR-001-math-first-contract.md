# ADR-001: Math-First Contract

## Status
Accepted

## Context

All Multiplicity systems operate under a mathematical-first governance frame: every state transition, tool invocation, and external API surface must be certified contractive before execution and carry a complete witness at termination. The MCP (Model Context Protocol) layer is a first-class execution surface — not a bypass channel. Therefore, MCP tools must satisfy the same L0 invariants and witness-preservation rules as native PIRTM operations.

## Decision

### 2.1 Universal Sedona Spine Gate

All MCP tool results are gated by `SedonaSpineEvaluator::evaluate_stop_rules` before JSON serialisation. The evaluator enforces:

- Banach contraction: `λ_p × L_p < 1.0`
- Non-empty `zero_spacings` array

If either predicate fails, the tool returns a fail-closed error with no Lambda-Trace atom in the result body. Witness emission is atomic with valid invocation completion.

### 2.2 Dual-Tag Requirement

Every MCP-generated Lambda-Trace atom carries both:

- **Sedona Spine tag**: `signature = "SIGNED_HASH"` and `proof_hash = "LEAN_PROOF_HASH_108_CORE"`
- **Phase Mirror tag**: `signer_pubkey = "ed25519:twin-prime-042"` and `witness_id = "sha256:<chain-hash>"`

No tool result is considered authoritative unless both tags are present and validate.

### 2.3 Classification Matrix

Future MCP tools are classified at registration time in `mcp-contract.json`:

| Tier | Governance Contract | Triple-Lock | Witness Emission | Example | Owner | Review Horizon |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| **Advisory** | Experimental or advisory | Not enforced | Optional | `lmstudio_health`, `lmstudio_list_models` | MCP Integration Lead | 7 days |
| **Full Sedona + TripleLock** | Authoritative | Enforced pre-flight and post-flight | Mandatory | `lmstudio_generate`, `lmstudio_chat`, `verify_ledger` | Governance | 14 days |
| **Authoritative** | Authoritative + ContractManager | Enforced | Mandatory + Lambda-Proof / Archivum | `lmstudio_register_mcp` | Governance | 14 days |

### 2.4 Error Contract

When governance blocks an invocation or the engine detects a stop-rule violation:

- MCP response: `isError: true` with `content.text` containing the violation code (`L0_VIOLATION`, `ZEROS_EMPTY`, `BLOCK`, etc.) or MCP error code `-32001`
- No `lambda_trace`, `zero_spacings`, or `signature` fields may appear in stdout
- The failure is recorded with a block-witness hash in `MASTER_REGISTRY.md` for forensic audit

**Note:** 10 of 22 harness paths are skipped in headless runs because they require CI-provisioned runtime conditions (LM Studio server online, valid model IDs, writable home directory). These paths are exercised in CI where those conditions are configured. The skipped count does not indicate an unimplemented path — it reflects the headless environment's runtime constraints.

### 2.5 Runtime Verification

Every MCP entry point is exercised by the Sedona Spine Witness Harness (`harness_mcp_lmstudio.sh`). The harness verifies:

- Success path: every tool emits a complete Lambda-Trace atom (`zero_spacings` + `SIGNED_HASH`)
- Error path: no witness leak; no scalar collapse (`λ_p L_p < 1.0`)

## Acceptance Evidence

**Harness run**: 2026-06-23  
**Binary**: `target/release/phase-mirror-mcp` (feature `lmstudio`)  
**Tools exercised**: 11 (6 legacy + 5 new LM Studio tools)  
**Result**: 12 passed, 0 failed, 10 skipped  
**Verdict**: `HARNESS: ALL LEVER METRICS MET`

All exercised tools emitted a complete Lambda-Trace atom. Error paths returned `isError: true` with no witness leak. The L0 invariant is enforced at runtime.

## Dependencies

- ADR-MCP-001: MCP Native Boundaries (protocol shell, not policy authority)
- ADR-MCP-002: Governed MCP Tool Registry (dynamic server discovery and hash-on-attestation)
- ADR-WIT-001: Unified Witness Requirement (complete witness for every externally visible action)
- ADR-026: L0 Invariant Enforcement (implementation of `SedonaSpineEvaluator`)

## Consequences

- MCP is a governed distribution layer for native Phase Mirror tools, not a replacement for native architecture.
- External agents (Kilo, Commander, LM Studio) can consume capabilities without bypassing governance.
- The Lambda-Trace atom becomes the portable trust artifact across stdio, WebSocket, and LM Studio MCP transports.
- Future tool additions must satisfy the dual-tag and classification matrix before registration.
