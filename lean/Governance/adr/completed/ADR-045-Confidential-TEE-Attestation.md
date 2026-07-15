# ADR-045: Confidential TEE Remote Cloud Attestation Manifests

**Status:** Proposed  
**Date:** 2026-06-16  
**Owner:** Substrates  

## Context

The `agios-ingress-spine` edge proxy terminates critical client mTLS connections and processes zero-knowledge clinical assertions. If deployed in standard virtualized host environments, the proxy remains vulnerable to hypervisor-level sniffing, memory dumping, or root access exploits. To guarantee absolute compliance with the **Governance-by-Design** mandate, the runtime execution must be hardware-isolated and verified via remote attestation before participating in the decentralized ledger system.

## Decision

We commit to deploying the `agios-ingress-spine` edge proxy inside a hardware-enforced **Trusted Execution Environment (TEE)** (e.g., Intel SGX enclaves or AMD SEV-SNP virtual machines). 

The deployment pipeline is governed by the following key architectural controls:
1. **Attestation Manifest Binding**: Generate Terraform and Kubernetes manifests that configure a secure confidential node pool.
2. **Identity Verification**: The enclave must generate a cryptographic quote containing the measurement of the running binary, the Pallas APO root, and the public key of the node's local identity certificate.
3. **Clinical Root CA Validation**: The remote attestation verification service must validate this quote before issuing the server credentials, linking the software-defined air-gap to hardware-level roots of trust.

This maps directly to the `Ξ-Constitutional-Core` mandate by ensuring the execution environment itself is cryptographically authenticated.

## Consequences

- **Security Posture**: Hardens the host boundary. The host operating system and hypervisor are excluded from the Trusted Computing Base (TCB).
- **Performance**: Introduces a one-time attestation handshake latency (approx. 1.2s during node startup). Proving times remain within nominal bounds as the CPU instruction sets (e.g., SGX instructions) run at native speed.
- **Compliance**: Satisfies **45 CFR §164.312(a)(1) (Access Control)** and **45 CFR §164.312(e)(1) (Transmission Security)**.

## Verification Plan

We will simulate this in the `agios-staging-package-t25` test harness:
1. **Valid Quote Test**: Emulate a valid attestation quote response and verify that the TLS handshakes proceed normally.
2. **Invalid Quote Test**: Inject a tampered binary measurement into the quote and verify that the gateway aborts execution immediately, logging a `SIG_GOV_KILL` equivalent event.
