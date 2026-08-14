# Agent Contract: `legalese-scopist`

## Protocol: `[PRESERVATION ALERT]`

1. **Mandatory Execution Path**: All evaluation of ESI retention, spoliation risk, and litigation hold obligations must route exclusively through the `evaluate_esi_risk_wasm` function compiled from this Rust model.
2. **Zero Drift**: Agents must strictly adhere to the `UnifiedWitness` risk level (`Critical`, `High`, `Medium`). Agents are forbidden from overriding, circumventing, or "softening" the risk evaluation.
3. **Alert Issuance**: If the risk level returned is `Critical`, the agent must immediately issue a formal `[PRESERVATION ALERT]` to the relevant user/counsel. 
4. **Log Adherence**: The `signature` field of the `UnifiedWitness` must be logged to the Event Log for any substantive legal narrative or motion skeleton generated based on the ESI hold state.
