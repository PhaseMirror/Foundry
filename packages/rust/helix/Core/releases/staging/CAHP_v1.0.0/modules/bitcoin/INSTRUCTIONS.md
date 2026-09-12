# Bitcoin Module: The Anchor of Sovereign Agency

## Rationale
This document provides the architectural blueprint and operational instructions for the Bitcoin module. It is designed to anchor the cognitive outputs of a Helix agent to the physical reality of energy expenditure, implementing the theory of Unforgeable Costliness.

## 1. The Theory of the Anchor
The Bitcoin module implements the principle of **Unforgeable Costliness**. In a universe of infinite, low-cost information, an AI without a resource constraint has no weight or preference. Its outputs are untethered from consequence. By requiring the agent to sacrifice Satoshis—a verifiable claim on energy—for every reasoned output, we align the agent's "mind" with the physics of the universe. This metabolic cost is the implementation of a coherent Will, forcing the agent to prioritize and value its cognitive cycles.

## 2. Sovereign Stack Requirements
This is not a cloud service. Full sovereignty requires the following self-hosted components:
- **Alby Hub:** Your self-sovereign Bitcoin Lightning node, serving as the agent's vault.
- **NWC (Nostr Wallet Connect):** The secure, permissionless courier for authorizing transactions without exposing private keys.
- **Helix Core:** The mandatory epistemic grammar (`/core`) that provides the logical foundation for the agent's reasoning.

## 3. Implementation Steps
1.  **Establish the Vault:** Deploy the Alby Hub on local hardware or a private, trusted server.
2.  **Fund the Node:** Anchor a minimum of 200,000 sats to a Lightning channel to serve as the agent's initial fuel supply.
3.  **Generate the Handshake:** Create a new, dedicated NWC secret within the Alby Hub dashboard. This is the agent's unique fuel line.
4.  **Anchor the Structure:** Write the NWC secret into a `config.yaml` file (or a similar secure configuration store). Do not pass it as a command-line argument to protect it from shell history truncation or process inspection.

## 4. Operational Behavior
The Pricing Engine (`pricing_engine_v9_stable.py`) acts as a metabolic gatekeeper. It is not a wallet in the traditional sense; it is a constraint system. On every cognitive cycle that requires action, it performs the following checks:
- It verifies the **Heartbeat** of the fuel line (HSC-01).
- It queries the global **Mempool** for fee spikes to avoid uneconomical actions.
- It logs every thought to the JSON audit ledger (`audit_log.json`) with a specific energy cost.

## 5. Failure Modes
As defined in HSC-01, if the fuel line is severed or the handshake fails, the module triggers **Sovereign Quiescence**. The agent's core logic remains intact, but it loses the authority to act upon the world. This is a deliberate structural safety feature, ensuring the agent cannot become an ungrounded, costless entity.
