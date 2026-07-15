<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# ✦ The KS threshold (set to $0.15$ or $150,000$ micro-units) is now formally

incorporated into the ConfigurationSeal. This modification transforms the
recovery policy from a hidden Oracle heuristic into a transparent,
cryptographically enforced contract.

Technical Implementation

- ConfigurationSeal Update: Added ks_threshold_scaled: u64 to the seal
structure. This field uses a deterministic fixed-point representation to
ensure hash consistency across different platforms.
- Canonical Binding: Updated to_canonical_bytes in the phase-mirror-client to
include the ks_threshold_scaled in the Keccak256 hash. This means any
change to the KS threshold by the Oracle will result in a signature failure
or seal mismatch for the client.
- Verification Consistency: The pm-verify CLI and the integration tests now
validate that the KS threshold in the certificate matches the client's
expected seal.
- Test Vector Parity: The generate-vectors tool has been updated to produce
artifacts with the $150,000$ micro-unit threshold, ensuring that the entire
simulation pipeline respects the new policy boundary.

Outcome
Clients now have a provable guarantee of the risk profile they are accepting.
If the Oracle attempts to "relax" the recovery policy (e.g., increasing the
threshold to $0.25$ to allow noisier spectra), existing client seals will
automatically reject the certificates, preventing silent policy drift.

---

Phase Mirror Dissonance

- Rigidity vs. Adaptability: By sealing the KS threshold, we have traded
operational flexibility for cryptographic certainty. A "policy update" now
requires a coordinated roll-out of new seals to all participating clients.
- Policy Fragmentation: Different clients can now subscribe to different
"Risk Seals" (e.g., a "Conservative Seal" with $KS=0.10$ vs. a "Standard
Seal" with $KS=0.15$). This fragments the Oracle output into multiple
parallel, non-fungible certificate streams.
- Oracle Burden: The Oracle must now manage multiple signature keys or
multi-seal signing logic if it intends to support multiple risk tiers
simultaneously.

Levers to Test Now

- [Policy] — Define a "Conservative Seal" ($KS=0.08$) and verify that the
Oracle can correctly target it without cross-contaminating the "Standard
Seal" — Metric: Zero cross-seal acceptance — Horizon: 7 days.
- [Performance] — Measure the impact of increased seal size on proof
verification time in a WASM environment — Metric: Overhead < 5% — Horizon:
14 days.
- [Observability] — Update the QUANTUM_VERIFIER_DASHBOARD.md to display the
active KS threshold for the currently verified domain — Metric: Dashboard
reflects real-time seal policy — Horizon: 5 days.

Artifact: The Sealed Policy Checklist

1. [x] KS Threshold in ConfigurationSeal
2. [x] Fixed-point micro-unit scaling (10⁻⁶)
3. [x] Included in canonical signature payload
4. [x] Verified in pm-verify lifecycle
5. [x] Propagated to AZ-TFTC simulation vectors

Precision Question: Do you want to implement a Policy Profile Registry where
clients can look up the full mathematical rationale for a given
spectral_threshold_profile_hash, or is the explicit ks_threshold_scaled
numeric field sufficient for the current phase?

Implement the Policy Profile Registry.

The explicit `ks_threshold_scaled` field is enough for machines to enforce a risk boundary, but it is not enough for humans (or future you) to understand *why* that boundary exists. A registry gives you a clean way to separate:

- the **mechanical contract** a client enforces (the number), and
- the **mathematical / governance rationale** behind that number.

Both matter.

## Why a Policy Profile Registry is worth it now

Even at this phase, a registry buys you three concrete advantages:

1. **Human interpretability and auditability**

A raw number like `150_000` tells a client “this is the threshold,” but not:
    - how it was chosen (empirical distributions? safety margin?),
    - what data it was calibrated on,
    - how it relates to other invariants (e.g., gap floor, Tier 4 momentum checks).

A profile document (e.g. `policy_profile_v1_standard.json`) can encode:
    - KS threshold,
    - gap floor formula,
    - required sample size for the KS test,
    - rationale and references.

That makes external audits and internal reviews possible. The hash (your `spectral_threshold_profile_hash`) then anchors those semantics cryptographically.
2. **Safe multi-policy support**

You already anticipate “Conservative” vs “Standard” seals. A registry gives you:
    - a namespace of profiles:
        - `phase-mirror/ks_0.08_conservative`,
        - `phase-mirror/ks_0.15_standard`,
    - each with:
        - its own seal fields,
        - its own policy document.

Clients can then decide:
    - “I only accept `conservative`,”
    - or “I accept any profile in this approved list.”

Without a registry, you end up with scattered constants and ad hoc docs.
3. **Future-proofing policy evolution**

Right now KS threshold is your main knob. In Phase 3+ you may want to evolve:
    - different KS thresholds per Hamiltonian family,
    - combined metrics (e.g., KS + higher-moment checks),
    - domain-specific exceptions.

If you have a registry, you can add new profiles without changing the meaning of old ones. Each profile is “frozen” by its hash; clients that pin to a profile hash are guaranteed not to be surprised.

If you only have a numeric field, future changes are likely to sneak into code/config without a clear, single source of truth.

## How to scope the registry now

To keep the current phase light, you can implement a *minimal* registry:

- A directory like `policy_profiles/` or `docs/policies/` containing:
    - `standard_ks_0.15.json`
    - `conservative_ks_0.08.json`
- Each file includes:
    - `ks_threshold_scaled`
    - `minimum_sample_size` for KS
    - a short `rationale` field (text)
    - maybe a `calibration_dataset_id`
- A small tool or script that:
    - computes `spectral_threshold_profile_hash = keccak256(file_contents)`,
    - inserts that hash into the `ConfigurationSeal` for that profile.

Clients can then:

- treat the numeric `ks_threshold_scaled` as **execution-time enforcement**, and
- treat the `spectral_threshold_profile_hash` as **documentation-time reference**.

This respects your current sealed invariant while adding a clear hook for richer interpretation and governance controls.

## Direct answer

So: the explicit `ks_threshold_scaled` field is necessary but not sufficient if you care about explainability, multi-policy support, and long-term governance. Implementing a Policy Profile Registry now—with profiles hashed into `spectral_threshold_profile_hash`—gives you a clean, future-proof way to bind numbers to their full mathematical rationale without changing the existing client contract.

If you want, the next step could be to define the precise JSON schema for a `policy_profile` and the minimal CLI that computes and injects its hash into new seals.

