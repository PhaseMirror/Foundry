# UAC On-Chain Finality Lock

The EVM attestation contract will only accept blocks containing FeMoco simulation results if:
1. The timestamp matches the FPGA wall-clock.
2. The entropy `S` computed by the ThermalWindow matches the contract's expected `S ≤ 6.0`.
3. The Merkle root of the execution trace includes the `validate_concurrency()` hash.

**Deployment Status**: 
- Stage: Pre-load-test.
- Action: Do not upgrade the contract until the 100-concurrent test passes.
