ADR-001: Genesis ODE — Core vs Experimental Scope
Document ID: ADR-001
Status: ACTIVE
Version: 1.2 consolidated
Date: 2026-05-15
Author: Allan Christopher Beckingham, CD — Lead Architect, Coherence Dynamics
Laboratory (CDL)
ORCID: 0009-0004-2830-4089
Review Basis: Limen draft; Athena edits; Phase Mirror / Ryan van Gelder referee
recommendations incorporated
Project: Genesis ODE v0.4.2 and forward experimental branches
---
0. Purpose of This ADR
This Architecture Decision Record establishes the formal governance boundary
between:
the canonical scalar Genesis ODE core, and
all experimental multiplicity, resonance, mineral, and prime-encoded extensions.
The purpose is not to slow research. The purpose is to protect both sides of the
work:
the scalar core remains bounded, reproducible, and defensible;
experimental branches remain free to explore without being forced to harden
prematurely;
claims remain tiered, tagged, and difficult to misinterpret;
symbolic, mathematical, and physical layers remain explicitly separated.
This ADR is the controlling document for all post-v0.4.2 scope decisions unless
superseded by a later ADR.
---
1. Context
Genesis ODE v0.4.2 introduced substrate-indexed persistence dynamics as its
central architectural refinement, transitioning from a generalized coherence
scalar:
```text
C(t)
```
to explicitly indexed substrate states:
```text
C\_X(t)
```
This transition stabilized the framework by separating the formal dynamical
structure from substrate-specific interpretation. The v0.4.2 scalar architecture
is now treated as the canonical reference implementation for substrate-indexed
persistence simulation.
The scalar core has demonstrated numerical stability and interpretive usefulness
across the current validation suite and example substrates, including
metallurgical, semiconductor, recursive AI, organizational, semantic, and related
comparative scenarios. This does not mean the scalar core is a final theory or
empirically calibrated across all substrates. It means the scalar architecture is
sufficiently bounded, inspectable, and reproducible to function as the current
canonical engine.
Following release, several collaborative discussions and external referee reviews
identified a natural next pressure point: the scalar architecture treats each
substrate as internally homogeneous. Most real substrates are not homogeneous.
Metallurgical, mineral, ecological, cognitive, organizational, semantic, and AI
systems often contain internal domains with distinct local stress, recovery,
impedance, drag, resonance, and failure behavior.
This motivates a possible future lift:
```text
C\_X(t) → C\_X,i(t)
```
where `i` denotes local microdomains within a substrate.
At the same time, exploratory discussions introduced additional future directions:
resonance injection modeling;
mineral substrate profiles;
multiplicity-aware coherence topology;
prime-encoded microdomain schemas;
local failure propagation;
structured perturbation and resonance-assisted degradation models.
These directions are promising, but they create a real architectural risk:
experimental branches may contaminate the validated scalar core, causing:
overextended claims in formal publications;
erosion of the current bounded and reproducible architecture;
symbolic inflation at the parameter, interpretation, or encoding layer;
premature hardening of exploratory ideas;
loss of adversarial tractability;
confusion between simulation behavior, physical calibration, and interpretive
analogy.
This ADR establishes the governance boundary required to prevent that failure
mode.
---
2. Decision
2.1 The Canonical Core Is Protected, Not Frozen
The Genesis ODE scalar core — as implemented in `GenesisODE\_v0\_4\_2.py` /
`GenesisODE\_v0\_4\_2\_rc1.py` and documented in the v0.4.2 Technical Note — is
designated the current canonical engine.
The canonical core consists of:
substrate-indexed scalar persistence states `C\_X(t)`;
substrate parameters and registry-based profiles;
impedance-aware stress propagation through `ρ\_X`, `Ω\_X`, and `D\_k,X`;
kinematic drag accumulation;
heterogeneous cross-substrate coupling;
validation routines and failure-mode detection;
metallurgical fatigue correspondence at the scalar-substrate level;
elemental and material persistence overlays under explicit guardrails;
adversarial recursive stress testing and recursive-closure diagnostics;
expanded simulation telemetry and example runs.
The scalar core may receive:
bug fixes;
documentation refinements;
numerical-stability improvements;
validation-contract updates;
calibration examples;
backwards-compatible telemetry additions.
However, the scalar core may not be modified to accommodate experimental branch
requirements without a formal superseding ADR.
Any extension that would alter the core ODE, substrate registry, impedance bridge,
validation semantics, or claim boundary must instead be implemented in a separate
experimental module with its own scope, test harness, evidence tier, and non-claim
statement.
Rule:
> Core stability takes precedence over experimental convenience.
---
2.2 Experimental Branches Are Explicitly Quarantined
The following work streams are designated EXPERIMENTAL and must be developed in
clearly separated modules, directories, and documentation:
Branch Designation      Repo Path / Artifact Path
Multiplicity-aware persistence EXPERIMENTAL
`GenesisODE\_Multiplicity\_Experimental/`
Resonant injection modeling     EXPERIMENTAL
`GenesisODE\_Resonance\_Experimental/`
Mineral substrate profiles      EXPERIMENTAL
`GenesisODE\_Mineral\_Experimental/`
Prime-encoded microdomain schemas       EXPERIMENTAL    `PRIME\_SCHEMA\_\*/`
Resonant mineral-coherence experiments EXPERIMENTAL
`Resonant\_Mineral\_Coherence\_Experimental/`
Experimental branches:
may not be cited as validated Genesis core behavior;
may not inherit evidentiary authority from the scalar core by proximity, naming,
or shared notation;
must carry explicit `EXPERIMENTAL` headers in documents and source files;
must maintain their own test harnesses, failure-mode notes, and non-claim
sections;
must declare decomposition basis, evidence tier, and intended use before external
distribution;
must avoid public language implying calibration, physical confirmation, or
universal mechanism unless such support is explicitly documented.
These branches are also explicitly protected as the project’s innovation budget.
They may explore high-uncertainty ideas, but they must remain clearly marked as
exploratory and may not be pressured into publication-ready claims before
calibration, validation, and governance structures are mature.
Rule:
> Experimental space is protected, but experimental claims are not promoted by
proximity to the core.
---
2.3 Branch Promotion Criteria
An experimental branch may only be proposed for promotion into the canonical core
if all of the following are satisfied:
Declared Scope: The branch has a clear README or design note stating its purpose,
boundaries, and non-claims.
Evidence Tier: All substrate claims are tiered under the evidence taxonomy in
Section 2.5.
Validation Contract: The branch has executable or explicitly reproducible tests.
Layer Tags: Core claims are tagged `\[E]`, `\[S]`, or `\[I]` under Section 2.6.
No Unresolved Ambiguity: Any unresolved core claim ambiguity has been downgraded
to `\[I]` or held pending redesign.
Calibration or Benchmark: At least one relevant calibration path, benchmark, or
null-model comparison exists.
Referee Review: Phase Mirror or equivalent external review has not identified
unresolved layer bleed.
Superseding ADR: Promotion requires a new ADR or explicit amendment to this ADR.
Until these conditions are met, experimental branches remain exploratory
regardless of how promising their outputs appear.
---
2.4 Prime-Encoding Discipline
This clause is the constitutional firewall for all multiplicity-related work.
The governing rule is:
> In the multiplicity-experimental branch, decomposition is first into physically
legible microdomains. Prime structure enters only as a semantically loaded
encoding of those microdomains under canonical integer factorization. \*\*Dynamics
live on `C\_X,i`, not on prime labels.\*\*
This means:
Decomposition is physical and substrate-readable. Examples include grain families,
fracture zones, inclusions, hydration regions, weld regions, heat-affected areas,
microcrack clusters, or equivalent substrate-legible partitions.
Encoding is mathematical. Each microdomain `i` receives an integer code `n\_i`
whose prime factorization acts as a canonical, typed, reversible descriptor:
```text
n\_i = ∏ p\_k^{e\_i,k}
```
Dynamics evolve on local state variables, including:
```text
C\_X,i
ρ\_X,i
Ω\_X,i
D\_k,X,i
f\_n,i
Q\_i
local thresholds
local recovery terms
```
Prime factors inform grouping, telemetry, schema decoding, feature comparison, and
coupling heuristics only.
Prime labels are never dynamical coordinates.
The integer is structured metadata, not a physical mode.
Example: Metallurgical Grain Family Encoding
A grain family might be encoded as:
```text
n\_i = 2^3 × 5^2 × 13^1
```
where the primes map to documented semantic bands and the exponents are bounded
ordinals or count-like intensities.
For example:
Prime Band       Example Meaning Example Exponent Interpretation
`2^a`   composition band         alloy phase / mineral family intensity
`5^b`   geometry band    grain size or aspect-ratio class
`13^c` defect band       microcrack-density class
This example is illustrative only. The actual assignments must be defined in
`PRIME\_SCHEMA\_Metallurgical.md` before any prime-encoded multiplicity work is
distributed.
Metallurgical Prime Band Families
The initial metallurgical schema shall reserve semantic bands for:
Semantic Family Encoding Role
Composition band         Material constitution: alloy phase, mineral family,
impurity class
Geometry band    Morphology: grain size class, aspect ratio, orientation band
History band     Processing lineage: heat treatment, weld status, cold-work,
hydration history
Defect band      Local flaw structure: inclusion type, porosity class, microcrack
density
Failure-signature band Empirical risk markers: fatigue tendency, brittle fracture
propensity, delamination risk
Each prime in a band must have:
a fixed documented meaning;
a bounded exponent range;
an allowed interpretation;
a disallowed interpretation;
at least one example;
a note indicating whether it is empirical, structural, or interpretive.
`PRIME\_SCHEMA\_Metallurgical.md` is the control surface that prevents encoding
drift.
---
2.5 Evidence Tier Commitment
All substrate classes must carry an explicit evidence tier before use in
comparative analysis or external publication.
Tier    Designation      Meaning
A       Empirically calibratable         Aims to track or qualitatively match known
curves, data, or behaviors from domain literature
B       Stylized but anchored    Structurally informed by domain literature; not
yet calibrated against a specific dataset
C       Explicitly metaphorical / exploratory     Heuristic or pedagogical use only;
no empirical grounding claimed
Substrates may not be rhetorically conflated across tiers. A Tier A metallurgical
scenario and a Tier C elemental overlay are not interchangeable analytical claims.
The artifact `SUBSTRATES\_EVIDENCE\_TIERS.md` is the highest-priority companion
document to this ADR. It must specify for each substrate:
substrate name and symbol;
intended use;
observables or proxy variables;
evidence tier;
admissible decomposition basis;
disallowed interpretations;
current calibration status;
whether the substrate is canonical, local-extension, or experimental.
Rule:
> A substrate without an evidence tier is not publication-ready.
---
2.6 Layer Separation Rule
All claims produced within the Genesis framework must be tagged by epistemic layer
before publication or external distribution.
Tag     Layer   Description
`\[E]` Empirical         Calibrated against data, directly measured, or explicitly
benchmarked
`\[S]` Structural        Derived from formal architecture or simulation behavior
under stated assumptions
`\[I]` Interpretive      Analogical, metaphorical, pedagogical, or heuristic; not a
formal mechanism claim
Any claim that remains unresolved after structured layer review must be either:
downgraded to `\[I]`, or
held pending structural redesign.
There is no valid publication state in which a core claim remains ambiguously
tagged.
Rule:
> Ambiguity is allowed in exploration. It is not allowed to harden silently into a
core claim.
---
2.7 Protocol-as-Microscope Rule
Firewalker, Phase Mirror, internal red-team review, validation scripts, and
related governance tools may be cited only as process methods, never as evidence
that a scientific or technical claim is true.
They may support statements such as:
```text
This claim was reviewed under Firewalker / Phase Mirror process.
```
They may not support statements such as:
```text
This claim is true because Firewalker / Phase Mirror approved it.
```
Rule:
> Governance tools expose failure surfaces; they do not certify truth.
---
3. Consequences
3.1 What This Protects
This ADR protects:
the scalar Genesis core as a bounded, tractable, reproducible reference
architecture;
formal publications grounded in v0.4.2 scalar behavior;
experimental freedom without premature claim hardening;
substrate-indexing discipline;
future multiplicity work from numerological or symbolic overreach;
public trust in the framework’s evidence boundaries.
3.2 What This Requires
All new Genesis-related modules must declare:
Core or Experimental status;
evidence tier;
layer tag discipline;
claim boundary;
test harness or validation status;
non-claims.
No experimental result may be cited as “Genesis behavior” in a formal publication
without explicit branch and evidence-tier annotation.
Required artifacts:
Artifact         Priority       Due Date / Horizon
`SUBSTRATES\_EVIDENCE\_TIERS.md`        Highest 7 days
`VALIDATION\_CONTRACT.md`        High   14 days
`METALLURGICAL\_CALIBRATION.md` High    30 days
`PRIME\_SCHEMA\_Metallurgical.md`       High     30 days
`RESONANT\_INJECTION\_APPENDIX.md`      Medium 30–60 days
`GenesisODE\_Multiplicity\_Experimental/microdomain\_stub.py`    Medium 30–60 days
---
4. Rollback Triggers
If any of the following conditions are observed, this ADR must be reviewed and the
affected experimental branch must be suspended pending re-evaluation:
An experimental branch claim appears in a formal publication without explicit tier
annotation.
Prime labels are used as dynamical drivers rather than metadata in any simulation
output.
An experimental module is cited as validation evidence for a scalar core claim.
Repeated layer-classification disputes in peer review suggest `\[E] / \[S] / \[I]`
tagging is not functioning as a governance gate.
Phase Mirror review identifies systematic layer bleed.
Public-facing materials imply resonance, mineral, or prime-encoded work is
validated core Genesis behavior.
A governance protocol is cited as evidence rather than process.
Experimental branch outputs create pressure to alter the scalar core without a
superseding ADR.
Rollback authority rests with the Lead Architect, with formal advisory input from
the Phase Mirror referee layer.
Any rollback event must be logged with:
trigger identified;
branch or artifact affected;
suspension action taken;
corrective action required;
reviewer notes;
date of restoration or supersession.
---
5. Artifact Dependency Map
```text
ADR-001\_Core\_vs\_Experimental\_Scope.md
├── SUBSTRATES\_EVIDENCE\_TIERS.md           \[7 days — highest priority]
├── VALIDATION\_CONTRACT.md                \[14 days]
├── METALLURGICAL\_CALIBRATION.md          \[30 days]
├── PRIME\_SCHEMA\_Metallurgical.md          \[30 days]
├── RESONANT\_INJECTION\_APPENDIX.md         \[30–60 days]
└── GenesisODE\_Multiplicity\_Experimental/
    ├── README.md                         \[30–60 days]
    ├── microdomain\_stub.py                \[30–60 days]
    └── tests/
```
All artifacts downstream of this ADR inherit its claim-boundary rules. An artifact
that contradicts ADR-001 does not supersede it; it requires a formal ADR revision
with documented rationale and referee review.
---
6. Required Experimental Branch Header
Every experimental document and source file must begin with a header substantially
equivalent to:
```text
STATUS: EXPERIMENTAL
BRANCH: <branch name>
CORE STATUS: Not part of canonical Genesis scalar core
EVIDENCE TIER: <A/B/C or mixed>
CLAIM BOUNDARY: Exploratory; not validated Genesis core behavior
NON-CLAIMS: <explicit disallowed interpretations>
```
For code files, this may appear as a module docstring. For Markdown, it must
appear before the first substantive section.
---
7. Disallowed Interpretations
The following interpretations are explicitly disallowed unless a future
superseding ADR and evidence package authorize them:
Mineral resonance experiments do not demonstrate ancient soft-stone technology.
Resonant injection terms do not imply transmutation or exotic physics.
57.8 GHz or any other carrier frequency is not a validated universal
eigenfrequency within Genesis ODE.
Prime-encoded microdomain schemas do not imply primes are physical microdomains.
Multiplicity-aware behavior does not invalidate the scalar core.
Experimental branch stability does not validate core Genesis claims.
Scalar core validation does not validate experimental branch claims.
Elemental or symbolic overlays do not replace chemistry, metallurgy, mineralogy,
neuroscience, psychology, or established physics.
Recursive AI persistence metrics do not imply AI consciousness.
Semantic coherence metrics do not imply objective truth.
Governance approval does not imply empirical confirmation.
---
8. What This ADR Does Not Claim
This ADR does not claim:
that multiplicity or resonance directions are closed;
that the scalar core is the final form of Genesis;
that experimental branches are invalid;
that prime-encoding is required for all future work;
that all substrates can be calibrated equally;
that Genesis ODE is a universal ontology;
that governance tools determine truth.
This ADR permits exploratory discussion and conceptual development when clearly
marked as exploratory.
The architecture advances by becoming more executable, more falsifiable, more
typed, and more difficult to misinterpret — not by expanding its conceptual reach.
---
9. Review and Amendment
This ADR is open for Phase Mirror review and amendment.
Proposed amendments must include:
reason for change;
affected section;
claim-boundary impact;
evidence-tier impact;
reviewer notes;
whether the amendment weakens or strengthens Sections 2.1–2.4.
No amendment may reduce the claim-boundary protections in Sections 2.1–2.4 without
a superseding ADR.
---
10. Signatures
Role    Name     Date   Status
Lead Architect Allan Christopher Beckingham, CD         2026-05-15      APPROVED
Phase Mirror Referee    Dr. Ryan van Gelder     —       PENDING REVIEW
CDL Review Layer        Athena / Zen / Limen    2026-05-15      ADVISORY INPUT
INCORPORATED
---
11. Change Log
Version Change
1.0     Initial Limen draft establishing core-vs-experimental boundary
1.1     Athena refinements: innovation budget, prime-schema example, evidence-tier
priority, Phase Mirror rollback trigger
1.2     Consolidated version: added core-not-frozen clause, branch promotion
criteria, protocol-as-microscope rule, required experimental header, disallowed
interpretations, review/amendment procedure, and expanded rollback triggers
---
Coherence Dynamics Laboratory (CDL)
Genesis ODE Project — Governance Layer
ORCID: 0009-0004-2830-4089
