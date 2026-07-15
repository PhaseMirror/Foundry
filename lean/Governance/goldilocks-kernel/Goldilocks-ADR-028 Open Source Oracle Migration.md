<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Follow-ups

Build an Open Source Oracle Migration Plan: from private policy registry to a forkable, community-verified attestation protocol
Computer
​
Architecture map: inverting the oracle trust model by moving verification from the Registry to a client-side TEE/ZK-proof SDK
Computer
​
How should the oracle be split into open source components
Which open source license fits an oracle best
How to keep a commercial version alongside open source

Yes. The strongest move is to split the oracle into an **open attestation protocol** plus a **commercial operated service**. That lets the trust model migrate from a private policy registry toward community-verifiable artifacts, while the business stays in operated infrastructure, premium policy packs, SLA, and managed certification.[^1][^2][^3]

## Migration plan

Build the open-source transition in four stages:

1. **Open the contract first**: publish the manifest schema, policy profile schema, signed payload schema, verifier API, and public test vectors before opening the full prover/oracle stack.[^4][^5]
2. **Open the verification layer**: release a client-side SDK that verifies seals, signatures, public inputs, and proofs locally, with optional TEE attestation verification and ZK-backed attestation checks where relevant.[^6][^2][^1]
3. **Open the policy plane**: move from a private registry to a public, forkable policy repository with versioned profiles, hashes, rationale, calibration metadata, and an explicit proposal/review process.[^7][^4]
4. **Keep operations premium**: preserve commercial value in hosted oracle nodes, curated manifests, managed signatory infrastructure, premium dashboards, support, compliance attestations, and enterprise policy governance.[^8][^3][^9]

## Trust inversion map

The inversion you described is exactly right: shift trust away from “the Registry says so” toward “the client SDK can verify it.” Trustless attestation work in TEE systems shows the same pattern: the service can be untrusted if clients get verifiable evidence, proofs, and pinned verification material.[^2][^1][^6]

A good target architecture is:


| Layer | Open source | Commercial |
| :-- | :-- | :-- |
| Manifest schema | Yes | Same schema, signed managed bundles |
| Policy registry | Public, forkable | Curated enterprise profiles |
| Verifier SDK | Yes, local/WASM/mobile | Managed gateway, support, SLAs |
| Proof verifier | Yes | Hosted high-availability endpoints |
| Prover/oracle runtime | Reference implementation | Hardened operated fleet |
| Governance docs | Public | Steward program, audited release process |
| Monitoring/dashboards | Community edition | Enterprise ops dashboard |

This keeps the trust boundary on the client side while retaining real product differentiation in reliability and governance.

## Open-source component split

I would split the repo family like this:

- `phase-mirror-specs` — manifest, seal, policy, attestation, signature, and vector schemas.
- `phase-mirror-sdk` — Rust core verifier plus WASM/TS/Python bindings.
- `phase-mirror-policies` — public policy registry, calibration metadata, rationale docs.
- `phase-mirror-vectors` — golden certificates, proofs, negative tests, migration vectors.
- `phase-mirror-reference-node` — minimal reproducible oracle/prover node.
- `phase-mirror-governance` — GOVERNANCE.md, policy RFC process, signatory model, release process.[^5][^4]

Keep the commercial distribution separate:

- `phase-mirror-cloud` or `phase-mirror-enterprise`
- managed nodes, dashboard, support tooling, key ceremonies, hosted watchtower, enterprise integrations.


## Licensing

If your main goal is maximum ecosystem adoption for the protocol and verifier, use a **permissive license** like Apache-2.0 for specs/SDK/core verifier. Apache-2.0 is usually the cleanest fit when patents, SDK adoption, and enterprise comfort matter.[^10]

If your main goal is preventing cloud competitors from simply packaging your full server/oracle stack, use a **dual-license** or open-core approach:

- Open: Apache-2.0 or AGPL for the community/reference stack.
- Commercial: proprietary commercial license for managed/enterprise use.[^11][^3][^9][^8]

My practical recommendation:

- **Specs, schemas, test vectors, verifier SDK**: Apache-2.0.
- **Reference node**: Apache-2.0 if you want broad adoption, or AGPL if you want reciprocity on hosted modifications.
- **Enterprise orchestration, managed dashboards, premium policy packs, hosted services**: commercial terms.[^3][^8]


## Keeping commercial alongside open source

The cleanest model is **open protocol, commercial operations**.

Commercial value comes from:

- managed uptime and multi-region hosted verification,
- enterprise manifests and signed release bundles,
- audited policy packs and calibration services,
- private signatory ceremonies and governance administration,
- compliance reporting, incident response, support SLAs,
- premium operator tooling and dashboards.[^9][^8]

Do **not** try to monetize the basic right to verify. That layer should be open, because opening verification strengthens trust and adoption. Monetize reliability, governance, support, and managed deployment instead.[^1][^2]

## Governance shift

Open-source projects benefit when roles and procedures are explicit, especially during governance transitions. For the forkable protocol, publish:[^4][^5]

- `GOVERNANCE.md`
- `POLICY_PROCESS.md`
- `SECURITY.md`
- `RELEASE.md`
- `MANIFEST_SIGNING.md`

That gives contributors clarity on:

- who proposes policy changes,
- who reviews calibration datasets,
- how manifests are signed,
- what counts as a breaking change.


## Recommended path

The best migration sequence is:

- Month 1: open specs, manifests, policy schema, and verifier SDK.
- Month 2: publish vectors, negative tests, and WASM/browser verifier.
- Month 3: open reference node and community policy process.
- Month 4+: keep the commercial offering focused on operated infrastructure and governance services.

So the oracle should be split into **open verification + open policy + open specs + optional reference node**, while the commercial side stays in **operated authority, enterprise governance, and managed reliability**.[^2][^4][^1]

If you want, I can turn this into a concrete deliverable: a **Migration Plan memo** with repo structure, license matrix, and a 90-day rollout sequence.
<span style="display:none">[^12][^13][^14][^15][^16][^17][^18][^19][^20]</span>

<div align="center">⁂</div>

[^1]: https://github.com/tiktok-privacy-innovation/trustless-attestation-verification

[^2]: https://developers.tiktok.com/blog/verifying-trusted-execution-environments

[^3]: https://fossa.com/blog/dual-licensing-models-explained/

[^4]: https://github.com/theopensourceway/guidebook/blob/main/community_governance.adoc

[^5]: https://arxiv.org/abs/2603.24879

[^6]: https://github.com/microsoft/azure-tee-attestation-samples

[^7]: https://github.com/GoverningOpen/governingopen.github.io

[^8]: https://github.com/PayDevs/awesome-oss-monetization/blob/main/approaches/dual-licensing.md

[^9]: https://blog.opentap.io/dual-licensing-open-source-software

[^10]: https://fossa.com/learn/open-source-licenses/

[^11]: https://github.com/dosyago/dual-licensing

[^12]: https://github.com/cornelius/open-source-governance

[^13]: https://github.com/apache/incubator-teaclave-trustzone-sdk/issues/112

[^14]: https://github.com/DO-SAY-GO/dual-licensing

[^15]: https://github.com/cornelius/open-source-governance/actions

[^16]: https://arxiv.org/html/2603.24879v1

[^17]: https://www.youtube.com/watch?v=VhoGeCY4i5M

[^18]: https://arxiv.org/abs/2603.26487

[^19]: https://developers.redhat.com/articles/2026/01/07/tee-backed-zero-trust-integrating-spire-confidential-containers

[^20]: https://www.newamerica.org/insights/govsch-an-open-source-schema/

