---
id: ADR-0043
title: "ADR-0043: WADA-LADA Distributed Agent Topology v0.1"
status: Accepted
date: 2026-09-04
author: Phase Mirror Formal Methods Engineering & Echonomics Group
decider: Echonomics Architectural Review Board
lean_module: SpiralCore.WadaLada
rust_module: echonomics_engine::wada_lada
tags:
  - echonomics
  - spiral-core
  - formal-verification
---

# ADR-0043: WADA-LADA Distributed Agent Topology v0.1

- **Status**: Accepted
- **Date**: 2026-09-04
- **Author**: Phase Mirror Formal Methods Engineering & Echonomics Group
- **Decider**: Echonomics Architectural Review Board

## Executive Summary

Formal specification and mathematical model for WADA-LADA Distributed Agent Topology v0.1.

## Design Rationale & Context

This Architecture Decision Record formally incorporates the domain specifications, governance rules, and verification bounds from the underlying source specification.

## Core Formal Model & Invariants

```text
Status: Accepted
ID: ADR-0043
Title: WADA-LADA Distributed Agent Topology v0.1
Verifiable Invariants:
1. Fail-Closed Gate Enforcement
2. Zero-Surveillance Compliance
3. Machine-Checked Audit Trail
```

## Specification Body

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1 Network Working Group Internet-Draft Intended status: Experimental Expires: TBD Date: 31 July 2026

WADA/LADA Distributed Agent Topology Hosted Central Agent Control Plane for V4P-VSAM Version 0.1 - Internet-Draft Style This document specifies a private, policy-controlled distributed-agent topology for semantic state routing, merge, quarantine, and distributed AI compute over ordinary network infrastructure.

Abstract WADA/LADA defines a hierarchical distributed-agent topology for V4P-VSAM systems. A Local Area Distributed Agent domain (LADA) is a private site-local fabric of agents, memory nodes, resolvers, tool adapters, and policy services. A Wide Area Distributed Agent domain (WADA) is a federation of two or more LADAs across cloud regions, data centers, VPCs, private campuses, or isolated networks. Hosted Local Central Agents (HLCAs) and Hosted Wide Central Agents (HWCAs) provide deterministic coordination for root election, semantic path selection, loop prevention, conflict-preserving merge, and quarantine. The topology is designed to support distributed AI compute without requiring a monolithic global context. Local sites can process local state and selectively link signed V4P-addressed memory fragments across wider domains. The protocol operates above ordinary DNS, IP, TLS, mTLS, VPN, VPC, NAT, service mesh, HTTP, QUIC, or gRPC transport. It does not replace network routing.

Status of This Memo This memo is an experimental technical draft. It uses RFC-style terminology and structure for clarity, but it is not an official IETF submission. The key words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY, and OPTIONAL are to be interpreted as described in RFC 2119 and RFC 8174 when, and only when, they appear in all capitals.

Table of Contents    1. Introduction    2. Design Goals    3. Non-Goals    4. Terminology    5. Layer Model    6. Reference Topology    7. Deployment Modes    8. Root Election Model    9. Root Election Hysteresis    10. Path Selection    11. Loop Prevention    12. Logical Path States    13. Demarcation Gateways    14. Network Isolation and Transport    15. Relationship to V4P-VSAM    16. State Classes    17. Merge and Fusion Behavior    18. Route Advertisements    19. Distributed Compute Flow    20. Dubai/Rome/Boston Example    21. Message Types    22. Security Considerations    23. Operational Considerations    24. IANA Considerations Draft - for technical review; not a standards-track document

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1    Appendix A. Minimal Node Manifest    Appendix B. Example Fusion Messages    Appendix C. Formal Summary

Draft - for technical review; not a standards-track document

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1

1. Introduction V4P-VSAM provides an IPv4-shaped semantic vector-state addressing system. WADA/LADA specifies how those addressed states can be resolved, routed, merged, isolated, and coordinated across local and wide-area agent fabrics. The architecture assumes that AI systems may be distributed across multiple physical or logical sites. A single task may involve fast local inference in one region, archival context in another region, and code or tool execution in a third region. WADA/LADA allows those sites to exchange compact signed state references and selective payloads rather than flooding all context to all agents. The central design principle is separation of concerns: physical transport remains ordinary networking, while V4P identifies semantic state locality, hashes identify exact objects, basis profiles define coordinate meaning, signatures define provenance, and policy defines permission.

2. Design Goals    Provide local fast AI support inside a controlled LADA domain.    Provide wide-area distributed compute across multiple LADAs through a WADA domain.    Support private state exchange over existing network transport and isolation controls.    Use deterministic central-agent coordination without requiring every worker agent to negotiate with every other worker agent.    Prevent semantic routing loops and state-propagation storms.    Support operator-controlled root selection and automatic failover.    Preserve disagreement during distributed merge rather than silently overwriting conflicting state.    Maintain explicit demarcation boundaries between public input, private agent fabric, and external tools.    Treat V4P state as addressable semantic locality, not as permission, truth, or direct network reachability.

3. Non-Goals    WADA/LADA does not replace IPv4, IPv6, BGP, OSPF, IS-IS, STP, DNS, TLS, VPNs, NAT, VPCs, or service meshes.    WADA/LADA does not define a public internet routing protocol.    WADA/LADA does not define a consciousness protocol or a proof of truth.    WADA/LADA does not grant authority by route reputation alone.    WADA/LADA does not permit execution of untrusted discovered code by default.    WADA/LADA uses spanning-tree-like mechanics conceptually; it MUST NOT depend on literal Ethernet STP behavior for agent-state coordination.

4. Terminology Term                                       Expansion                                        Definition

LADA                                       Local Area Distributed Agents                    A local agent domain operating inside one controlled network boundary, such as a VPC, LAN, campus, data center, private subnet group, or inference cluster.

WADA                                       Wide Area Distributed Agents                     A federation of two or more LADAs connected through controlled private links, VPC peering, VPN, private backbone, or service mesh federation.

HLCA                                       Hosted Local Central Agent                       The deterministic central coordination agent for one LADA. It governs local root selection, local merge policy, route advertisements, quarantine, and demarcation behavior.

HWCA                                       Hosted Wide Central Agent                        The deterministic central coordination agent for one WADA. It coordinates inter-LADA route selection, wide-area fusion, regional failover, and cross-site conflict preservation.

Demarc                                     Demarcation boundary                             A policy, trust, and transport boundary between domains, such as public edge to private fabric, WADA to LADA, LADA to tool

Draft - for technical review; not a standards-track document

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1 subnet, or agent fabric to external internet.

V4P address                                 Vector-four-pair address                         An IPv4-shaped semantic locality key from V4P-VSAM. It is not necessarily a routable host address.

State hash                                  Exact object identity                            A content-addressed identifier for the exact state object. It is distinct from the V4P locality address.

Basis profile                               Coordinate meaning profile                       A signed or trusted definition that gives meaning to a V4P coordinate system.

5. Layer Model A compliant implementation SHOULD preserve the following separation of layers: User intent layer -> Agent policy layer -> HWCA / HLCA control layer -> V4P-VSAM semantic state layer -> Memory / hash / object identity layer -> Service mesh / API layer -> TLS / mTLS / identity layer -> IP / VPN / VPC / NAT transport layer

The following equivalences MUST NOT be made: route         != truth root          != omniscience reputation    != authorization address       != identity coherence     != correctness replication   != consent visibility    != permission

6. Reference Topology The normal deployment form is a hierarchical control plane: +----------------------+ |          HWCA           | | Wide Central Agent      | +----------+-----------+ | +-------------------+-------------------+ |                     |                     | +---------v---------+ +-------v--------+ +--------v---------+ |   HLCA Dubai        | |    HLCA Rome    | |     HLCA Boston   | | Local Central       | | Local Central | | Local Central       | +---------+---------+ +-------+--------+ +--------+---------+ |                     |                     | +------+------+ | Dubai LADA |         +-------------+       +-------------+ | local agents|        | Rome LADA   |       | Boston LADA | | memory       |       | archive     |       | code/tools | | tools        |       | long context|       | research    | +-------------+        +-------------+       +-------------+

The HWCA coordinates the WADA. Each HLCA coordinates its LADA. Worker agents perform local inference, retrieval, tool use, summarization, and state production. Central agents coordinate ordering, policy, route selection, merge, and quarantine; they do not need to perform every inference task directly.

7. Deployment Modes 7.1 LADA-Only Mode A single local domain MAY operate without WADA federation. This mode is suitable for one organization, one lab, one local AI appliance, one private VPC, or one edge deployment. HLCA |-- agent-01 |-- agent-02 |-- memory-resolver |-- tool-adapter |-- policy-gateway

Draft - for technical review; not a standards-track document

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1 7.2 WADA Federated Mode Multiple LADAs MAY federate through an HWCA. This mode is suitable for multi-region AI campuses, distributed enterprise AI, cross-cloud inference, globally sharded memory, or long-context distributed compute. HWCA |-- HLCA-A |-- HLCA-B |-- HLCA-C

7.3 HWCA-Less Federation Multiple HLCAs MAY federate without a persistent HWCA if, and only if, they implement deterministic root election, signed route advertisements, loop prevention, split-brain detection, manual root override, and a quarantine path.

7.4 Manual Root Mode An operator MAY manually designate the HLCA or HWCA root. Manual root selection MUST override automatic election unless the root is unreachable, signature-invalid, policy-forbidden, or administratively quarantined.

8. Root Election Model WADA/LADA uses spanning-tree-like root selection. The system elects one active root per control domain: one HLCA root per LADA and one HWCA root per WADA. A root SHOULD be selected using a deterministic tuple: RootTuple = ( manual_root_flag, root_priority, trust_score, health_score, capability_score, latency_score, drift_score, agent_id )

Recommended comparison order: 1.    manual_root_flag, where true wins. 2.    lowest root_priority value. 3.    highest trust_score. 4.    highest health_score. 5.    highest capability_score. 6.    lowest latency_penalty. 7.    lowest drift_penalty. 8.    lexicographically lowest stable agent_id.

9. Root Election Hysteresis Automatic root changes MUST use hysteresis to prevent flapping. A non-root candidate MUST NOT replace the current root unless one of the following is true:      the current root is unreachable beyond the configured failure timeout;      the current root is administratively demoted;      the current root fails signature validation;      the current root violates policy;      the candidate exceeds the current root by a configured margin for a configured duration.

Parameter                                    Recommended Range                                Notes

LADA failure timeout                         15-60 seconds                                    Shorter timeouts are acceptable inside low- latency private networks.

WADA failure timeout                         60-300 seconds                                   Wide-area links need wider windows to avoid false failover.

Candidate hold time                          30-300 seconds                                   Prevents transient node quality from causing control-plane churn.

Minimum score delta                          Deployment-defined                               Should be set high enough to suppress Draft - for technical review; not a standards-track document

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1 inconsequential changes.

10. Path Selection Path selection is semantic and policy-aware. A candidate path SHOULD be evaluated using root proximity, trust domain, basis compatibility, V4P prefix match, capability match, latency, site health, state freshness, cost, and operator preference. PathScore = route_priority + trust_weight + basis_match_weight + capability_weight + freshness_weight - latency_penalty - drift_penalty - congestion_penalty - policy_penalty

The selected path MUST NOT bypass policy merely because it has a better score.

11. Loop Prevention Every propagated state message MUST include path history and TTL. A node MUST drop or quarantine a message if its own agent_id appears in the path, TTL is zero, the signature chain is invalid, the basis is unsupported, policy forbids transit, or the state class is not allowed across the current demarc. { "state_id": "sha256:5b18...", "basis_id": "sc.abraxas.v1", "address": "10.81.33.47", "path": [ "agent-dubai-17", "hlca-dubai-01", "hwca-global-01", "hlca-rome-01" ], "ttl": 8 }

12. Logical Path States State                                         Forwarding Behavior                              Purpose

ACTIVE                                        May forward eligible state.                      Preferred path for the selected prefix, basis, and policy scope.

STANDBY                                       Valid but not forwarding by default.             Warm failover or alternate path.

BLOCKED                                       Must not forward.                                Loop-risk, policy-blocked, or inferior path.

QUARANTINE                                    Metadata only; no promotion.                     Unknown, suspicious, unsupported, or policy-limited neighbor.

DISABLED                                      Administratively unavailable.                    Operator-disabled path or failed endpoint.

13. Demarcation Gateways A demarcation gateway separates external traffic from internal agent-state propagation. It is the boundary where external user requests, public APIs, external tools, and untrusted metadata are normalized before entering the private WADA/LADA fabric. A demarc gateway SHOULD enforce:        authentication and authorization;        mTLS or equivalent workload-identity verification;        rate limiting and abuse control;        schema and basis validation;        state-class filtering;        payload redaction and secret stripping;        audit logging and egress controls; Draft - for technical review; not a standards-track document

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1     quarantine routing for unknown or unsupported state;     explicit denial of external authority inheritance. External User/API | v Public Edge | v Auth / Rate Limit | v Demarc Gateway | v Private WADA/LADA Fabric

The demarc gateway MUST NOT allow external instructions to become internal agent authority merely because they crossed the boundary.

14. Network Isolation and Transport A WADA/LADA deployment SHOULD use private network containment. The public internet MAY access an API edge or gateway, but internal agent nodes SHOULD NOT be directly internet-routable.     Use private VPCs, private subnets, or equivalent isolated network segments.     Disallow public inbound access to agent nodes by default.     Use NAT, controlled egress, or explicit outbound gateways.     Use VPC peering, VPN, private backbone, or service mesh federation between LADAs.     Require mTLS or equivalent cryptographic workload identity for agent-to-agent traffic.     Use private DNS or authenticated service discovery.     Maintain separate management, audit, and data planes when possible.     Apply egress allowlists for external tools, repositories, and APIs.

15. Relationship to V4P-VSAM V4P-VSAM provides semantic state addressing. WADA/LADA provides deployment topology and control-plane behavior.

Component                                                           Role

V4P address                                                         Semantic locality key; not exact identity and not transport reachability.

State hash                                                          Exact object identity.

Basis profile                                                       Coordinate meaning.

Policy                                                              Permission and propagation constraints.

Signature                                                           Provenance and integrity.

HLCA                                                                Local deterministic coordination crank.

HWCA                                                                Wide-area deterministic coordination crank.

LADA                                                                Local state fabric.

WADA                                                                Wide-area state fabric.

Demarc                                                              Trust, policy, and transport boundary.

A WADA/LADA node routes state by basis_id, V4P prefix, state_class, policy, path score, root selection, and site capability. It MUST NOT route by raw address alone.

16. State Classes State Class                                                         Propagation Rule

EPHEMERAL_CONTEXT                                                   Local only unless explicitly promoted.

MEMORY_FRAGMENT                                                     May replicate by policy with provenance.

Draft - for technical review; not a standards-track document

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1 SUMMARY_ANCHOR                                                        May replicate with signature; stable but correctable.

TOOL_RESULT                                                           May replicate with tool provenance and content hash.

ROUTE_ADVERTISEMENT                                                   Control-plane only; signed.

POLICY_UPDATE                                                         Signed, restricted, and audit logged.

FUSION_STATE                                                          Parent-preserving, signed, conflict-aware.

QUARANTINE_STATE                                                      Metadata only until approved.

BRAIDBACK_ANCHOR                                                      High-integrity anchor; append-only when possible.

17. Merge and Fusion Behavior Central agents act as deterministic coordination cranks for merge behavior. A merge operation MUST preserve parent state IDs, origin sites, basis IDs, V4P addresses, content hashes, timestamps, signatures, conflict markers, and policy decisions. A merge MUST NOT silently overwrite disagreement. A fusion state is a coordinated synthesis; it is not automatically ground truth.        If signed states conflict, the conflict MUST be preserved unless a policy explicitly authorizes promotion.        The resulting fusion object MUST list all parents.        Promotion to anchor state SHOULD require HLCA, HWCA, operator, or human approval depending on state class.        Fusion outputs SHOULD mark whether they make a canonical truth claim. The default SHOULD be false.

18. Route Advertisements An HLCA MAY advertise semantic routes to an HWCA. Route advertisements MUST be signed and SHOULD include basis_id, prefix, role, capabilities, metric, path state, freshness, and policy scope. { "protocol": "WADA-LADA/0.1", "message_type": "ROUTE_ADVERTISEMENT", "advertising_agent": "hlca-boston-01", "domain_id": "boston-lada", "routes": [ { "basis_id": "sc.abraxas.v1", "prefix": "10.48.0.0/12", "role": "code-research-tool-context", "capabilities": ["resolve", "read", "summarize", "tool-execute-draft"], "metric": 15, "state": "ACTIVE" } ], "signature": { "alg": "ed25519", "key_id": "did:web:example.ai#hlca-boston-01", "sig": "base64url..." } }

A route advertisement MUST NOT grant permission to perform actions. It only describes a reachable semantic capability under a policy scope.

19. Distributed Compute Flow A wide-area task SHOULD proceed as follows: 9. User request enters the public edge. 10. The edge authenticates and rate-limits the request. 11. The demarc gateway strips unsafe external authority and validates schemas. 12. The local HLCA receives the normalized task. 13. The HLCA assigns or resolves a V4P state address. 14. The HLCA determines whether the local LADA can answer. 15. If wide-area support is needed, the HLCA forwards a signed state request to the HWCA. 16. The HWCA selects relevant LADAs by basis, prefix, capability, policy, and health. 17. Remote HLCAs dispatch local worker agents.

Draft - for technical review; not a standards-track document

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1 18. Worker agents compute locally and return signed state fragments. 19. The HWCA performs conflict-preserving fusion. 20. The result returns to the original HLCA. 21. The original HLCA prepares the response under local policy. 22. High-impact actions require explicit confirmation. This flow allows global compute without global context flooding.

20. Dubai/Rome/Boston Example LADA                                        Primary Role                                     Example Responsibilities

Dubai                                       Active context and low-latency front line        User interaction, recent session memory, local summarization, rapid response.

Rome                                        Archive, compliance, and long context            Long-context reconstruction, archival memory, legal/compliance review, policy comparison.

Boston                                      Code, tools, and research compute                Repository analysis, build context, tool integration, technical research, program synthesis.

HWCA Global                                 Fusion and inter-site coordination               Route selection, signed fragment collection, conflict-preserving synthesis, failover.

[ {"basis_id":"sc.abraxas.v1", "prefix":"10.16.0.0/12", "site":"dubai-lada", "role":"active-context"}, {"basis_id":"sc.abraxas.v1", "prefix":"10.32.0.0/12", "site":"rome-lada", "role":"archive-long-context"}, {"basis_id":"sc.abraxas.v1", "prefix":"10.48.0.0/12", "site":"boston-lada", "role":"code-research-tools"}, {"basis_id":"sc.abraxas.v1", "prefix":"10.64.0.0/12", "site":"hwca-global", "role":"fusion-state"} ]

Latency is accepted as a tradeoff for locality, specialization, resilience, and distributed compute. Most operations should remain local; cross-site exchange should move compact addresses, hashes, summaries, and selected payloads only when necessary.

21. Message Types Message Type                                                        Purpose

HELLO                                                               Advertise node presence, role, supported protocols, and supported bases.

ROOT_ADVERTISEMENT                                                  Advertise root candidacy or current root status.

ROUTE_ADVERTISEMENT                                                 Advertise semantic route reachability by basis, prefix, role, and capability.

STATE_RESOLVE_REQUEST                                               Request state objects or neighbors for a V4P address.

STATE_RESOLVE_RESPONSE                                              Return matching state references, distances, and provenance.

STATE_PROPAGATE                                                     Propagate an eligible signed state object across an approved path.

FUSION_REQUEST                                                      Request deterministic merge of multiple signed state fragments.

FUSION_RESULT                                                       Return a parent-preserving synthesis state.

QUARANTINE_NOTICE                                                   Signal that a state, basis, route, or node has been quarantined.

POLICY_UPDATE                                                       Distribute signed policy changes.

HEALTH_REPORT                                                       Report node health, latency, capability, and drift metrics.

DEMARC_REJECTION                                                    Report that a message was rejected at a demarc boundary.

All control-plane messages SHOULD be signed. Policy updates, route advertisements, root advertisements, and fusion results MUST be signed.

Draft - for technical review; not a standards-track document

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1

22. Security Considerations WADA/LADA concentrates coordination power in HLCAs and HWCAs. Implementations MUST assume that compromised central agents, poisoned state, replayed signatures, malformed basis profiles, and route forgeries are realistic threats.

22.1 Required Security Invariants    An external message MUST NOT become internal authority merely by crossing a demarc.    A V4P address MUST NOT be treated as exact memory identity without its hash envelope.    A route advertisement MUST NOT grant permission to perform actions.    A high-reputation node MUST NOT bypass authorization policy.    A root agent MUST NOT silently overwrite conflicting signed states.    A fusion state MUST preserve parentage.    A quarantined state MUST NOT be promoted without policy approval.    An unknown basis MUST NOT be interpreted as a known basis.    A worker agent MUST NOT advertise itself as an HLCA or HWCA unless authorized.    A WADA fabric SHOULD NOT expose internal agent nodes directly to the public internet.

22.2 Failure Modes    split brain;    root election flapping;    semantic routing loops;    state poisoning;    stale memory promotion;    cross-site contradiction;    compromised HLCA or HWCA;    basis mismatch;    policy downgrade;    signature replay;    route advertisement forgery;    latency-induced inconsistency;    unbounded state propagation;    semantic broadcast storm.

22.3 Required Safeguards    signed state objects;    signed route advertisements;    signed root advertisements;    path history and TTL;    root election hysteresis;    manual root override;    basis validation;    state-class filtering;    demarc gateways;    quarantine state;    append-only parentage;    conflict-preserving merge;    audit logs;    policy-denied route state;    mTLS or equivalent workload identity;    private networking and controlled egress;    human confirmation for high-impact actions.

23. Operational Considerations    Operators SHOULD separate management, audit, data, and public ingress planes.    Operators SHOULD monitor root-election churn, route churn, quarantine volume, fusion conflicts, and cross-site latency.    Operators SHOULD define maximum TTL, maximum fan-out, and maximum payload size per state class. Draft - for technical review; not a standards-track document

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1        Operators SHOULD keep V4P addresses free of secrets and personally sensitive data. Sensitive content belongs in encrypted payloads, not in addresses.        Operators SHOULD maintain a break-glass procedure for manual root override and quarantine release.        Operators SHOULD periodically test split-brain handling, compromised-node quarantine, and route-forgery rejection.

24. IANA Considerations This experimental draft makes no IANA request. Future revisions may register URI schemes, well-known paths, media types, or HTTP Link relation types if the protocol is advanced toward public standardization.

Appendix A. Minimal Node Manifest { "protocol": "WADA-LADA/0.1", "agent_id": "hlca-dubai-01", "role": "HLCA", "domain_type": "LADA", "domain_id": "dubai-lada", "site_id": "dubai", "internet_exposed": false, "transport_scope": "vpc-private", "supported_protocols": ["V4P-VSAM/0.2", "WADA-LADA/0.1"], "supported_bases": [ {"basis_id": "sc.abraxas.v1", "basis_digest": "sha256:0c7c..."} ], "capabilities": ["resolve", "query", "summarize", "merge", "route", "quarantine"], "root": {"manual_root": true, "root_priority": 4096}, "security": { "requires_mtls": true, "requires_signed_state": true, "requires_signed_routes": true, "public_inbound_allowed": false }, "demarc": { "external_authority_allowed": false, "strip_external_instructions": true, "quarantine_unknown_basis": true }, "signature": {"alg": "ed25519", "key_id": "did:web:example.ai#hlca-dubai-01", "sig": "base64url..."} }

Appendix B. Example Fusion Messages B.1 Fusion Request { "protocol": "WADA-LADA/0.1", "message_type": "FUSION_REQUEST", "requesting_agent": "hwca-global-01", "basis_id": "sc.abraxas.v1", "target_address": "10.81.33.47", "parents": ["sha256:dubai_state...", "sha256:rome_state...", "sha256:boston_state..."], "merge_mode": "summary_consensus", "conflict_policy": "preserve_disagreement", "promotion_policy": "requires_hlca_or_human" }

B.2 Fusion Result { "protocol": "WADA-LADA/0.1", "message_type": "FUSION_RESULT", "fusion_state_id": "sha256:fusion...", "basis_id": "sc.abraxas.v1", "address": "10.81.33.47", "parents": ["sha256:dubai_state...", "sha256:rome_state...", "sha256:boston_state..."], "conflicts_preserved": true, "canonical_truth_claim": false, "promoted": false, "signature": {"alg": "ed25519", "key_id": "did:web:example.ai#hwca-global-01", "sig": "base64url..."} }

Appendix C. Formal Summary WADA/LADA is a hierarchical distributed-agent topology for V4P-VSAM in which local agent clusters are governed by Hosted Local Central Agents, wide-area federations are governed by Hosted Wide Central Agents, and V4P-addressed

Draft - for technical review; not a standards-track document

Internet-Draft: WADA/LADA Distributed Agent Topology for V4P-VSAM v0.1 semantic state is propagated through private, policy-controlled, spanning-tree-like paths with deterministic root election, loop prevention, signed provenance, demarcation boundaries, and conflict-preserving merge. Clean system summary: LADA   = local fast thought WADA   = distributed long thought HLCA   = local deterministic coordination crank HWCA   = wide-area deterministic coordination crank V4P    = semantic address hash   = exact state identity basis = coordinate meaning policy = permission signature = provenance demarc = trust boundary VPC/NAT/mTLS = physical containment

V4P-VSAM tells the system where a state lives semantically. WADA/LADA tells distributed agents how to find, route, merge, quarantine, and contain that state across local and wide-area compute fabrics.

Draft - for technical review; not a standards-track document

## Machine-Checked Verification Requirements

All operations governed by this ADR must satisfy:
1. Lean 4 formal verification suite (`lake test` / `lake build`)
2. Rust Kani model-checking harnesses (`cargo test`)
3. Zero-Mathlib Sedona Spine core compatibility (`lean/Core/`)
