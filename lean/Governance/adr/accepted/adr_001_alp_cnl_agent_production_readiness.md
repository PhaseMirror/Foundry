# ADR 001 – Production‑Grade Deployment of ALP‑CNL & PhaseMirrorAgent Integration

**Status**: Accepted

---

## Context
The *PhaseMirror* ecosystem now includes:
- **ALP‑CNL** – the policy engine (crate `alp`) that authoritatively governs all preservation‑risk and litigation‑hold decisions.
- **PhaseMirrorAgent** – a deterministic compiler‑engine (crate `phase-mirror-agent`) exposing an `analyze` API used by the `echobraid` and `phase‑mirror` web services.
- **Governance pipeline** – Triple‑Lock verification, UnifiedWitness creation, and archival in `Archivum`.

To move from a local development setup to a production‑grade deployment we must ensure:
1. **Zero drift** – no component may compute preservation risk outside the Sedona Spine.
2. **Observability & auditability** – every request must generate a `UnifiedWitness` and be persisted.
3. **Scalability & resilience** – services must be containerised, health‑checked, and able to auto‑scale.
4. **Security & compliance** – least‑privilege runtime, signed artifacts, and secret management.
5. **CI/CD governance** – all code changes must pass the `cargo test --test governance` suite and `npm test` for the front‑ends.

---

## Decision
Adopt a **Kubernetes‑native** deployment model with the following components:
| Component | Runtime | Deployment Artifact |
|-----------|---------|---------------------|
| `alp` (policy engine) | Rust binary (`alp`) | Docker image `phase-mirror/alp:<git‑sha>` |
| `phase-mirror-agent` | Node/TS module (via `npm pack`) | Docker image `phase-mirror/agent:<git‑sha>` |
| `echobraid` service | Node TS (`tsx server.ts`) | Docker image `phase-mirror/echobraid:<git‑sha>` |
| `phase‑mirror` service | Node TS (`tsx server.ts`) | Docker image `phase-mirror/site:<git‑sha>` |
| `governance‑gateway` (Triple‑Lock, Archivum) | Rust binary (`governance`) | Docker image `phase-mirror/gateway:<git‑sha>` |

All images are built in the **CI pipeline**, signed with the project’s GPG key, and pushed to the internal container registry.

---

## Consequences
- **Operational consistency** – every request flows through the same policy‑verified path, satisfying the *Sedona Spine Mandate*.
- **Increased surface area** – container orchestration adds complexity; we must monitor resource usage and pod health.
- **Build time** – compiling the Rust binaries and packing the TS agent adds CI minutes; we cache `cargo` and `node_modules` layers.

---

## Implementation Steps
1. **CI Pipeline** (GitHub Actions / GitLab CI)
   - `jobs.build_alp` → `cargo build --release` → Docker build → `docker push`.
   - `jobs.build_agent` → `npm pack phase-mirror-agent` → Docker build (copy the pack) → push.
   - `jobs.build_echobraid` & `jobs.build_phase_mirror` → `npm ci` → `tsx` compile → Docker build.
   - Run **governance test suite**: `cargo test --test governance` and **frontend tests**: `npm run test`.
   - Lint & format checks for Rust (`cargo clippy`, `cargo fmt`) and TS (`eslint`, `prettier`).
   - Generate a *UnifiedWitness* report and attach as an artifact to the CI run.
2. **Container Images**
   - Multi‑stage Dockerfiles that compile Rust binaries in a `rust:nightly` stage, then copy into a minimal `distroless` runtime.
   - TS services use `node:current-alpine` with only the compiled `dist` folder.
3. **K8s Manifests**
   - Deployments with 2‑replica minimum, `PodDisruptionBudget` – `maxUnavailable: 1`.
   - Liveness probe on `/api/health`, readiness probe on `/api/ready`.
   - ConfigMaps for static assets (e.g., `The Phase of Mirror Dissonance.md`).
   - Secrets for `LLM_HOST`, `PM_GPT_ROOT`, etc., injected via `envFrom`.
4. **Observability**
   - Export Prometheus metrics (`/api/metrics`).
   - Structured JSON logs forwarded to Loki/Elastic.
   - OpenTelemetry tracing across the request chain (policy verification → agent → response).
5. **Security Hardening**
   - Run containers as non‑root (`USER 1001`).
   - Enable `seccomp` and `AppArmor` profiles.
   - Enforce image signatures (cosign) in the CI gate.
6. **Rollout & Canary**
   - Use a `Deployment` with `strategy: RollingUpdate` and `maxSurge: 25%`.
   - Deploy a canary service (`phase-mirror-canary`) and route 5 % of traffic via an Ingress annotation.
7. **Backup & Archivum**
   - Schedule a nightly job (CronJob) that runs `governance` to dump `state/archivum/witnesses.jsonl` to persistent storage (S3/MinIO).
   - Verify checksum and store a signed hash in the ledger.
8. **Documentation & Runbooks**
   - Create runbooks for:
     - `kubectl` troubleshooting (pod logs, witness inspection).
     - Incident response (how to pause the policy engine, re‑run triple‑lock verification).
   - Store them under `docs/adr/`.

---

## Deployment Checklist (Production Promotion)
- [ ] All CI jobs pass, including `governance` tests.
- [ ] Docker images are signed and scanned for CVEs.
- [ ] K8s manifests validated with `kubeconform`.
- [ ] Helm chart (or Kustomize overlay) generated and version‑bumped.
- [ ] Monitoring dashboards created (Grafana panels for latency, witness count, policy violations).
- [ ] Alerting rules for:
    - `governance_status != VERIFIED`
    - Spike in `phase_mirror_archivum_entries` lag.
- [ ] Secrets stored in Vault/SealedSecrets and referenced via `envFrom`.
- [ ] Backup job enabled and test‑restored on a staging cluster.
- [ ] Documentation reviewed and linked in the service catalog.

---

## Rollback Plan
1. **Immediate** – scale the Deployment replicas to `0` (stop traffic).
2. **Revert** – roll back the Helm release to the previous version (`helm rollback`).
3. **Restore** – if a policy regression is detected, run the nightly archivum restore script to recompute affected witnesses.
4. **Post‑mortem** – capture logs, update the ADR with lessons learned.

---

## Monitoring & Incident Response
- **SLOs**: 99.5 % of `/api/health` checks succeed; 99 % of requests complete within 500 ms.
- **Dashboards**: request latency per endpoint, witness creation rate, policy violation count.
- **Runbooks**: steps to manually trigger `verifyWithTripleLock` on a suspect request, re‑issue a witness hash, and re‑publish to Archivum.

---

## References
- [`models/legalese-scopist/CONTRACT.md`](file:///home/multiplicity/Multiplicity/Phase%20Mirror/models/legalese-scopist/CONTRACT.md)
- [`phase-mirror-agent/src/index.ts`](file:///home/multiplicity/Multiplicity/Phase%20Mirror/packages/phase-mirror-agent/src/index.ts)
- [`alp` crate documentation`](file:///home/multiplicity/Multiplicity/Phase%20Mirror/crates/alp/README.md)

---

*Prepared by the PhaseSpace Commander Coding Agent on 2026‑07‑01.*
