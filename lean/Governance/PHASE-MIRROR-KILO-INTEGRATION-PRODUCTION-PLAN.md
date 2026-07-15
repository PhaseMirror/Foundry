# Phase Mirror MCP ↔ Kilo CLI Integration Plan (Production-Grade)

## ⚠️ CRITICAL: Sedona Spine FFI Guard Required

**Current Design Flaw**: The MCP server does NOT evaluate `λ_p L_p < 1.0` and witness integrity before JSON serialization. Policy evaluation occurs AFTER results leave the engine via `process_request` in `lib.rs:63-372`.

**Required Fix**: All MCP entry points must use `try_` wrapper pattern that evaluates Sedona Spine predicates FIRST, returning `Err` on violation before any outbound serialization.

---

## Executive Summary

Integrate `phase-mirror-mcp` with Kilo CLI via dual transport methods:
1. **MCP Server Mode**: Kilo spawns `phase-mirror-mcp` as subprocess, communicates via stdio JSON-RPC
2. **Sedona Spine Guard**: Every tool call evaluates `λ_p L_p < 1.0` and witness integrity BEFORE JSON result

---

## Phase Mirror MCP Server Capabilities

### Available Tools (phase-mirror-mcp)
| Tool | Description | Governance Mode |
|------|-------------|-----------------|
| `verify_ledger` | L0 invariant verification | Authoritative |
| `evaluate_esi_risk` | Spoliation risk + retention | Advisory/Authoritative |
| `check_governed_bridge` | 5-gate verification harness | Authoritative |
| `scan_litigation_hold` | Active litigation detection | - |
| `scan_spoliation_risk` | Risk violation scanning | - |
| `get_stability_metric` | Stability witness (q-score) | - |
| `attest_cross_domain_mission` | Clinical cross-domain attestation | - |
| `health_check` | Agent health status | - |
| `sovereign_posture` | Global posture/dissonance | - |
| `run_command` | Sandboxed command execution | - |
| `get_metrics` | Live system metrics | - |

### Transport Options
- **stdio** (default): JSON-RPC 2.0 over stdin/stdout
- **WebSocket** (`--ws` flag): AXUM-based WS server on port 3001

---

## Integration Architecture (Option A: In-Process Library Call)

```
┌─────────────┐    JSON-RPC    ┌─────────────────────────────────────┐
│  Kilo CLI   │◄─────────────►│ phase-mirror-mcp (single binary)    │
│   (C)       │   (stdio)      │  - MCP protocol handler           │
└─────────────┘                │  - Links against phase-mirror-gpt   │
                               │  - Calls McpTransportWrapper API    │
                               └─────────────────────────────────────┘
                                          │  (in-process, no serde)
                                          ▼
                               ┌────────────────────────┐
                               │ phase-mirror-gpt (lib) │
                               │ - InvariantConsistencyOracle
                               │ - ContractivityReceipt   │
                               └────────────────────────┘
```

**Key Decision**: MCP links against `phase-mirror-gpt` as a library crate (Cargo.toml line 7), eliminating the JSON serialization boundary. `try_` wrappers call `McpTransportWrapper::handle_mcp_call()` directly in-memory.

---

## Implementation Steps

### Phase 0: Repository Setup
- Fork `antirez/kilo` → `multiplicity/kilo-phase-mirror`
- Create integration branch in `multiplicity/phase-mirror-kilo-integration`

### Phase 1: MCP Client Library (pm_mcp_client.c)
```c
// pm_mcp_client.h
typedef struct {
    pid_t child_pid;
    int stdin_fd;
    int stdout_fd;
    char *binary_path;
    int request_id;
} PmMcpClient;

PmMcpClient* pm_mcp_client_new(const char *binary_path);
int pm_mcp_initialize(PmMcpClient *client);
char* pm_mcp_call_tool(PmMcpClient *client, const char *tool_name, const char *json_args);
void pm_mcp_client_free(PmMcpClient *client);
```

**Key features:**
- Uses `posix_spawn()` for subprocess management
- JSON-RPC request/response serialization (cJSON)
- Async read/write with `select()` for timeout handling
- Connection pooling for performance

### Phase 2: Configuration Layer
Config file: `~/.config/kilo/phase-mirror.yaml`
```yaml
mcp_binary: ${HOME}/.local/bin/phase-mirror-mcp
gpt_binary: ${HOME}/.local/bin/phase-mirror-gpt
mcp_transport: stdio  # or "ws" for WebSocket mode
ws_endpoint: ws://localhost:3001
enable_ai: true
enable_governance: true
timeout_ms: 5000
log_path: ${XDG_STATE_HOME}/kilo/pm_audit.log
```

Environment variable overrides:
- `PHASE_MIRROR_MCP_BINARY`
- `PHASE_MIRROR_GPT_BINARY`
- `PHASE_MIRROR_MCP_ENDPOINT`

### Phase 3: Kilo Command Extensions

New editor commands (triggered via `:` prompt or `Ctrl-A`):
```
:ai <prompt>           - Call phase-mirror-gpt for code generation
:review                - Run verify_ledger on current file
:esi-risk              - Evaluate ESI risk of file changes
:bridge-check          - Validate governed bridge transition
:health                - Check MCP server health status
:posture               - Show sovereign posture metrics
:metrics               - Display system governance metrics
:run <cmd>             - Execute sandboxed command via MCP
```

### Phase 4: Governance Command Flow

```
1. User triggers :review in Kilo
2. Kilo reads buffer content
3. PmMcpClient sends: {"method": "tools/call", "params": {"name": "verify_ledger", ...}}
4. MCP validates against mcp-contract.json policy
5. Tool executes, result includes governance verdict
6. Kilo displays result in status bar or split window
```

### Phase 5: Contract Validation Handler

Before inserting AI-generated content:
1. Extract `result.content[].text` from MCP response
2. Verify `signature` field exists in response
3. Cross-check against `mcp-contract.json` schema
4. Validate `isError` flag
5. Only insert if `PERMITTED:` prefix present

---

## Security & Compliance (Sedona Spine)

### Zero-Drift
- All risk calculations remain in MCP/GPT binaries
- Kilo only forwards facts and displays verdicts

### Policy-Driven
- Tool policies in `tool_policies` section of contract
- Modes: `Advisory` (log only) vs `Authoritative` (enforce blocks)

### Audit Trail
- Each MCP call logged to `$XDG_STATE_HOME/kilo/pm_audit.log`
- Format: `{"timestamp": "...", "session": "...", "request": "...", "tool": "...", "verdict": "..."}`

### Contract Enforcement
- MCP validates all tool calls against `mcp-contract.json`
- Responses include governance messages (`PERMITTED:`, `BLOCK:`, etc.)
- Kilo UI reflects governance status in color coding

---

## Build & Deployment

### Cargo Workspace Integration
```toml
# Cargo.toml additions
[workspace]
members = [
    "Phase Mirror/phase-mirror-mcp",
    "Phase Mirror/phase-mirror-gpt",
]

[package.metadata.kilo]
mcp-server-bin = "target/release/phase-mirror-mcp"
gpt-engine-bin = "target/release/phase-mirror-gpt"
```

### Makefile Targets
```makefile
.PHONY: build-mcp build-gpt integrate
build-mcp:
	cargo build --release -p phase-mirror-mcp
build-gpt:
	cargo build --release -p phase-mirror-gpt
integrate:
	$(MAKE) build-mcp build-gpt
	cp target/release/phase-mirror-mcp $(PREFIX)/bin/
	cp target/release/phase-mirror-gpt $(PREFIX)/bin/
```

### CI/CD Pipeline (.github/workflows/ci.yml)
```yaml
steps:
  - actions/checkout@v4
  - name: Install Rust
    uses: dtolnay/rust-toolchain@master
    with: { toolchain: stable }
  - name: Build MCP Server
    run: cargo build --release -p phase-mirror-mcp
  - name: Build GPT Engine
    run: cargo build --release -p phase-mirror-gpt
  - name: Build Kilo
    run: make -C kilo
  - name: Run Tests
    run: |
      cargo test -p phase-mirror-mcp
      cargo test -p phase-mirror-gpt
      make -C kilo test
  - name: Lint
    run: |
      cargo clippy -- -D warnings
      clang-tidy kilo/*.c
```

---

## Error Handling & Resilience

| Error Type | Response |
|------------|----------|
| MCP binary not found | Display "Phase Mirror MCP not installed" and disable AI commands |
| Timeout (>5s) | Show "Governance check timed out, try again" |
| Contract violation | Display "BLOCKED: <reason>" in red status |
| L0 invariant failure | Show "UNSTABLE: Risk detected" with lever suggestions |
| Process spawn failure | Log to stderr, fail gracefully |

---

## Testing Strategy

### Unit Tests
- Mock MCP server returning fixed JSON responses
- Test JSON-RPC serialization round-trip
- Validate contract parsing

### Integration Tests
- Spawn real MCP server binary
- Verify `:review` command output format
- Assert audit log entries created

### Security Tests
- Tampered response detection
- Policy bypass attempts
- Sandbox escape prevention

---

## Sedona Spine FFI Guard Implementation

### Required: `try_` Wrapper Pattern for MCP Tools

**Current Tool Entry Points** (from `phase-mirror-mcp/src/tools/mod.rs`):
- `verify_ledger` - L0 invariant verification
- `evaluate_esi_risk` - ESI risk calculation  
- `check_governed_bridge` - 5-gate bridge validation
- `attest_cross_domain_mission` - Cross-domain attestation

**Required Guard Flow**:
```
JSON-RPC Request
      ↓
try_verify_ledger()  ←─┐
try_evaluate_esi_risk() │
try_check_governed_bridge() │ Sedona Spine Predicate
try_attest_cross_domain_mission() ── evaluates λ_p L_p < 1.0 first
      ↓
Err(L0 violation) → BLOCK: No JSON serialization
      ↓
Ok(result) → JSON-RPC Response with full witness
```

### Implementation: Sedona Spine Predicate Evaluator

Add to `phase-mirror-mcp/src/lib.rs`:

```rust
/// Sedona Spine Predicate Evaluator (ADR-028)
pub struct SedonaSpineEvaluator;

impl SedonaSpineEvaluator {
    /// Evaluates λ_p L_p < 1.0 constraint before any tool result
    pub fn evaluate_stop_rules(
        &self, 
        tool_name: &str, 
        result: &Value
    ) -> Result<Value, &'static str> {
        // 1. Extract witness if present
        let witness = result.get("witness")
            .ok_or("WITNESS_MISSING: No witness in result")?;
        
        // 2. Check λ_p L_p constraint
        let lambda_p = witness.get("lambda_p")
            .and_then(|v| v.as_f64())
            .ok_or("LAMBDA_MISSING: λ_p not found in witness")?;
        let L_p = witness.get("L_p")
            .and_then(|v| v.as_f64())
            .ok_or("L_P_MISSING: L_p not found in witness")?;
        
        if lambda_p * L_p >= 1.0 {
            return Err("L0_VIOLATION: λ_p L_p >= 1.0 - Scalar collapse detected");
        }
        
        // 3. Verify zero_spacings array integrity
        let zero_spacings = witness.get("zero_spacings")
            .and_then(|v| v.as_array())
            .ok_or("ZEROS_MISSING: zero_spacings not found")?;
        
        if zero_spacings.is_empty() {
            return Err("ZEROS_EMPTY: zero_spacings array cannot be empty");
        }
        
        // 4. Return result with preserved witness
        Ok(result.clone())
    }
}

/// Guard wrapper for verify_ledger tool
pub fn try_verify_ledger(req: VerifyLedgerRequest) -> Result<VerifyLedgerResponse, String> {
    let raw_result = verify_ledger_integrity(req.clone());
    
    // Convert to JSON for witness evaluation
    let result_json = serde_json::to_value(&raw_result)
        .map_err(|e| format!("SERIALIZATION_ERROR: {}", e))?;
    
    // Apply Sedona Spine predicate
    SedonaSpineEvaluator.evaluate_stop_rules("verify_ledger", &result_json)
        .map(|v| serde_json::from_value(v).unwrap())
        .map_err(|e| e.to_string())
}
```

---

## Levers & Metrics

| Role | Owner | Metric | Horizon |
|------|-------|--------|---------|
| MCP Integration Lead | Implement `try_` wrappers on 4 core tools evaluating λ_p L_p < 1.0 first | 100% of MCP entry points produce signed Lambda-Trace atom with unaltered zero_spacings array | 7 days |
| Governance | Audit ADR-001 with dedicated MCP section, L0 guard clauses, classification matrix | CI dual-gate blocks merge on any MCP binary that bypasses Rust engine | 14 days |
| DevOps | Link phase-mirror-mcp binary against Rust engine; declare explicit dependency and audit-log mount | P99 tool-call latency <300 ms under load | 21 days |

---

## ADR-001 Update Required

Append MCP Integration Section to `ADR-001-Production-Installation.md`:

```markdown
### MCP FFI Integration Layer

1. All MCP tool calls MUST use `try_` wrapper pattern before JSON serialization.
2. Every response MUST include a signed Lambda-Trace atom containing:
   - `lambda_p`: Spectral radius (num/den)
   - `L_p`: Drift magnitude
   - `zero_spacings`: Array of spectral gap measurements (unaltered)
   - `witness_id`: Unique identifier for the witness
3. Any tool returning `λ_p L_p >= 1.0` MUST return Err(L0_VIOLATION) and BLOCK.
4. The Kilo CLI integration MUST validate witness presence before displaying results.
```

---

## CI Dual-Gate: `sedona_spine_ci.yml`

```yaml
name: Sedona Spine CI Validation
on: [push, pull_request]

jobs:
  sedona_spine_gate:
    steps:
      - name: Run MCP try_ wrappers
        run: |
          # Verify all try_ functions exist
          grep -q "try_verify_ledger" phase-mirror-mcp/src/lib.rs
          grep -q "try_evaluate_esi_risk" phase-mirror-mcp/src/lib.rs
          grep -q "try_check_governed_bridge" phase-mirror-mcp/src/lib.rs
          
      - name: Assert receipt + full witness
        run: |
          cargo test --package phase-mirror-mcp -- sedona_spine_witness_test
          
      - name: Block on L0 violation
        run: |
          # Fail if any tool can return without witness
          ! grep -P "Ok\(.*result.*\)" phase-mirror-mcp/src/lib.rs | grep -v "try_"
```

---

## flatpak Manifest: `com.citizengardens.agiOS.yaml`

```yaml
- name: phase-mirror-mcp
  buildsystem: simple
  build-commands:
    - cargo build --release --manifest-path "Phase Mirror/phase-mirror-mcp/Cargo.toml"
    - install -D target/release/phase-mirror-mcp /app/bin/pm-mcp
  # No process-spawn needed - engine linked in-process via phase-mirror-gpt dependency
  # Audit volume mount for Lambda-Proof / Archivum storage at /var/lib/pm/audit
```

---

### Receipt Validation Code (In-Process)

The `try_` wrapper validates `ContractivityReceipt` structs in Rust memory:

```rust
pub fn try_verify_ledger(req: VerifyLedgerRequest) -> Result<McpCallToolResult, String> {
    // 1. Call engine in-process (no serde boundary)
    let receipt = phase_mirror_gpt::transport::validate_l0_invariants(req)?;
    
    // 2. Evaluate Sedona Spine stop rules on receipt
    SedonaSpineEvaluator.evaluate_stop_rules(&receipt.witness)?;
    
    // 3. Return MCP-compliant result only after validation
    Ok(McpCallToolResult {
        content: vec![McpContent {
            r#type: "text".to_string(),
            text: serde_json::to_string_pretty(&receipt)?,
        }],
        is_error: false,
    })
}
```

---

### CI Headless Test Harness Contract

For `try_get_stability_metric` (mapped from `get_stability_metric`):

```rust
// Failure contract for try_ wrappers
pub fn try_get_stability_metric() -> Result<McpCallToolResult, String> {
    // 1. Call engine in-process
    let receipt = phase_mirror_gpt::transport::get_stability_metric()?;
    
    // 2. Evaluate witness (status check)
    let witness = receipt.witness.ok_or("WITNESS_MISSING")?;
    
    // 3. Check λ_p L_p constraint
    let lambda_p = witness.lambda_p;
    let L_p = witness.L_p;
    
    if lambda_p * L_p >= 1.0 {
        return Err(format!("L0_VIOLATION: λ_p L_p = {} - Scalar collapse", lambda_p * L_p));
    }
    
    // 4. Check zero_spacings intact
    if witness.zero_spacings.is_empty() {
        return Err("L0_VIOLATION: zero_spacings array truncated".to_string());
    }
    
    Ok(McpCallToolResult { /* ... */ })
}
```

**CI Test Execution**:
```bash
# Spawn MCP binary, send tool request, verify:
# - Exit code 0 (no panic)
# - No tool-result JSON on stdout when error
# - Error response JSON emitted to stderr with code -32001
echo '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"get_stability_metric"},"id":1}' | \
  ./target/release/phase-mirror-mcp 2>&1 | \
  grep -q '"code":-32001' && echo "PASS: Error correctly returned"
```

---

### SUCCESS Response Schema (Lambda-Trace Atom)

When `try_*` returns `Ok()`:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [{
      "type": "text", 
      "text": "{\"status\":\"OK\",\"witness_id\":\"sha256:abc123\",\"lambda_trace\":{\"lambda_p\":0.999999,\"L_p\":0.95,\"zero_spacings\":[0.9549652277648129,1.5563111057990717,...],\"signature\":\"SIGNED_HASH\",\"signer_pubkey\":\"ed25519:...\","proof_hash":"LEAN_PROOF_HASH_108_CORE"}}"
    }],
    "isError": false
  }
}
```

1. **Full Lambda-Trace atom in `result.content[].text`** — includes witness, signature, zero-spacings
2. **`zero_spacings` field** under `"lambda_trace"` object  
3. **CI positive test asserts:** witness array present + signature marker matches `"SIGNED_HASH"` and `proof_hash` matches `"LEAN_PROOF_HASH_108_CORE"` (stub validation; full ed25519 verification pending engine key rotation)

---

## Acceptance Criteria (Sedona Spine Required)

- [ ] All 4 core MCP tools wrapped with `try_` predicate evaluator (verify_ledger, evaluate_esi_risk, check_governed_bridge, attest_cross_domain_mission)
- [ ] All dynamic tools wrapped with `try_` predicate evaluator (get_stability_metric, get_metrics)
- [ ] `λ_p L_p < 1.0` enforced before JSON serialization in all `try_` wrappers
- [ ] Every MCP response contains signed Lambda-Trace atom with `zero_spacings`
- [ ] CI dual-gate prevents merge of unguarded MCP entry points
- [ ] ADR-001 updated with MCP FFI section and L0 guard clauses
- [ ] `./validate-witness.sh` asserts witness integrity on all tool outputs
- [ ] Headless harness confirms MCP binary exits cleanly (no panic) on receipt violation
- [ ] Headless harness confirms no tool-result JSON on stdout when error occurs
- [ ] Headed harness confirms Lambda-Trace atom with `zero_spacings` and valid signature on success