# PIRTM 1.0 Production Deployment Checklist
**Final Cutover to PIRTM.com with Ring 0.5 Hash Enforcement**

This checklist governs the final CI/CD cutover of the PIRTM 1.0 Runtime to PIRTM.com. It ensures that all public release artifacts satisfy the **Ring 0.5** integrity requirements, anchoring the deployment to the immutable Archivum Ledger.

## Phase 1: Artifact Integrity & Hash Enforcement (Ring 0.5)
- [ ] **Lock Dependencies (`Cargo.lock` & `requirements.txt`)**: Ensure all dependencies for `pirtm-rs` and `nl_to_pirtm.py` are strictly pinned.
- [ ] **Generate Canonical Binary Hashes**: Run `blake3` on the final release binaries (`pirtm-rs` CLI, `pirtm_runtime.bin` templates).
- [ ] **Update `mcp_manifest.yaml`**: Inject the canonical BLAKE3 hashes of all release artifacts into the manifest, setting `enforce_hash: strict`.
- [ ] **Self-Verify `manifest_verifier.py`**: Confirm the manifest verifier itself is included in the hash registry to prevent self-exemption flaws.

## Phase 2: CI/CD Pipeline Verification
- [ ] **Confirm Legal Governance Gate**: Verify the `.github/workflows/legal-governance.yml` action is active and set to *fail-closed* on `main` branch merges.
- [ ] **Dry-Run `PirtmLinkWithEnsemble`**: Execute a test deployment linking two distinct prime-indexed modules, confirming that a valid `GovernanceSeal` is successfully emitted and verified by the CI.
- [ ] **Dry-Run Spectral Veto**: Inject a deliberately non-contractive coupling matrix (e.g., $r = 1.1$) into the CI staging branch. Verify the pipeline aborts the build with the correct diagnostic error.
- [ ] **Verify `pirtm inspect` Output**: Run the inspector on a generated binary in CI to ensure the mandatory L0.7 audit string (`Audit Chain: NOT EMBEDDED`) is present in the logs.

## Phase 3: Domain & Infrastructure Cutover
- [ ] **DNS Resolution**: Confirm A-records for `PIRTM.com` correctly point to the multi-site Google Cloud Load Balancer (as defined in ADR-118).
- [ ] **TLS Provisioning**: Verify the multi-SAN TLS certificate is active and securing traffic on `PIRTM.com`.
- [ ] **CDN Cache Segregation**: Ensure Cloud CDN uses the `Host` header in its cache key to prevent cross-contamination between `pirtm.com` and `phasemirror.com` assets.
- [ ] **Publish Whitepaper & FAQ**: Deploy `docs/PIRTM-Compliance-Whitepaper.md` and `docs/PIRTM-Release-FAQ.md` to the production web root.

## Phase 4: Post-Deployment Audit
- [ ] **Run End-to-End Smoke Test**: Execute the full "Front Door" sequence via the live server: Natural Language → `nl_to_pirtm.py` → `PirtmLinkWithEnsemble` → `pirtm_runtime.bin`.
- [ ] **Ledger Synchronization**: Verify that the production deployment successfully writes its release signature back to the central `pweh_logstore` / Archivum Ledger.

---
**Sign-off:**
*Deployment is authorized only when all checkboxes are verified and cryptographically signed by the Multiplicity Foundation Release Key.*
