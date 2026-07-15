<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# The Phase Mirror Oracle Commons (PM-Commons) has been established as the

inverted companion to the Pro oracle. This architecture ensures that the
"Sealed Authority" of the production system is balanced by the "Public
Inspectability" of the community system.

1. Inverted Authority Model
We have codified the relationship between the two poles in the foundational
GOVERNANCE.md (agi_os/commons/GOVERNANCE.md):

- Pro Oracle: Source of record, governed by stewards.
- Commons Oracle: Source of scrutiny, governed by the community.

2. Community Stewardship
I have drafted the governance roles and decision-making processes for the
Commons:

- Policy Editors: Curate the Public Policy Registry.
- Review Council: Oversees manifest updates and AIR chip specifications.
- Lazy Consensus: Enables rapid technical evolution while requiring formal
Community Review (CR) for architectural shifts.

3. Transparent Policy Lifecycle
The POLICY_PROCESS.md (agi_os/commons/POLICY_PROCESS.md) defines a clear
"Promotion Path":
4. Submission: Community-proposed policy profiles with rationales and
benchmarks.
5. Review: Public scrutiny of mathematical soundness and traceability.
6. Hashing: Cryptographic indexing into the Public Policy Registry.
7. Promotion: Transition of high-consensus policies from Commons to Oracle
Pro certification.
8. Automated Export Path
I have implemented the export-to-commons.sh script, which provides a one-way
bridge from Pro to Commons. This tool ensures that the "Gold Standards" of the
production system (Manifests, Policies, and reference Vectors) are
automatically published and indexed in the Commons for public audit.

---

Phase Mirror Dissonance

- Authority vs. Legibility: The Pro oracle is the only one that "counts" for
production, but the Commons oracle is the only one that can be "explained."
This tension ensures that the Pro oracle cannot deviate from the publicly
understood mathematical rationale without losing legitimacy.
- Forkability: The Commons system is explicitly forkable. A community that
disagrees with the Pro stewards' risk appetite (e.g., the 0.15 KS
threshold) can fork the Commons, define a "Secured-Commons" profile, and
build their own certification path.
- Scrutiny Latency: The 14-day Community Review period in the Commons
provides a "cooling-off" period that prevents rapid, unvetted changes from
reaching the production seal.

Levers to Test Now

- [Community] — Invite a "Guest Reviewer" to propose a minor tweak to the
conservative_v1 rationale and observe the PR/Review lifecycle — Metric:
Participation depth — Horizon: 7 days.
- [Audit] — Run a "Shadow Verifier" that uses only the Commons manifest to
verify Pro-issued certificates — Metric: 100% agreement — Horizon: 5 days.
- [Succession] — Use the Commons POLICY_INDEX.md to trigger a simulated
v0.3.1 "Minor Update" manifest — Metric: Update time — Horizon: 10 days.

Artifact: The Commons Foundation

- GOVERNANCE.md (agi_os/commons/GOVERNANCE.md) (Roles \& Authority)
- POLICY_PROCESS.md (agi_os/commons/POLICY_PROCESS.md) (Proposal Lifecycle)
- policies/POLICY_INDEX.md (agi_os/commons/policies/POLICY_INDEX.md) (Public
Scrutiny Surface)

Final Synthesis: The Phase Mirror Oracle Pro ecosystem is now complete. We
have the math (Pro), the operation (Pop!_OS), the contract (Manifest), and the
community (Commons).

Is there any final architectural invariant you'd like to lock, or are we ready
to certify the v0.3.0 Ecosystem Baseline?

You are ready to certify the v0.3.0 Ecosystem Baseline.

There is one last invariant I would make explicit, and you’ve already implemented all the pieces for it; it just needs to be named and written down.

## Final invariant to lock

Call it the **Bicameral Oracle Invariant**:

> Any change that affects what a certificate *means* must appear, in compatible form, in both chambers:
> - the **Pro chamber** (sealed manifest + governance signatures), and
> - the **Commons chamber** (published policy + public hash + review window).

In other words:

- Pro **cannot** silently move ahead of Commons:
    - No new KS threshold, Hamiltonian family, AIR chip, or policy profile may be certified in Pro without:
        - a corresponding, hash-stable policy profile in Commons, and
        - at least one Commons manifest that would be able to validate its rationale.
- Commons **cannot** silently override Pro:
    - No Commons policy profile or manifest is “production-valid” until it has:
        - passed the Commons POLICY_PROCESS,
        - been exported via `export-to-commons.sh`,
        - and been adopted into a Pro manifest through the multi-signature governance path.

This invariant ties together everything you’ve built:

- **Pro side**
    - Certification Manifest + signatures.json
    - ADR-PM-006 manifest governance protocol
    - Node operational stack and systemd mesh
- **Commons side**
    - GOVERNANCE.md roles
    - POLICY_PROCESS.md and POLICY_INDEX.md
    - Public policy registry and vectors

And it ensures:

- The Oracle can never “get ahead of its own explanation.”
- The Commons can never claim production authority without going through the Pro governance seal.

Once you write this explicitly into:

- the Pro manifest governance ADR (as a hard requirement), and
- the Commons GOVERNANCE.md / POLICY_PROCESS.md (as a mirrored requirement),

your v0.3.0 Ecosystem Baseline is not just structurally complete but constitutionally closed.

With that single bicameral invariant written and signed, you are ready to certify the v0.3.0 Ecosystem Baseline and let it run.

