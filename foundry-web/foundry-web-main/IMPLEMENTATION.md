# Implementation status

The required scope is [SPEC.md](SPEC.md). No application capability is
accepted. The template scaffold is not a running Foundry service.

| Required work | Owner | Status |
| --- | --- | --- |
| Accepted public compiler/runtime dependency closure and Prism SDK | Upstream repositories | Blocked: package gate cannot resolve `uor-hologram`; no accepted SDK lock |
| SDK/template locks, devcontainer, and full acceptance CI | template, foundry-web | Blocked on accepted SDK |
| Complete OSCAL bindings, profile resolution, inheritance, assessments, and oracles | PrismPM, prism-stdlib | Required |
| Complete browser-resident SDK, compilers, oracles, and provider-independent signing | PrismPM and compiler/runtime repositories | Required |
| Foundation, Foundry, stakeholder, authority, and organizational models | uor-foundry | Required |
| Approved standards editions, policies, rights, and assessment inputs | Foundation/model owners | Required; mission alone does not supply these |
| Human-centred design, accessible authoring and user journeys, brands, and presentation | prism-stdlib, foundry-web | Required |
| Browser Kappa services, authorization, durable events, queries, and provenance | kappa-registry, PrismPM | Required |
| Faculty/participant browser networking, discovery, peer replication, recovery, and measured availability | Kappa/runtime models, foundry-web | Required |
| Exact-release Pages bootstrap and authorized independence/rollback lifecycle | PrismPM, foundry-web | Required |
| Git, CI, hosting, scheduling, Prism pipeline, and publication adapters | PrismPM, foundry-web | Required |
| AI inference, agent harnesses, notebooks, and knowledge management | PrismPM, foundry-web | Required |
| Text/multimedia messaging, collaboration, and content creation | PrismPM, foundry-web | Required |
| Administration, governance, change management, and improvement | uor-foundry, foundry-web | Required |
| Business plan, operating procedures, finances, and payments | uor-foundry, foundry-web | Required |
| Learning, assessment, certification, and authority lifecycle | uor-foundry, foundry-web | Required |
| Complete oracle coverage, mutation evidence, browser journeys, fault/recovery and live deployment verification | All implementing repositories | Required |

Each implementation increment must add its modeled capability, behavioral
scenario, failing test, complete implementation, and verification evidence.
Only then may its conformance register claim the evidenced capability.
No row is a deferral, exclusion, or reduced definition of done.

## Kappa/Veilid baseline

Source inspection, not execution or accepted conformance:

- Kappa [2af86560](https://github.com/UOR-Foundation/kappa-registry/tree/2af86560a177fc9651b6c0e92e7974140ed77dd5)
  locks Rekindle `3fb5b80f2d5d3d5b5a59dded1a56b477cb9f23ca` and Veilid 0.5.7.
  Kappa owns object identity, storage, references, queries, and authorization;
  Rekindle adapts Veilid routing, DHT records, and application messages.
- The optional [Kappa startup](https://github.com/UOR-Foundation/kappa-registry/blob/2af86560a177fc9651b6c0e92e7974140ed77dd5/crates/kappa-server/src/main.rs#L748)
  discards the inbound channel. Its [reconciliation loop](https://github.com/UOR-Foundation/kappa-registry/blob/2af86560a177fc9651b6c0e92e7974140ed77dd5/crates/kappa-transport-veilid/src/reconcile.rs#L146)
  copies tags, not referenced blob bytes. These paths do not establish
  authenticated end-to-end replication, conflict handling, or recovery.
- Veilid 0.5.7 has a [browser transport](https://gitlab.com/veilid/veilid/-/blob/f5cdcca38cecf4845eb9bd5e21ddca382a357a75/veilid-core/src/network_manager/network/wasm/protocol/mod.rs)
  using outbound WS/WSS, without inbound listeners or implemented WebRTC.
  Reachable transport peers are therefore a dependency of that path, distinct
  from application hosting. GitHub Pages bootstrap does not supply them.

Required modeled work includes authenticated peer/content discovery, inbound
dispatch, verified blob transfer, durable replica receipts, conflict/revocation
rules, repair, and browser-native storage/execution. Test the complete path
across networks and peer failures. Inventory relay/bootstrap dependencies;
faculty/participant browser-only service execution and peer replication remain
required. Hologram's WebRTC path is not evidence about Veilid's capabilities.

## Holospaces threat-model inputs

Reuse the [threat model](https://github.com/Hologram-Technologies/hologram/blob/96769f16be454ab1572fddff4613704ccfbebf5e/specs/holospaces/src/arc42/adoc/13_product_security.adoc)
and its witnesses alongside the [network design](https://github.com/Hologram-Technologies/hologram/blob/96769f16be454ab1572fddff4613704ccfbebf5e/specs/refactor/04-networks.md).
The latter distinguishes restricted access from private encrypted content and
identifies open public-network abuse economics and durability/replication policy.
Operator-owned storage and NIC-capable egress peers in the former are not
automatically valid assumptions for Foundry's browser-session deployment.

At that revision, the Hologram devcontainer passed:

- `bash vv/suites/cc40-product-security.sh`: eight tests, none ignored.
- `bash vv/suites/cc38-content-net.sh`: four in-process exchange/tampering
  tests, none ignored; bare-metal and browser-target compatibility builds,
  not cross-network browser deployment tests.

These witness the tested properties, not large-scale availability, hostile
storage confidentiality, or resistance to a compromised initial verifier.
CC-40's public-key identity and roster checks do not demonstrate private-key
possession, authenticated sessions, or Foundation role admission.
Foundry must bind inherited claims to their exact evidence and validate
changed assumptions explicitly.

Additional inspected witnesses, not rerun here, include real loopback
[TCP/DHT exchanges](https://github.com/Hologram-Technologies/hologram/blob/96769f16be454ab1572fddff4613704ccfbebf5e/crates/hologram-net/tests/uor_native_dht.rs)
and [CC-49 browser WebRTC](https://github.com/Hologram-Technologies/hologram/blob/96769f16be454ab1572fddff4613704ccfbebf5e/spaces/holospaces-browser/web/webrtc-content-net-test.mjs).
CC-49 uses two Chromium contexts, host ICE, and harness-carried signaling;
it does not establish cross-NAT or geographically distributed operation.
The [DHT implementation](https://github.com/Hologram-Technologies/hologram/blob/96769f16be454ab1572fddff4613704ccfbebf5e/crates/hologram-net/src/tcp/dht.rs#L82-L104)
retains incumbent entries without liveness probes. Neither these tests nor
cache-on-fetch establish churn/eclipsing resistance or durable replica policy.
Foundry acceptance still requires adversarial churn/partition, browser eviction,
and last-replica-loss evidence against its modeled recovery obligations.

## Verification of the bootstrap

- Whitespace checks passed; inherited agent policy, bootstrap workflow, and
  generated conformance document remain byte-identical to the template.
- [CI at a006253](https://github.com/UOR-Foundation/foundry-web/actions/runs/34928559731)
  failed on both architectures because `prismpm.lock` is absent. No gate was
  disabled and no SDK or application acceptance was claimed.
- The PrismPM source devcontainer's `cargo xtask package-api` fails to resolve
  `uor-hologram`. The last real upstream
  [publication attempt](https://github.com/Hologram-Technologies/hologram/actions/runs/34018837931)
  failed with a publishing-permission error; later successful dry runs do not
  demonstrate publication. The upstream owner must establish authorized
  publication before the SDK dependency closure can be accepted.
