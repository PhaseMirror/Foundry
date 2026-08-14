---
id: ADR-037
title: Prime-5 Quarantine Sinkhole for Rights Violations
status: Accepted
date: 2026-08-10
deciders: P²C Core
---

# Context
Prime 5 was previously listed in `Pforbidden` to test strict exclusion. However, pure exclusion leaves malicious actor trajectories blind to the system. They hit a wall and leave no forensic trail.

# Decision
Reclassify $p_5$ as the Sovereignty Protection & Containment Channel (`P_quarantine` = {5}). We deprecate legacy WORM logging in favor of Cryptographic Record Management Framework (CRMF) hash-chained event sealing.

# Mechanics
- **Trigger:** Rights deltas dropping below safety thresholds (mapped to 18 U.S.C. § 2261A, § 249).
- **Action:** Forced projection $\Pi_{p_5}$ applies an attenuation manifold (damping 0.92) and enforces a strict contraction bound ($\epsilon = 0.05$).
- **Output:** Immutable CRMF hash-chained attestation (PWEH), ready for regulatory handoff without reliance on GitLedger WORM logs.

# Consequences
- Bad actors are actively mapped, not just blocked.
- No cross-contamination with the primary execution stack is permitted.
- Legal reporting artifacts are generated automatically via CRMF event sealing.
