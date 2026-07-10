# ADR-SED-003: Thread-Isolated Asynchronous Pipeline for PMOC Telemetry

## Status
Proposed

## Context
The Prime-Recursive Multiplicity Substrate (PRMS) requires low-latency execution of its continuous simulation loop (Path A). However, the Forensic Track (Path B) involves cryptographic hashing and lineage scoring which can induce non-deterministic latency spikes. To maintain real-time simulation targets without sacrificing zero-trust auditability, a decoupled execution strategy is needed.

## Decision Drivers
* **Real-time Performance**: The DAE simulation must not be blocked by audit logic.
* **Audit Integrity**: Every simulation frame must eventually be audited.
* **Fail-Closed Safety**: If an audit fails, the simulation must be halted immediately to prevent "un-audited state runaways."

## Decision
We implement an **Asynchronous Thread-Isolated Pipeline** using a lock-free sync channel. 
* **Worker A (Simulation)**: Runs on a high-priority thread, performing numerical integration and pushing telemetry frames to the channel.
* **Worker B (Audit)**: Consumes frames from the channel, performing provenance verification and lineage scoring.
* **Synchronization**: If the audit engine detects a violation, it drops its receiver, causing the simulation thread to fail its next `send` and terminate (Fail-Closed).

## Consequences
### Positive
* Zero-latency impact on simulation from audit logic (until buffer is full).
* Guaranteed audit of every frame before it is accepted into the long-term forensic ledger.
* Clean separation of concerns between physics and governance threads.

### Negative
* Increased complexity due to multi-threaded execution and synchronization.
* Memory overhead for the telemetry buffer.
* Potential for "backpressure" to block the simulation thread if the audit engine is significantly slower.
