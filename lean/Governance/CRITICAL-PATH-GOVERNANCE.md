# Critical-Path Multi-Cloud Governance

**Status**: Governance framework locked (v1 critical-path-only parity)  
**Authority**: ADR-001 (Math-First Contract, section 2.5) + ADR-016 (Critical-Path Registry Precedence)  
**Date**: 2026-05-20  

---

## Executive Summary

Phase Mirror v1 enforces multi-cloud (AWS/GCP) parity **only for the production critical path**. All other workloads remain on AWS staging in v1.

This governance model uses a **single source of truth** (`config/critical-path.yaml`) that is kept authoritative through a fail-closed CI contract:
- **Single writer**: Registry only
- **Multiple readers**: Terraform tags, CI gates, docs
- **Drift prevention**: By design, not by detection

---

## Authority Hierarchy

```
ADR-001 (Policy Intent)
        ↓ defines rules
ADR-016 (Authority Binding)
        ↓ mandates registry as source
config/critical-path.yaml (Machine Truth)
        ↓ consumed by
Terraform tags (mirrors only)
CI merge gates (fail closed)
Observability dashboards
```

---

## In-Scope for v1 AWS/GCP Parity

### Services
- **mirror-dissonance-adapters**: Core inference and session service

### Endpoints (Customer-Facing)
- `/session/auth` — authentication and authorization
- `/inference/submit` — inference submission and routing

### Data Stores
- `pirtm-dev-sessions` — user session state
- `pirtm-dev-fingerprints` — identity and commitment data

### Cross-Cutting Concerns
- Rollback and graceful degradation mechanics
- Baseline observability: request tracing, error telemetry, SLA monitoring

---

## Out-of-Scope for v1 (AWS Staging Only)

- Analytics workloads and BI pipelines
- Batch processing and non-real-time jobs
- Internal admin and ops tooling
- Non-customer-facing auxiliary services
- R&D and exploratory features
- Modules not listed in `config/critical-path.yaml`

---

## Registry Structure

### `config/critical-path.yaml`

```yaml
# Schema version (required)
schema-version: 1

# Authority declaration (required)
registry-authority: merge-gating-and-human-review-contract

# Merge-gate precedence rules (immutable)
precedence-rules:
  - docs-only-bypass
  - explicit-critical-requires-aws-gcp
  - missing-or-malformed-registry-fail-closed
  - ambiguous-scope-fail-closed

# Module paths to be treated as critical (top-level index)
critical-path:
  - packages/mirror-dissonance/src/adapters/
  - infra/terraform/
  - infra/gcp/

# Service inventory (machine-readable service IDs)
critical-path-services:
  - id: mirror-dissonance-adapters
    module-paths:
      - packages/mirror-dissonance/src/adapters/
    parity-required: true

# Endpoint inventory (customer-facing flows)
critical-path-endpoints:
  - service-id: mirror-dissonance-adapters
    endpoint-id: adapter-auth-session
    path: /session/auth
  - service-id: mirror-dissonance-adapters
    endpoint-id: adapter-inference-submit
    path: /inference/submit

# Data store inventory (customer data integrity)
critical-path-data-stores:
  - service-id: mirror-dissonance-adapters
    store-id: session-store
    logical-name: pirtm-dev-sessions
  - service-id: mirror-dissonance-adapters
    store-id: fingerprint-store
    logical-name: pirtm-dev-fingerprints

# Tag contract (schema for Terraform labels)
critical-path-tag-contract:
  service-id-label: critical-path/service-id
  endpoint-id-label: critical-path/endpoint-id
  store-id-label: critical-path/store-id

# Paths exempted from parity gating
docs-only-paths:
  - docs/
  - artifacts/docs/
  - README.md
  - CHANGELOG.md
  - CONTRIBUTING.md
  - CODE_OF_CONDUCT.md
  - SECURITY.md

# Label required to acknowledge ambiguous scope
ambiguity-ack-label: ambiguity-acknowledged
```

### Mutation Rules

- **Only mutation path**: ADR amendment → registry update in same PR
- **No dual authority**: Terraform tags and CI heuristics are read-only
- **Fail closed**: If registry is missing, malformed, or inconsistent with ADR-001, CI must fail all parity checks

---

## Terraform Tagging Scheme

All critical-path GCP and AWS resources must carry the following labels:

```terraform
labels = {
  "critical-path/service-id"  = "<service-id>"      # e.g., "mirror-dissonance-adapters"
  "critical-path/endpoint-id" = "<endpoint-id>"     # e.g., "adapter-auth-session"
  "critical-path/store-id"    = "<store-id>"        # e.g., "session-store"
  "governance"                = "adr-001-critical-path"
}
```

### Tag Placement

- **Cloud Run services** (inference API): `service-id`, `endpoint-id`
- **Firestore databases** (session/fingerprint stores): `store-id`
- **Secret Manager** (auth credentials): `service-id`
- **Artifact Registry** (container images): `service-id`
- **Vertex AI endpoints** (inference model): `service-id`, `endpoint-id`

### Example: GCP Foundation

```terraform
resource "google_cloud_run_v2_service" "multiplic" {
  name     = "multiplic-server"
  location = var.gcp_region

  labels = {
    "critical-path/service-id"  = "mirror-dissonance-adapters"
    "critical-path/endpoint-id" = "adapter-auth-session,adapter-inference-submit"
    "governance"                = "adr-001-critical-path"
  }
  # ... service config
}

resource "google_firestore_database" "database" {
  project     = var.gcp_project
  name        = "(default)"
  location_id = var.gcp_region

  labels = {
    "critical-path/store-id" = "session-store,fingerprint-store"
    "governance"             = "adr-001-critical-path"
  }
  # ... database config
}
```

---

## CI Contract and Merge Gating

### Validation Jobs (Fail Closed)

All PRs are subject to:

1. **Registry Schema Validation**
   - Schema version matches expected value
   - Authority declaration is canonical
   - Precedence rules are immutable
   - All required fields are present

2. **ADR/Registry Synchronization**
   - `config/critical-path.yaml` mirrors policy in ADR-001 section 2.5
   - Service IDs in registry match services named in ADR-001
   - In-scope and out-of-scope items match

3. **Governance Drift Detection**
   - Registry schema must not diverge from ADR-016 contract
   - Tag contract keys must be documented and stable
   - Fail closed if registry is malformed or inconsistent

### Classification Logic

For each PR:

```
IF changed files ⊆ docs-only-paths
  THEN docs-only bypass (no parity required)
  
ELSE IF any changed file ∈ critical-path modules
  THEN require parity tests (AWS + GCP)
  
ELSE
  THEN normal tests (AWS staging only)
```

### Ambiguity Handling

- If a PR touches files not clearly in or out of critical path:
  - Require `ambiguity-acknowledged` label
  - Require human review to confirm scope
  - Never guess; always fail closed

---

## Four-Lever Execution Plan

### Lever 1: Architecture (7 days)
- **Owner**: Architecture lead
- **Artifact**: ADR-001 frozen with explicit critical-path scope
- **Metric**: Signed ADR naming 5 in-scope services + observability concern
- **Status**: ✅ **COMPLETE** — ADR-001 section 2.5 locked

### Lever 2: Product/Platform (7 days)
- **Owner**: Product/architecture owner
- **Artifact**: Critical Path Surface one-pager
- **Metric**: Single agreed list naming services, endpoints, data stores
- **Status**: ⏳ **IN PROGRESS** — Use this document as foundation

### Lever 3: DevEx (30 days)
- **Owner**: DevEx lead
- **Artifacts**: CI workflow + Python validation scripts
- **Metric**: Only critical-path modules require parity; non-critical stay on normal tests
- **Status**: ✅ **FRAMEWORK PRESENT** — CI workflow exists; need end-to-end test

### Lever 4: Infra (60 days)
- **Owner**: Infra lead
- **Artifacts**: GCP resources tagged, parity test coverage
- **Metric**: All critical-path resources discoverable by label; parity passing on staging
- **Status**: ⏳ **IN PROGRESS** — GCP resources tagged; awaiting test harness

---

## Compliance Checklist

### Registry
- [x] Schema-version declared
- [x] Authority declared (merge-gating-and-human-review-contract)
- [x] Precedence rules canonical
- [x] Critical-path modules listed
- [x] Service IDs stable and non-duplicating
- [x] Endpoints with paths documented
- [x] Data stores with logical names documented
- [x] Tag contract spelled out
- [x] Docs-only paths enumerated
- [x] Ambiguity label defined

### ADR-001
- [x] Critical-path scope explicitly IN-SCOPE (deploy, auth, storage, rollback, observability)
- [x] Out-of-scope items explicitly listed
- [x] Reference to registry contract
- [x] Binding to ADR-016

### ADR-016
- [x] Registry declared as only writable authority
- [x] Read-only binding for ADRs
- [x] Fail-closed contract stated
- [x] Override policy documented

### Terraform
- [x] All GCP critical-path resources have labels
- [x] All AWS critical-path resources have labels
- [x] Labels match registry tag contract
- [x] Governance annotation present

### CI
- [x] Registry validation jobs present
- [x] Classification logic present
- [x] Docs-only bypass implemented
- [x] Ambiguity detection present
- [x] Python scripts updated for correct registry keys

---

## Maintenance and Evolution

### When to Update the Registry

1. **New critical-path service identified**
   - Add to `critical-path-services`
   - Add to `critical-path` (module paths)
   - Update ADR-001 with policy rationale
   - Tag all related Terraform resources
   - PR must pass all validation jobs

2. **Endpoint added to in-scope service**
   - Add to `critical-path-endpoints`
   - Verify service ID already exists
   - Tag resource in Terraform
   - CI validation must pass

3. **Data store added**
   - Add to `critical-path-data-stores`
   - Reference correct service ID
   - Tag Terraform resource
   - Validation must pass

### When to Update ADRs

- **ADR-001**: Policy scope changes (in-scope/out-of-scope lists)
- **ADR-016**: Authority or enforcement rules change
- **Both**: Must be updated in same PR as registry changes
- **Validation**: CI will fail if ADRs and registry diverge

---

## Disaster Recovery

### If Registry is Corrupted

1. Revert to last known-good commit
2. Run `python scripts/critical_path_registry.py validate --registry config/critical-path.yaml`
3. All PRs are blocked until validation passes
4. No manual overrides allowed

### If Tag/Registry Mismatch Detected

1. CI fails on validation job
2. PR cannot merge
3. Options:
   - Align Terraform tags to registry
   - Update registry and ADRs together

### If ADR/Registry Diverge

1. CI validation job fails
2. PR cannot merge
3. Must update both artifacts in same PR
4. Human review required

---

## Reference Implementation

See:
- [ADR-001: Math-First Contract](../adr/ADR-001-math-first-contract.md) — Policy intent
- [ADR-016: Critical-Path Registry Precedence](../adr/ADR-016-critical-path-registry-precedence.md) — Authority binding
- [config/critical-path.yaml](../../config/critical-path.yaml) — Machine truth
- [cloud/terraform/providers.tf](../../cloud/terraform/providers.tf) — Provider configuration
- [cloud/terraform/gcp_foundation.tf](../../cloud/terraform/gcp_foundation.tf) — Tagged resources
- [.github/workflows/cloud-integration.yml](../../.github/workflows/cloud-integration.yml) — CI workflow

