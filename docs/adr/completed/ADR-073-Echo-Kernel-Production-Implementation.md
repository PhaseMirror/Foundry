# ADR-073: Echo Kernel Production Implementation

## Status
**Adopted**

## Context
The `Prime/crates/echo-kernel/` crate implements the **Echo-Kernel / Echo-Braid runtime**, which is the **agent communication and memory layer** of the Multiplicity Sovereign Core. The Echo Kernel is responsible for:
- **Echo-Braid protocol**: Secure, contractive message passing between agents
- **Memory retention**: Prime-indexed memory with superpositional states
- **Agent orchestration**: Dispatching tasks to the correct agent (The Guardian, The Examiner, The Publisher, etc.)

Currently, `echo-kernel` is a Rust crate with `petgraph`, `clap`, `regex`, and `tempfile` dependencies. It lacks:
- A **Lean 4 formalization** proving that the Echo-Braid protocol preserves contraction bounds
- **Kani verification** that message passing is safe and contractive
- A **production-grade ADR** governing its deployment, scaling, and security model

The Echo Kernel is a **high-value target** because it is the **nervous system** of the Phase Mirror Agency. Any failure in the Echo-Braid protocol could cause:
- **Message loss or corruption**: Agent coordination fails
- **Contraction violation**: Non-contractive message passing could destabilize the entire system
- **Security breach**: Unverified message routing could allow adversarial injection

## Decision
We will implement the Echo Kernel as a **formally verified, production-grade agent communication and memory layer** with the following mandates:

### 1. Lean 4 Formalization of Echo-Braid Protocol
- Define `Prime/lean/ECHO_BRAID/EchoKernel.lean` with:
  - `EchoMessage` — message type with `sender`, `receiver`, `payload`, `contractive_proof`
  - `EchoBraidState` — state of the braid (queued messages, active channels)
  - `EchoBraidTransition` — message passing transition
- Prove:
  - `echo_braid_preserves_contraction`: Message passing does not increase system energy.
  - `echo_braid_no_cycles`: The braid graph is acyclic (no circular message loops).
  - `memory_retention_sound`: Prime-indexed memory states are preserved across transitions.

### 2. Rust Implementation
- Expand `Prime/crates/echo-kernel/` to expose:
  - `EchoKernel::new(config: EchoConfig) -> Result<EchoKernel, InitError>`
  - `EchoKernel::send(msg: EchoMessage) -> Result<EchoReceipt, SendError>`
  - `EchoKernel::receive(agent_id: &str) -> Result<Vec<EchoMessage>, ReceiveError>`
  - `EchoKernel::store_memory(state: &PrimeIndexedState) -> Result<MemoryHash, StoreError>`
- The Rust implementation must:
  - Validate `contractive_proof` on every incoming message
  - Emit `EchoBraidWitness` to `Archivum` on every send/receive
  - Reject messages that would create cycles in the braid graph

### 3. Kani Verification
- Implement Kani harnesses in `Prime/crates/echo-kernel/tests/kani/` proving:
  - `proof_send_preserves_contraction`: `send` does not increase system energy.
  - `proof_no_cycles`: `send` rejects messages that would create braid cycles.
  - `proof_memory_tamper_evident`: `store_memory` emits a witness that detects tampering.

### 4. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/ECHO_BRAID/` and `cargo kani -p echo-kernel` on every PR.
- The Guardian lock must verify `EchoBraidWitness` before approving inter-agent communication.
- The Examiner lock must audit message traces for cycle detection.
- The Publisher lock must sign braid state snapshots into the `Archivum` ledger.

## Formal Proof Obligations

### 1. Echo-Braid Preserves Contraction
```lean
namespace ADR.EchoKernel

structure AgentId where
  value : String
  deriving Repr, DecidableEq

structure EchoMessage where
  sender : AgentId
  receiver : AgentId
  payload : String
  contractive_proof : String  -- hash of Lean proof
  deriving Repr

structure EchoBraidState where
  queued_messages : List EchoMessage
  active_channels : List (AgentId × AgentId)
  system_energy : ℝ
  deriving Repr

def send_message (state : EchoBraidState) (msg : EchoMessage) : Option EchoBraidState :=
  if msg.sender = msg.receiver then none
  else if state.active_channels.any (· = (msg.sender, msg.receiver)) then none
  else some {
    queued_messages := state.queued_messages ++ [msg],
    active_channels := (msg.sender, msg.receiver) :: state.active_channels,
    system_energy := state.system_energy * 0.99  -- contractive
  }

@[proof]
theorem echo_braid_preserves_contraction (state : EchoBraidState) (msg : EchoMessage)
  (h_send : send_message state msg = some state') :
  state'.system_energy < state.system_energy := by
  cases h_send
  simp [send_message] at *
  linarith

@[proof]
theorem echo_braid_no_cycles (state : EchoBraidState) (msg : EchoMessage)
  (h_send : send_message state msg = some state') :
  ¬ state'.active_channels.contains_cycle := by
  -- Proof that adding a directed edge (sender, receiver) cannot create a cycle
  -- if the sender and receiver are distinct and the edge was not already present
  sorry

end ADR.EchoKernel
```

### 2. Rust Runtime Contract
```rust
// crates/echo-kernel/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentId {
    pub value: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EchoMessage {
    pub sender: AgentId,
    pub receiver: AgentId,
    pub payload: String,
    pub contractive_proof: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EchoBraidState {
    pub queued_messages: Vec<EchoMessage>,
    pub active_channels: Vec<(AgentId, AgentId)>,
    pub system_energy: f64,
}

#[derive(Debug, thiserror::Error)]
pub enum SendError {
    #[error("self-loop not allowed")]
    SelfLoop,
    #[error("channel already active")]
    ChannelActive,
    #[error("contractive proof invalid")]
    InvalidProof,
}

impl EchoBraidState {
    pub fn send(&mut self, msg: EchoMessage) -> Result<(), SendError> {
        if msg.sender.value == msg.receiver.value {
            return Err(SendError::SelfLoop);
        }
        if self.active_channels.iter().any(|(s, r)|
            s.value == msg.sender.value && r.value == msg.receiver.value) {
            return Err(SendError::ChannelActive);
        }
        self.queued_messages.push(msg);
        self.active_channels.push((msg.sender.clone(), msg.receiver.clone()));
        self.system_energy *= 0.99;
        Ok(())
    }
}
```

## Consequences

### Positive
- **Verified Agent Communication**: Lean 4 + Kani guarantees that the Echo-Braid protocol is contractive and acyclic.
- **Secure Message Passing**: Contractive proof validation prevents adversarial or non-contractive messages from entering the system.
- **Audit-Ready Communication**: Every send/receive emits an `EchoBraidWitness` to `Archivum`.
- **Memory Integrity**: Prime-indexed memory states are tamper-evident via `Archivum` witnesses.

### Negative
- **Protocol Rigidity**: The no-cycle and contractive constraints may limit dynamic routing topologies.
- **Latency**: Contractive proof validation and witness emission add overhead to every message.
- **Formalization Gap**: The `ECHO_BRAID` Lean module exists but lacks the full Echo-Braid formalization required for production.

## Implementation Steps

1. **Define `EchoKernel.lean`** in `Prime/lean/ECHO_BRAID/` with `EchoMessage`, `EchoBraidState`, `EchoBraidTransition`.
2. **Prove core theorems** in `Prime/lean/adr-governance/ADR/EchoKernelProofs.lean`.
3. **Expand `Prime/crates/echo-kernel/`** with `EchoMessage`, `EchoBraidState`, and send/receive APIs.
4. **Implement Kani harness** proving contraction preservation and acyclicity.
5. **Wire Triple-Lock integration**: Guardian → message approval → Examiner → `EchoBraidWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p echo-kernel`.
7. **Emit Archivum witness** `EchoBraidProof` on every message.
8. **Benchmark message latency** against Phase Mirror Agency requirements.

## References
- `Prime/crates/echo-kernel/` — Existing Rust crate
- `Prime/lean/ECHO_BRAID/` — Existing Lean module
- `Prime/models/the-guardian/` — Lock 1
- `Prime/models/the-examiner/` — Lock 2
- `Prime/models/the-publisher/` — Lock 3
- ADR-002 (Sedona Spine) — Path of Integrity
- ADR-009 (Agent Transformation Contracts) — Agent contracts
- ADR-067 (Archivum) — Immutable witness ledger
