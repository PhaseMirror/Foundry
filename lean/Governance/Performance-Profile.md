# Performance Profile: Archivum Bridge IPC

**Date:** 2026-06-16
**Baseline:** Unix Domain Sockets (UDS) Request/Response Pattern
**Load Test:** 10,000 serialized `BridgeMessage` exchanges.

## Metrics
- **Total Latency**: 154.05ms
- **Average Round-trip Latency**: 15.4µs
- **Performance Budget**: < 5000µs (5ms)
- **Constraint Complexity**: 100 R1CS constraints per circuit (fixed).

## Status
**PASSED**: The average latency of 15.4µs is well within the 5ms Forensic Threshold budget. The architecture maintains modular isolation while satisfying execution determinism.
