# ADR-PROF-002: Constitution Versioning and Profile Upgrade Path

**Status**: Accepted (2026-05-22)
**Deciders**: Protocol / Core

---

## Context
Operator Profiles (Step 13) are constitutional overlays pinned to a specific version of the foundation constitution. As the foundation evolves, these profiles must be upgraded to ensure continued alignment. We need a secure, non-silent upgrade ceremony that prevents governance drift.

---

## Decision

### 1. Hash-on-Version Pinning
Profiles will use **Hash-on-Version Pinning** to identify the foundation constitution they are aligned with.
- `foundation_version`: A human-legible version string (e.g., `v1.0.0`).
- `foundation_hash`: A SHA-256 hash of the `constitution.json` content at the time of profile creation/attestation.

### 2. Manual Upgrade Ceremony
To prevent silent governance drift, all constitution upgrades require a manual **Upgrade Ceremony**:
1. When `pscmd` detects a mismatch between the current constitution hash and the one stored in the active profile, the profile is marked `STALE`.
2. A stale profile is **deactivated** (fail-closed) — its overlays are no longer applied by the ALP gate.
3. The operator must manually run `pscmd profile upgrade` to review the new constitution and re-attest the profile.

### 3. Upgrade Logic
The `pscmd profile upgrade` command will:
- Display the diff between the old and new constitution (if possible).
- Prompt the operator to re-confirm their tool blocklist and overlays.
- Update `foundation_version` and `foundation_hash` in the profile upon successful attestation.

### 4. Automatic Rollback
If a profile upgrade fails or is rejected by the operator, the system remains in a "foundation-only" state (no profile overlays applied). This ensures that global safety invariants are always maintained even if personalized settings are broken.

---

## Consequences
- Guarantees that personal overlays never silently conflict with foundation safety updates.
- Forces human-in-the-loop validation for every governance shift.
- Simplifies profile portability: a profile can be safely moved between nodes because its integrity is verified by content hash, not just metadata.

---

## Verification
- `pscmd profile status` shows the current alignment status (`ALIGNED`, `STALE`, or `UNVERSIONED`).
- Modification of `state/constitution.json` triggers a `STALE` status for all active profiles.
- `pscmd profile upgrade` correctly updates the hash and reactivates the profile.
