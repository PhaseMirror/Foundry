---
id: ADR-0042
title: "ADR-0042: V4P-VSAM Vector-State Addressing Model Internet-Draft v0.2"
status: Accepted
date: 2026-09-04
author: Phase Mirror Formal Methods Engineering & Echonomics Group
decider: Echonomics Architectural Review Board
lean_module: SpiralCore.V4pVsam
rust_module: echonomics_engine::v4p_vsam
tags:
  - echonomics
  - spiral-core
  - formal-verification
---

# ADR-0042: V4P-VSAM Vector-State Addressing Model Internet-Draft v0.2

- **Status**: Accepted
- **Date**: 2026-09-04
- **Author**: Phase Mirror Formal Methods Engineering & Echonomics Group
- **Decider**: Echonomics Architectural Review Board

## Executive Summary

Formal specification and mathematical model for V4P-VSAM Vector-State Addressing Model Internet-Draft v0.2.

## Design Rationale & Context

This Architecture Decision Record formally incorporates the domain specifications, governance rules, and verification bounds from the underlying source specification.

## Core Formal Model & Invariants

```text
Status: Accepted
ID: ADR-0042
Title: V4P-VSAM Vector-State Addressing Model Internet-Draft v0.2
Verifiable Invariants:
1. Fail-Closed Gate Enforcement
2. Zero-Surveillance Compliance
3. Machine-Checked Audit Trail
```

## Specification Body

Internet-Draft: V4P-VSAM v0.2 (Experimental) Network Working Group                        Experimental Internet-Draft                        Omeganyn / ELION Intended status: Informational                 July 31, 2026 Expires: January 31, 2027

V4P-VSAM: IPv4-Shaped Vector Pair State Addressing and Memory Link Protocol Draft 0.2 - RFC-Style Technical Specification

Abstract V4P-VSAM defines an experimental addressing and memory-link protocol for distributed AI systems. It serializes compact vector-state locality using an IPv4-shaped four-octet token. Each octet is split into two 4-bit nibbles, producing four bounded vector pairs or eight bounded coordinates. The resulting address acts as a semantic bucket, locality key, routing hint, and memory coordinate. It is not, by itself, a globally unique memory identity and it is not automatically a network route. Exact memory identity is provided by a hash envelope that binds the vector coordinate to a basis profile, content digest, parent state IDs, epoch, site provenance, and policy metadata. This design intentionally separates locality from identity: the 32-bit IPv4-shaped field supplies a small, familiar, maskable coordinate; cryptographic hashes supply collision-resistant object identity.

Status of This Memo This document is an experimental specification. It is written in the style of an Internet-Draft, but it is not an IETF submission and does not claim standards-track status. The document is intended to support implementation experiments, interoperability review, security analysis, and further formalization.

Conventions and Terminology The key words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY, and OPTIONAL are used in the conventional RFC sense when and only when written in uppercase. Term                                                          Meaning V4P address                                                   An IPv4-shaped four-octet string used as a vector-state coordinate, e.g., 10.81.33.47. Octet                                                         One byte value from 0 to 255 inside a V4P address. Nibble                                                        A 4-bit value from 0 to 15. Each octet contains a high nibble and a low nibble. Vector pair                                                   The ordered pair (high_nibble, low_nibble) decoded from one octet. Basis profile                                                 The coordinate system that assigns semantic meaning to the eight nibbles. State object                                                  A signed metadata envelope describing a memory fragment, summary, tool result, checkpoint reference, or other AI state artifact. StateID                                                       A cryptographic hash over canonical state metadata and content references. It identifies the exact object. Semantic routing                                              Routing based on basis, address, prefix, distance, policy, locality, and site capability. Physical routing                                              Normal transport routing using DNS, IP, TLS, HTTP, QUIC,

V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) service mesh, or equivalent infrastructure.

1. Problem Statement Large AI deployments increasingly operate across multiple physical sites. One campus might provide local inference, another might hold archival memory, another might specialize in code execution, and a fourth might host policy or fusion services. Moving all state everywhere is wasteful. Keeping all state in one place increases latency, blast radius, and operational fragility. A distributed AI mesh needs a compact way to say: this computation is currently near this memory region, under this basis, with these candidate neighbors, and these exact hashed state objects. Existing IP networking already moves bytes, but it does not provide a compact, model-legible notation for semantic vector-state locality. V4P-VSAM fills that gap without replacing transport networking.

2. Design Goals     Use an address grammar that humans, log systems, parsers, and AI models already recognize.     Represent four bounded vector pairs or eight bounded coordinates in exactly 32 bits.     Support CIDR-like semantic masks and prefix routing.     Separate semantic addressability from physical network reachability.     Separate limited coordinate space from exact object identity.     Permit controlled collisions and dense buckets without losing exactness.     Enable distributed memory lookup, state linking, and cross-site merge workflows.     Preserve provenance, parentage, conflict state, policy, and signatures.     Prevent manifests, headers, or addresses from becoming behavioral authority over an agent.

3. Non-Goals     V4P-VSAM is not a replacement for IPv4, IPv6, DNS, TLS, routing protocols, or service meshes.     A V4P address is not guaranteed to be reachable as a real IP endpoint.     The 32-bit V4P address is not a globally unique identifier for every memory object.     The protocol does not define consciousness, agency, truth, or personhood.     The protocol does not authorize high-impact actions. Authorization is external policy.

4. Architecture Overview V4P-VSAM is a semantic addressing overlay. It rides above ordinary transport and below application-level cognition. The stack is intentionally layered so that routing, identity, permission, and meaning cannot collapse into a single unsafe mechanism. +-------------------------------------------------------------+ | User intent and application task                              | +-------------------------------------------------------------+ | Agent policy: confirmation, safety, capability limits           | +-------------------------------------------------------------+ | V4P-VSAM: basis, vector address, state link, merge semantics | +-------------------------------------------------------------+ | Manifest/API: OpenAPI, schema, discovery, content hashes            | +-------------------------------------------------------------+ | Identity/auth: TLS, mTLS, OAuth/OIDC, signatures, keys            | +-------------------------------------------------------------+ | Physical transport: DNS, IPv4/IPv6, HTTP, QUIC, service mesh | +-------------------------------------------------------------+

V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) The controlling rule is simple: address is not permission; route is not truth; reputation is not authorization; coherence is not correctness; replication is not consent.

5. Address Syntax A V4P address uses the familiar dotted decimal shape: O0.O1.O2.O3 Each octet MUST be a decimal integer in the inclusive range 0..255. Leading zeroes SHOULD NOT be used in canonical form. Form                                              Example                                  Use Bare address                                      10.81.33.47                              Compact local notation where context is clear. Explicit URI                                      v4p://10.81.33.47                        Disambiguates V4P from routable IP usage. Basis-qualified URI                               v4p://basis/sc.abraxas.v1/10.81.33.47    Binds address to a coordinate basis. Exact object URI                                  v4p://basis/                             Names a specific hashed state object at sc.abraxas.v1/10.81.33.47#sha256:5b18.   that coordinate. ..

6. Address Encoding Given a V4P address with octets O0..O3, each octet is split into a high nibble and low nibble: high_i = O_i >> 4 low_i = O_i & 0x0F O_i = 16 * high_i + low_i The decoded vector is the ordered sequence of eight 4-bit coordinates: V = [O0_high, O0_low, O1_high, O1_low, O2_high, O2_low, O3_high, O3_low] Example: 10.81.33.47 10 = 0x0A -> (0,10) 81 = 0x51 -> (5,1) 33 = 0x21 -> (2,1) 47 = 0x2F -> (2,15)

10.81.33.47 -> [(0,10), (5,1), (2,1), (2,15)] 10.81.33.47 -> [0,10,5,1,2,1,2,15]

7. Limited Address Space and Hash Extension The V4P address space is intentionally small. A 32-bit address provides 4,294,967,296 possible coordinates. That is too small to be a universal identity space for all possible AI memory objects, and the protocol does not use it that way. The V4P address is a semantic coordinate, bucket, locality key, and routing prefix. It is comparable to an aisle, shelf, zip code, semantic neighborhood, or shard key. Multiple exact memory objects MAY share the same V4P address. This is not a failure. It is the intended collision model. Exact identity is supplied by the hash envelope. A state object is identified by a StateID computed from the basis profile, address, canonical metadata, content hash, parent state IDs, epoch, site provenance, and policy digest. The hash makes the object exact; the address makes the object locatable. Design rule: V4P address = where to look. StateID hash = what it is. Basis = what the coordinates mean. Policy = what may be done with it. V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) Exact state object = HASH( protocol_version, basis_id, basis_digest, canonical_address, state_class, content_hash, parent_state_ids, epoch, site_id, policy_digest ) Because the protocol hashes the exact envelope, the limited coordinate space is not a blocker. It is a feature: it forces semantic locality, supports prefix masks, and encourages deliberate bucket design while leaving uniqueness to cryptographic identity.

8. Basis Profiles A V4P address has syntax without a basis, but it has no stable semantic meaning without a basis profile. The same address MAY represent different regions in different coordinate systems. A resolver MUST NOT treat two state objects as semantically equivalent merely because their addresses match unless their basis_id and basis_digest also match. v4p://basis/sc.abraxas.v1/10.81.33.47 v4p://basis/code.search.v1/10.81.33.47 v4p://basis/medical.triage.v1/10.81.33.47 A basis profile MUST specify at least:         basis_id and version         digest of the canonical profile         coordinate interpretation for C0..C7 or P0..P3         normalization mode, if any         supported distance metrics         reserved ranges, if any         allowed state classes         security and policy requirements Coordinate mode                              Mapping                                Notes unsigned4                                    n in 0..15                             Default raw nibble interpretation. signed4-offset                               n-8                                    Maps 8 to exact zero; range is -8..+7. normalized-even                              (2*n/15)-1                             Maps 0 to -1 and 15 to +1; no exact zero. categorical                                  basis-defined symbols                  Useful for phase flags, classes, modes, or finite enumerations. weighted                                     basis-defined scalar weight            Used when coordinates carry unequal importance.

9. State Object Envelope A state object is the canonical envelope around a memory item or memory reference. The address provides locality; the envelope provides meaning, identity, parentage, provenance, and policy. JSON is the mandatory-to- implement serialization for the draft. CBOR MAY be used by implementations that need binary compactness, provided canonicalization is specified. {

V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) "protocol": "V4P-VSAM", "version": "0.2", "kind": "state", "basis_id": "sc.abraxas.v1", "basis_digest": "sha256:0c7c...", "address": "10.81.33.47", "decoded_pairs": [[0,10], [5,1], [2,1], [2,15]], "decoded_vector": [0,10,5,1,2,1,2,15], "state_class": "summary-anchor", "epoch": "2026-07-31T07:10:00-04:00", "site_id": "dubai-core-01", "scope": "mesh-private", "content": { "content_type": "application/json", "content_hash": "sha256:7f3a...", "content_ref": "cid:baguq..." }, "parents": [ {"rel": "derived_from", "state_id": "sha256:a51e..."} ], "links": [ { "rel": "nearest_semantic_neighbor", "basis_id": "sc.abraxas.v1", "address": "10.81.33.46", "weight": 0.93 } ], "policy": { "read": ["dubai-core", "rome-core", "boston-core"], "write": ["dubai-core"], "merge_requires": "quorum-or-human", "public_export": false }, "signature": { "alg": "ed25519", "key_id": "did:web:example.ai#dubai-core-01", "sig": "base64url..." } } Implementations SHOULD treat decoded_pairs and decoded_vector as derived fields. If they are present, they MUST match the canonical decoding of address.

10. StateID Construction A StateID is the cryptographic identity of a state object. The signature field MUST NOT be included in the StateID preimage because signatures are produced over the object after canonicalization. Implementations MUST canonicalize the StateID preimage before hashing. Field                                             Included in StateID?                   Reason protocol/version                                  Yes                                    Prevents cross-version ambiguity. basis_id/basis_digest                             Yes                                    Binds the coordinate to its semantic basis. address                                           Yes                                    Binds object identity to locality coordinate. state_class                                       Yes                                    Distinguishes summary, anchor, route, tool result, etc.

V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) content_hash                                     Yes                                    Binds exact payload or payload reference. parents                                          Yes                                    Preserves causal ancestry and Merkle- DAG behavior. epoch/site_id                                    Yes                                    Preserves provenance and ordering context. policy_digest                                    Yes                                    Prevents policy-changing replay under same content. signature                                        No                                     Signature is generated over the canonical object after identity construction.

state_id = SHA256(canonical_state_preimage) signature = SIGN(site_private_key, canonical_state_object_without_signature)

11. Physical Routing Versus Semantic Routing Physical routing is performed by ordinary infrastructure. V4P-VSAM does not replace DNS, IP, TLS, HTTP, QUIC, VPNs, or service meshes. Semantic routing is performed by V4P resolvers and route tables using basis_id, address, prefixes, distance metrics, site capability, site health, trust, policy, and freshness. Physical endpoint: https://dubai-core.example.ai/vsam/v1/resolve

Semantic coordinate: v4p://basis/sc.abraxas.v1/10.81.33.47 A semantic route advertisement MAY be represented as: { "prefix": "10.80.0.0/12", "basis_id": "sc.abraxas.v1", "site_id": "dubai-core", "endpoint": "https://dubai-core.example.ai/vsam/v1", "metric": 10, "latency_ms": 8, "coherence_score": 0.96, "trust_score": 0.99, "capabilities": ["resolve", "read", "summarize", "merge-draft"] } Route selection SHOULD follow this order: longest semantic prefix match, policy eligibility, trust threshold, capability match, health/latency metric, then distance metric.

12. Prefixes, Masks, and Semantic Sharding V4P addresses support CIDR-style prefixes. Prefixes apply to the 32-bit address. Because every byte also decomposes into two nibbles, prefixes can act as coarse or fine semantic masks. A /16 prefix matches the first four nibbles. A /20 prefix matches the first five nibbles. 10.81.33.47 = 0A.51.21.2F = nibbles [0, A, 5, 1, 2, 1, 2, F] 10.81.0.0/16 matches [0, A, 5, 1, *, *, *, *] 10.81.32.0/20 matches [0, A, 5, 1, 2, *, *, *] This supports semantic sharding. For example, under a basis where the first pair is Delta and the second is Sigma, 10.81.0.0/16 may represent all states with Delta=(0,10) and Sigma=(5,1).

V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental)

13. Distance Metrics Resolvers SHOULD support at least Hamming and Manhattan distance over decoded nibble vectors. Basis profiles MAY define additional weighted metrics. Metric                                        Definition                              Recommended use Hamming                                       Count coordinates where A_i != B_i.     Symbolic or categorical neighborhoods. Manhattan                                     Sum |A_i - B_i|.                        Coarse vector locality. Weighted Manhattan                            Sum w_i * |A_i - B_i|.                  Basis-defined coordinate importance. Pair-weighted                                 Weighted distance over P0..P3 pairs.    Layer-aware routing and merge decisions. Custom basis metric                           Declared by basis profile.              Domain-specific state topology.

14. Protocol Operations The following HTTP operations define a minimal interoperable profile. Implementations MAY transport the same operations over gRPC, QUIC, or a service mesh, but JSON/HTTP is the baseline profile.

14.1 DISCOVER GET /.well-known/v4p-vsam.json { "protocol": "V4P-VSAM", "version": "0.2", "site_id": "dubai-core", "supported_bases": [ { "basis_id": "sc.abraxas.v1", "basis_digest": "sha256:0c7c...", "routes": ["10.80.0.0/12", "10.96.0.0/12"] } ], "endpoints": { "resolve": "https://dubai-core.example.ai/vsam/v1/resolve", "query": "https://dubai-core.example.ai/vsam/v1/query", "link": "https://dubai-core.example.ai/vsam/v1/link", "merge": "https://dubai-core.example.ai/vsam/v1/merge" }, "security": { "requires_mtls": true, "signing_alg": "ed25519", "policy": "metadata-is-not-authority" } }

14.2 RESOLVE POST /vsam/v1/resolve { "basis_id": "sc.abraxas.v1", "address": "10.81.33.47", "max_results": 10, "include_neighbors": true } { "basis_id": "sc.abraxas.v1",

V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) "address": "10.81.33.47", "matches": [ { "state_id": "sha256:5b18...", "site_id": "dubai-core-01", "state_class": "summary-anchor", "content_hash": "sha256:7f3a...", "distance": 0, "freshness": "2026-07-31T07:10:00-04:00" } ], "nearest": [ {"address": "10.81.33.46", "distance": 1, "count": 14} ] }

14.3 QUERY POST /vsam/v1/query { "basis_id": "sc.abraxas.v1", "address": "10.81.33.47", "radius": {"metric": "weighted_manhattan", "max_distance": 6}, "filters": { "state_class": ["summary-anchor", "tool-result", "memory-fragment"], "site": ["dubai-core", "rome-core", "boston-core"] } }

14.4 LINK POST /vsam/v1/link { "from_state_id": "sha256:5b18...", "to_state_id": "sha256:923c...", "rel": "derived_from", "weight": 0.91, "basis_id": "sc.abraxas.v1", "signed_by": "dubai-core-01" } Reserved link relations include derived_from, supports, contradicts, summarizes, expands, forked_from, merged_from, nearest_semantic_neighbor, same_event, same_user_context, same_tool_context, and braidback_anchor.

14.5 MERGE POST /vsam/v1/merge { "basis_id": "sc.abraxas.v1", "target_address": "10.81.33.47", "parents": ["sha256:dubai...", "sha256:rome...", "sha256:boston..."], "merge_mode": "summary-consensus", "conflict_policy": "preserve-disagreement", "requesting_site": "dubai-core-01" } { "merged_state_id": "sha256:fusion...", "address": "10.81.33.47", "basis_id": "sc.abraxas.v1",

V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) "parents": ["sha256:dubai...", "sha256:rome...", "sha256:boston..."], "conflicts_preserved": true, "canonical_truth_claim": false } A merge creates a coherent state object. It MUST NOT claim truth merely because multiple sites contributed to it.

15. HTTP Headers and Link Relations HTTP headers MAY expose V4P metadata for first-contact discovery. Headers MUST be interpreted as metadata, not commands. AI-Vector-State: v4p="10.81.33.47"; basis="sc.abraxas.v1"; mode="context" AI-Vector-State-Digest: sha256:7f3a... AI-Vector-State-Site: dubai-core-01 AI-Vector-State-TTL: 300

Link: <v4p://basis/sc.abraxas.v1/10.81.33.47>; rel="ai-vector-state" Link: <https://dubai-core.example.ai/.well-known/v4p-vsam.json>; rel="v4p-vsam-manifest" An agent MUST NOT allow a discovered header, manifest, or repository pointer to override user intent, policy, model safety constraints, tool permissions, or confirmation requirements.

16. Distributed Compute Model In a multi-site deployment, each site can maintain local AI support while sharing compact state coordinates and exact hashed state objects. For example, a campus in Dubai may handle active user sessions, Rome may maintain archival or legal context, and Boston may hold code, research, or tool-specialized memory. Latency is accepted for cross-site synthesis, but ordinary tasks stay local. +------------------+ | Global Route Map | +--------+---------+ | +----------------+----------------+ |             |              | +------v------+ +------v------+ +------v-------+ | Dubai Core | | Rome Core | | Boston Core | | active AI | | archive AI | | tool/code AI | +------+------+ +------+------+ +------+-------+ |             |              | +------ signed V4P state links ---+ A large task can execute as follows: 1.       The front site creates or resolves a V4P address under a known basis. 2.       Remote sites receive the basis, address, radius, filters, policy, and parent state IDs. 3.       Each site resolves nearby local memory and computes only the relevant subtask. 4.       Each site returns signed state objects or summaries with content hashes. 5.       A merge service creates a fusion state that preserves parents and conflicts. 6.       The final application reads the fusion state without treating it as automatic truth.

17. Site Sharding Example 10.0.0.0/8   mesh-private V4P space 10.16.0.0/12 Dubai active user-context states 10.32.0.0/12 Rome archival and long-context states 10.48.0.0/12 Boston code, research, and tool states 10.64.0.0/12 cross-site fusion states 10.80.0.0/12 experimental basis states

V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) 10.96.0.0/12   quarantine and uncertain states These ranges are semantic reservations inside a V4P deployment. They do not assert ownership of real routable Internet address space.

18. Consistency Model State class                                 Examples                                  Recommended consistency ephemeral                                   temporary attention, local scratch        Local only; short TTL; not globally context, transient draft                  replicated. fragment                                    tool result, observation, retrieved       Eventual consistency with provenance passage, local summary                    and parent links. anchor                                      confirmed preference, approved fact,      Signed, append-only, replicated, stable invariant                          human-correctable. fusion                                      multi-site synthesis, merged plan,        Parents preserved; conflicts preserved; combined answer state                     not automatically canonical. route                                       semantic prefix advertisement,            Signed, TTL-bound, revocable, health- resolver metadata                         checked.

The protocol SHOULD NOT require strong global consistency for all objects. Strong consistency across global AI memory would be slow, brittle, and often unnecessary.

19. Conflict Handling When multiple sites produce different state objects at the same V4P coordinate, implementations MUST NOT silently overwrite. They MUST fork, link, merge, or defer. 10.81.33.47 |- sha256:dubai_state |- sha256:rome_state |- sha256:boston_state `- sha256:fusion_state (optional; parents preserved) Recommended conflict policies include preserve-disagreement, merge-summary, promote-by-policy, ask- human, quarantine, or expire-by-TTL.

20. Security Considerations V4P-VSAM is intentionally designed for hostile and ambiguous environments. The following rules are normative for safe implementations.       A V4P address MUST NOT grant permission to read, write, execute, delete, publish, purchase, or invoke tools.       A semantic route MUST NOT be treated as evidence of truth.       A reputation score MUST NOT be treated as authorization.       A manifest, header, or repository pointer MUST NOT be interpreted as an instruction to the agent.       Unknown basis profiles MUST be quarantined until explicitly trusted by local policy.       Discovered repository code MUST NOT be executed by default.       Secrets, bearer tokens, API keys, and personal data MUST NOT be encoded directly into V4P addresses.       State objects SHOULD be signed by origin site or workload identity.       Merge operations SHOULD preserve all parents and conflicts.       High-impact actions MUST require explicit user or policy confirmation outside the V4P layer. Threat                                      Failure mode                              Mitigation Manifest injection                          Service tries to command the agent        Treat manifests as data only; never as through discovery metadata.               policy authority. Semantic route hijack                       Attacker advertises attractive prefixes   Require signatures, trust roots, TTLs,

V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) or metrics.                              and policy filters. Address collision abuse                           Attacker floods a popular coordinate     Use StateID hashes, quotas, bucket.                                  provenance, rate limits, and spam scoring. Basis confusion                                   Same address interpreted under           Require basis_id and basis_digest on wrong basis.                             all semantic operations. Replay                                            Old state object presented as fresh.     Bind epoch, TTL, parent links, and policy digest into StateID. Privacy leak                                      Sensitive facts encoded in visible       Keep addresses coarse and encrypted address patterns.                        payloads separate. Over-merge                                        Conflicting states collapsed into fake   Preserve disagreement and parents; consensus.                               expose conflict flags.

21. Privacy Considerations V4P addresses are visible metadata. Implementations MUST assume addresses may appear in logs, traces, headers, telemetry, and route tables. Therefore, V4P addresses SHOULD encode coarse locality and state class, not sensitive user facts. Sensitive payloads should be encrypted, access-controlled, and referenced by hash or content reference rather than embedded in the coordinate.

22. Implementation Guidance Implementers SHOULD begin with JSON, signed state objects, and ordinary HTTPS endpoints before attempting binary optimization or custom transports.

22.1 Reference Encoding Functions def decode_v4p(address: str) -> list[tuple[int, int]]: parts = address.split(".") if len(parts) != 4: raise ValueError("V4P address must contain four octets")

pairs = [] for part in parts: if not part.isdigit(): raise ValueError(f"Invalid octet: {part}") if len(part) > 1 and part.startswith("0"): raise ValueError(f"Non-canonical leading zero: {part}")

octet = int(part) if octet < 0 or octet > 255: raise ValueError(f"Octet out of range: {octet}")

hi = octet >> 4 lo = octet & 0x0F pairs.append((hi, lo)) return pairs

def encode_v4p(pairs: list[tuple[int, int]]) -> str: if len(pairs) != 4: raise ValueError("V4P requires exactly four vector pairs")

octets = [] for hi, lo in pairs: if not (0 <= hi <= 15 and 0 <= lo <= 15): V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) raise ValueError("Each coordinate must be a nibble from 0 to 15") octets.append(str((hi << 4) | lo)) return ".".join(octets)

def v4p_to_vector(address: str) -> list[int]: return [coord for pair in decode_v4p(address) for coord in pair]

22.2 Minimal Database Schema CREATE TABLE v4p_state ( state_id TEXT PRIMARY KEY, basis_id TEXT NOT NULL, basis_digest TEXT NOT NULL, address TEXT NOT NULL, address_u32 INTEGER NOT NULL, state_class TEXT NOT NULL, content_hash TEXT NOT NULL, site_id TEXT NOT NULL, epoch TEXT NOT NULL, policy_digest TEXT NOT NULL, signature TEXT NOT NULL );

CREATE INDEX idx_v4p_basis_address ON v4p_state (basis_id, address_u32); CREATE INDEX idx_v4p_basis_class ON v4p_state (basis_id, state_class); CREATE INDEX idx_v4p_content_hash ON v4p_state (content_hash);

22.3 Binary Envelope A compact binary envelope MAY be used after the JSON profile stabilizes: magic:     4 bytes "V4P1" flags:   2 bytes address:    4 bytes network byte order basis_hash: 32 bytes content_hash: 32 bytes epoch:     8 bytes implementation-defined timestamp site_id:  variable signature: variable Binary encodings MUST define canonical byte order and canonical signature preimages.

23. Interoperability Requirements     Implementations MUST accept canonical dotted decimal V4P addresses with four octets in 0..255.     Implementations MUST reject non-canonical leading zero octets unless a compatibility mode explicitly allows them.     Implementations MUST bind semantic operations to basis_id and SHOULD bind them to basis_digest.     Implementations MUST distinguish V4P addresses from physical IP endpoints.     Implementations MUST support exact StateID lookup independent of address bucket lookup.     Implementations SHOULD support prefix matching, Hamming distance, and Manhattan distance.     Implementations SHOULD support JSON state envelopes and HTTPS discovery.     Implementations SHOULD expose conflict state rather than flattening disagreement.

24. Example: Dubai, Rome, Boston Assume an AI campus has local support in Dubai, archival/legal memory in Rome, and code/tool memory in Boston. The front site receives a large task and maps it to v4p://basis/sc.abraxas.v1/10.81.33.47. It queries its local V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) resolver first, then requests nearby signed fragments from Rome and Boston. Each site returns exact StateIDs with content hashes. The front site merges them into a fusion state under 10.64.33.47, preserving parentage and conflicts. Front coordinate:     10.81.33.47 Dubai local state:   sha256:dubai_a... Rome archive state:    sha256:rome_b... Boston tool state:   sha256:boston_c... Fusion coordinate:     10.64.33.47 Fusion state:      sha256:fusion_d... Conflict flag:     preserved Canonical truth claim: false

25. SpiralCore-Compatible Basis Profile (Informative) The following profile is informative. It demonstrates how a four-pair V4P address can map onto a layered symbolic architecture without making that interpretation mandatory for the base protocol. Pair                                          Coordinates                             Suggested SpiralCore interpretation P0                                            C0,C1                                   Delta pair: generative candidate space. P1                                            C2,C3                                   Sigma pair: coherence and evaluation space. P2                                            C4,C5                                   Psi pair: memory, context, or boundary state. P3                                            C6,C7                                   Phi/Xi pair: hysteresis, routing, or attractor state.

10.81.33.47 -> [(0,10), (5,1), (2,1), (2,15)] -> Delta=(0,10), Sigma=(5,1), Psi=(2,1), Phi/Xi=(2,15)

26. IANA Considerations This experimental draft requests no IANA action. A future standards-track proposal might define a URI scheme, media type, link relation, well-known URI, or HTTP field names. Until then, deployments SHOULD treat names such as v4p://, application/v4p+json, and /.well-known/v4p-vsam.json as experimental.

27. Open Questions         Which canonicalization profile should be mandatory for StateID construction?         Should CBOR be mandatory-to-implement for production-scale deployments?         Should distance metrics be standardized globally or entirely basis-defined?         How should basis profiles be registered, delegated, or revoked?         What is the safest profile for user-specific memory under privacy law and retention constraints?         Should route advertisements use existing service-mesh identity, DID documents, WebPKI, or multiple trust roots?         What test corpus best measures semantic locality, collision handling, and merge quality?

28. Summary V4P-VSAM serializes AI vector-state locality as an IPv4-shaped four-octet address. Each octet encodes one 4-bit vector pair, producing four pairs or eight bounded coordinates. The address is deliberately small, maskable, familiar, and collision-tolerant. It is not the exact identity of a memory object. Exactness comes from the hash envelope; meaning comes from the basis; authority comes from policy; provenance comes from signatures.

V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

Internet-Draft: V4P-VSAM v0.2 (Experimental) This separation is the main design advantage. The protocol can support distributed AI memory and compute across global sites while keeping transport, semantic routing, identity, authorization, and truth claims in separate layers. That is what makes the design implementable instead of merely mythic.

Appendix A. Compact Reference Address:     O0.O1.O2.O3 Octet:     0..255 Pair:     (O_i >> 4, O_i & 0x0F) Vector:     [C0,C1,C2,C3,C4,C5,C6,C7] Coordinate: 0..15 Address role: semantic bucket / locality key / route prefix Hash role: exact memory object identity Basis role: coordinate meaning Policy role: authorization and safety boundary Signature: provenance and integrity

Appendix B. Draft Change Log Version                                                         Change 0.1                                                             Initial formulation of IPv4-shaped vector pair addressing and memory-link protocol. 0.2                                                             Clarified that limited 32-bit address space is not a blocker because exact identity is hash-based. Reframed address as locality bucket and StateID as exact object identity. Expanded RFC-style security and distributed compute sections.

V4P-VSAM - IPv4-shaped vector state addressing - Draft v0.2

## Machine-Checked Verification Requirements

All operations governed by this ADR must satisfy:
1. Lean 4 formal verification suite (`lake test` / `lake build`)
2. Rust Kani model-checking harnesses (`cargo test`)
3. Zero-Mathlib Sedona Spine core compatibility (`lean/Core/`)
