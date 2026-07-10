# ADR-SED-001: Forensic and Operational Duality in PMOC Engine

## Status
Proposed

## Context
The implementation of the Prime-Recursive Multiplicity Substrate (PRMS) requires a decoupled control layer. If cryptographic verification occurs inline with the fast mechanical integration loop, the system induces numerical latency spikes, violating real-time simulation targets.

## Decision Drivers
* **Numerical Latency**: Real-time simulation targets must be maintained.
* **Audit Integrity**: Cryptographic verification must be robust and non-bypassable.
* **Separation of Concerns**: Decoupling simulation physics from governance logic.

## Decision
We establish a strictly isolated thread boundary. The continuous DAE integration loop executes on high-priority worker threads (Path A), emitting state snapshots to a thread-safe lock-free ring buffer. The validation engine (Path B) consumes frames asynchronously, verifying provenance signatures and enforcing metric thresholds ($metrics_t \in B_\epsilon$).

## Consequences
### Positive
* Maintains real-time simulation performance.
* Provides a non-authoritative, auditable forensic track.
* Enables zero-trust observability.

### Negative
* Asynchronous verification introduces a slight delay between a state change and its audit confirmation.
* Increased architectural complexity due to multi-threaded synchronization.
