# Foundry portal requirements

This is the required product contract, not evidence of implementation.
Application semantics must be authored in Prism/LexLean; generated outputs
and this requirements document cannot substitute for the accepted model.

## Purpose and ownership

The UOR Foundation is dedicated to the democratization of technology for
the well-being of humanity. It operates under the Citizen Gardens model
through a network of physical Foundries; the first also houses Foundation HQ.
No location, legal structure, financial policy, or additional authority is
inferred from that mission.

`uor-foundry` owns the Foundation/site model. `foundry-web` consumes that
model through the PrismPM SDK and prism-stdlib to produce `app.uor.foundation`.
Reusable capabilities belong upstream, not in a vendored SDK or handwritten
application fallback. All implementation semantics flow through LexLean,
generated Lean, and lean4-prod, including the Holo profile and browser Views.

## Complete scope

The portal is the authoritative interaction point for faculty, participants,
and all other modeled stakeholder roles. It must provide the Foundation's
digital presence and operations, including:

- concept-to-production Prism workflows, Git, CI, hosting, and scheduling;
- AI inference, agentic execution, notebooks, and knowledge management;
- text and multimedia messaging, collaboration, and content creation;
- administration, governance, change management, and improvement;
- business planning, operating procedures, finances, and payments;
- learning, assessment, certification, and their authority records; and
- brand identity, approved descriptions, brand kits, and accessible presentation.

This list does not replace standards-derived coverage of the whole
organization. Physical-site responsibilities and human activities remain
modeled obligations with appropriate assessment evidence.

Each service must define its actors, permissions, inputs, outputs, state,
effects, resource requirements, failure/recovery behavior, and acceptance.
An interface, mock, third-party link, or generated document is not a service
implementation. AI output is a proposal until the applicable workflow
authorizes and verifies its effects. Recording a payment or assessment is
not evidence of settlement or certification by an independent authority.

## Controls and standards

All facets are governed through OSCAL catalogs, resolved profiles, component
and system implementation records, and assessment evidence. Every applicable
control must have a verified local implementation, verified inheritance, or
both. Inheritance identifies provider scope, exact subjects and revisions,
evidence, validity conditions, and consumer responsibilities.

The mandatory PrismPM base profile cannot be weakened by an overlay or an
unsupported inapplicability claim. Missing implementations, planned work,
unassessed claims, and remediation records do not satisfy mandatory controls.

Every adopted standard requires a complete normative-requirement inventory,
lawfully acquired pinned sources, formal bindings, implementation mappings,
and the complete applicable authoritative oracle/assessment coverage.
Structural validation, test-corpus agreement, formal proof, human assessment,
and observed operation remain distinct. Missing coverage blocks acceptance;
it must not be hidden by narrowing the claimed standard.

The model includes human-centred design, complete accessible user journeys,
brand rules, business planning, and operating procedures. Framework and
design-system bindings must preserve the adopted web standards. Brand assets,
descriptions, forecasts, and procedures are versioned and authorized; their
publication and actual outcomes are separate evidence.

## Browser network and bootstrap

Deployed service execution and peer replication use faculty and participant
browser sessions only. Dedicated Foundation nodes and hidden service backends
are not authorized. Development and bootstrap release builds use repository
devcontainers and locked SDK CI; this does not authorize server-side substitutes
for portal functions or establish browser-resident build/CI acceptance.
Kappa provides the modeled decentralized object space, queries, references,
and service artifacts; a browser runtime executes the artifacts.

GitHub Pages initially distributes the generated `foundry-web` portal at
`https://app.uor.foundation` and bootstraps the browser network. GitHub remains
a modeled publication target after the network becomes independent.
Bootstrap hosting does not authorize undisclosed external inference,
identity, signing, agent, storage, or application-service dependencies.

The migration lifecycle has three distinct states:

1. **Bootstrap:** the accepted Pages release distributes the exact application
   and dependency closure. External dependencies are inventoried, not concealed.
2. **Candidate:** browser services run and gather complete migration evidence;
   required external hosting is not removed or claimed to be unnecessary.
3. **Independent:** an authorized transition accepts measured browser-network
   readiness, complete control coverage, recovery, and all service acceptance.

Migration must demonstrate fresh-client acquisition, returning-client offline
launch, discovery, networking, identity, compiler/oracle execution, publication,
and recovery. DNS, TLS, signaling, relays, trust bootstrap, and counterparties
must be identified and tested; they cannot disappear from the dependency model.
Publication to GitHub, Cargo registries, or another external target is an
explicit authorized network effect, not an offline completion claim.

Migration is not automatic after a timer, download count, or passing schema
check. It needs exact-release evidence and an authorized decision. Rollback
and evidence invalidation are explicit; no silent fallback changes the model.

## Authority, resilience, and availability

Authority comes from accepted models, authenticated records, and authorized
decisions, not a browser, registry hash, or generated response alone.
Object, query, peer-protocol, and effect boundaries independently enforce
permissions; a caller cannot bypass them by avoiding a View. Views expose only
authorized content, metadata, queries, edges, and actions. Negative tests must
exercise unauthorized raw requests as well as interface interactions.
Publicly delivered assets contain no private credentials or organizational data.

The data model distinguishes local work, replicated durable acceptance, and
globally confirmed effects. It defines consistency, conflict handling,
revocation, authorized deletion, retention, replica independence, repair,
key recovery, atomic updates, and restoration from independent copies.
Content addressing detects identity mismatch; it does not recreate lost bytes.

Internet-grade availability requires approved service-level targets, workload
and fault bounds, measurements, and recovery objectives. Missing peers,
suspended browsers, storage denial, deleted copies, partitions, and exhausted
resources must be exercised. Peer outages cannot be silently removed from
measurements. No claim permits execution without an available executor or
recovery after every recoverable copy is destroyed.

Targets and operating policies not supplied by the owner remain explicit
acceptance inputs, not invented defaults. Their absence blocks production
acceptance, not implementation of independent generic prerequisites.

## Release acceptance

The complete locked Prism model must generate every declared artifact through
the accepted SDK, including the `.holo` runtime closure and browser projection.
No independent handwritten UI, service, compiler, or policy implementation may
substitute for the model. Bootstrap trust is explicit and non-circular.

Acceptance requires complete control/oracle coverage, human assessment where
required, all service journeys, negative/mutation tests, two clean reproducible
builds, actual browser execution, recovery and fault tests, and verification
of the deployed bytes at `app.uor.foundation`. All evidence binds exact inputs,
subjects, tools, policies, and results. Empty registers cannot establish this.

Development and verification use repository devcontainers; consumer acceptance
uses the immutable SDK lock. Preserve template policy, keep build/cache output
untracked, and make atomic Conventional Commits. Push reviewed increments to
`main` when permitted; use upstream PRs where required and inspect their CI.
