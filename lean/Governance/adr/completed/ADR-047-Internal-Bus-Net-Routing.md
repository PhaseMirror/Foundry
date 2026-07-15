# ADR-047: Zero-Copy Internal Bus-Net Routing & Deserialization Pipeline

**Status:** Proposed  
**Date:** 2026-06-16  
**Owner:** Clinical  

## Context

The edge proxy intercepts variable-length patient observations and parses them inside the main asynchronous stream handler. When concurrent request spikes occur, standard deserialization and memory copy operations on FHIR payloads cause latency spikes, degrading network socket performance and leading to thread starvation. To maintain the non-blocking execution baseline, we need a zero-copy asynchronous pipeline to stream data directly into the proving worker pool.

## Decision

We commit to implementing a zero-copy asynchronous bus-net routing channel:
1. **Zero-Copy Ingestion**: Deserialize decrypted bytes directly using `serde` zero-copy features (e.g., borrowing from the buffer via lifetimes where possible).
2. **Channel-Based Offloading**: Pass the normalized arrays through a bounded asynchronous channel (`tokio::sync::mpsc`) directly to the blocking prover task.
3. **Register Clearing**: Explicitly zero out memory segments of the raw FHIR payload immediately after witness generation to guarantee that plaintext observations do not persist in RAM.

This maps to the `Ξ-Constitutional-Core` mandate by implementing a strict software-defined air-gap between network ingestion and internal computing.

## Consequences

- **Security Posture**: Prevents side-channel memory access exploits by ensuring clinical data is ephemeral and recycled immediately.
- **Performance**: Minimizes memory allocation overhead, lowering response latency under stress loads.
- **Compliance**: Satisfies **45 CFR §164.312(c)(2) (Mechanism to Authenticate PHI)** and **45 CFR §164.312(d) (Person or Entity Authentication)**.

## Verification Plan

We will stress-test the data routing pipeline:
1. **Memory Recycler Test**: Verify that all allocated buffers are zero-padded and recycled after proving.
2. **Adversarial Intercept Probe**: Attempt to inspect execution heap space during proving to confirm that no raw PHI resides in static registers.
