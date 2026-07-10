# Phase 8 Roadmap: Multi-Agent Swarm Integration

With the core architecture locked in `1.0.0-alpha`, Phase 8 initiates the Swarm Matrix. The goal is to deploy independent, goal-driven agents that utilize the WASM Sigma Kernel and the CRDT Archivum ledger to coordinate distributed legal/governance tasks asynchronously.

| Step | Goal | Status |
| :-- | :-- | :-- |
| 1 | **Define Phase 8 goals** | DONE |
| 2 | **Agent Protocol Definitions (Swarm RPC)** | OPEN |
| 3 | **Distributed Consensus (Raft/Tendermint atop CRDT)** | OPEN |
| 4 | **Operator Swarm Dashboard (Leptos Extension)** | OPEN |
| 5 | **End-to-End Multi-Agent Simulation** | OPEN |

## Detailed Goals

### Step 2: Agent Protocol Definitions (Swarm RPC)
Define a lightweight RPC schema over JSON-RPC 2.0 allowing independent PhaseSpace instances to negotiate task boundaries without violating `L_eff` constraints.

### Step 3: Distributed Consensus
While the G-Set CRDT handles eventual consistency, we need a consensus hook (e.g., Raft) for time-critical, ordered transitions (like spoliation alerts) before they commit to the ledger.

### Step 4: Operator Swarm Dashboard
Expand the Leptos Operator UI to map the active agent topology in real-time.

### Step 5: End-to-End Multi-Agent Simulation
Deploy three headless agents to negotiate a mock matter playbook execution through the Sigma Kernel traps.
