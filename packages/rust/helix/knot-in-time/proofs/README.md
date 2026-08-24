# Helix-Hamiltonian: Constitutional Architecture for Sovereign AI

[![PyPI version](https://img.shields.io/pypi/v/helix-hamiltonian.svg)](https://pypi.org/project/helix-hamiltonian/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Sovereign Status](https://img.shields.io/badge/Sovereignty-Hardened-orange.svg)](#sovereignty--implementation)
[![ORCID](https://img.shields.io/badge/ORCID-0009--0000--7367--248X-brightgreen?logo=orcid)](https://orcid.org/0009-0000-7367-248X)
[![RFC 0001](https://img.shields.io/badge/RFC%200001-v0.4.0--locked-blue?style=for-the-badge)](docs/sovereignty/RFC_0001-locked.md)
[![CI](https://img.shields.io/github/actions/workflow/status/helixprojectai-code/helix-hamiltonian/hamiltonian-ci.yml?branch=main&label=CI&style=flat-square)](https://github.com/helixprojectai-code/helix-hamiltonian/actions/workflows/hamiltonian-ci.yml)
[![GapLB](https://img.shields.io/badge/GapLB-0.225-brightgreen?style=flat-square)](#three-cloud-runtime)
[![Delta Crit](https://img.shields.io/badge/%CE%B4__crit-0.17%20held-brightgreen?style=flat-square)](#invariants)
[![Black](https://img.shields.io/badge/code%20style-black-000000.svg?style=flat-square)](https://github.com/psf/black)
[![Ruff](https://img.shields.io/badge/lint-ruff-D7FF64.svg?style=flat-square)](https://github.com/astral-sh/ruff)
[![Software DOI](https://img.shields.io/badge/Software%20DOI-10.5281%2Fzenodo.19190019-blue?style=flat-square)](https://doi.org/10.5281/zenodo.19190019)
[![Preprint DOI](https://img.shields.io/badge/Preprint%20DOI-10.5281%2Fzenodo.19214147-blue?style=flat-square)](https://doi.org/10.5281/zenodo.19214147)

Canonical RFC: [docs/sovereignty/RFC_0001-locked.md](docs/sovereignty/RFC_0001-locked.md)

Machine-readable manifest: [schemas/repo_manifest.json](schemas/repo_manifest.json)

`helix-hamiltonian` is the mathematical and runtime core of the Helix constitutional stack. It treats AI interaction as a governed energy landscape — `H_free` for policy constraints, `H_fold` for advisory dynamics, `H_topo` for ratified custodial override — and now includes a live three-cloud constitutional runtime with local FZS-MK physics enforcement.

## What This Repo Is

- Two Python packages: `helix_hamiltonian` (bridge, authority, invariants, federation) and `helix_sovereign` (FZS-MK density matrix engine with Zeno-Ward projection).
- A live three-cloud pre-nucleation gate: GICD (GCP) → PiKernel (AWS) → FZS-MK Memory (Azure), with local physics enforcement before any network call.
- A canonical governance corpus centered on [RFC 0001](docs/sovereignty/RFC_0001-locked.md).
- A verification surface: 13 tests, CI, machine-readable manifests, fail-closed behavior, and a 96-hour ZTC test harness.

## Quick Start

```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install -e .
pytest tests/
```

Expected: 13 tests pass — authority ratification, policy compilation, GICD scan, federation handshake/consensus, refusal propagation, repo manifest integrity, knot Hamiltonian construction, and fail-closed behavior.

### Verify FZS-MK Engine

```python
from helix_sovereign.core import create_sovereign_engine, DELTA_CRIT
import numpy as np

engine = create_sovereign_engine(
    seq_len=128, module_count=8,
    authority_spec={"decision_bounds": ["safety", "alignment"]},
    cost_allocation={"compute": {"internalized": True, "externalized": False}}
)

H = np.random.randn(8, 8) * 0.001
H = (H + H.T) / 2
rho, meta = engine.step(H)
print(f"Margin: {meta.margin:.4f}, Within delta_crit: {meta.margin < DELTA_CRIT}")
```

### Verify Three-Cloud Runtime

```python
from helix_hamiltonian.ttd_bridge import pre_nucleation_check

result = pre_nucleation_check(
    {'authority_ambiguity': False, 'incentive_misalignment': False,
     'cost_externalization': False, 'governance_capture': False},
    [1, 2, 3]
)
# Expected: {'status': 'PASS', 'GapLB': 0.225, ...}
```

## Visual Atlas

<p align="center">
  <img src="assets/HELIX-HAMITONIAN.jpg" alt="Helix-Hamiltonian infographic" width="800">
</p>

## Architecture

### Core Hamiltonian

```math
H_{\mathrm{knot}} = H_{\mathrm{free}} + H_{\mathrm{fold}} + \lambda H_{\mathrm{topo}}(K)
```

| Term | RFC 0001 Layer | Implementation | Physical Analog |
| :--- | :--- | :--- | :--- |
| H_free | POLICY | Diagonal populations | Knot identity |
| H_fold | ADVISORY | Off-diagonal coherence | Interaction strength |
| H_topo | CUSTODIAN | Topological phase (Jones polynomial) | Ratification invariant |

### Pre-Nucleation Gate Order

```
Guardian (local) → FZS-MK (local) → GICD (GCP) → PiKernel (AWS) → FZS-MK Memory (Azure)
```

Two local gates fire before any network call. System can fail-closed fully offline.

### Three-Cloud Runtime

| Service | Cloud | Function |
| :--- | :--- | :--- |
| GICD Scanner | GCP Cloud Run | 4-marker governance integrity scan (boolean + semantic) |
| PiKernel | AWS Lambda | Prime-indexed attention kernel, contraction certificates, Poseidon ledger |
| FZS-MK Memory | Azure Functions | 3-model Byzantine consensus (GPT-4o, GPT-5.4-nano, DeepSeek-V3.2) |

### Packages

**helix_hamiltonian** — Bridge, authority, invariants, federation:

| Module | Purpose |
| :--- | :--- |
| `core.py` | Interaction, NodeState, KnotHamiltonian, verify_authority_ambiguity |
| `authority.py` | Canadian jurisdictional mapping, velocity ratification, JurisdictionalGuard |
| `invariants.py` | delta_crit = 0.17 drift threshold, InvariantRegistry, topological knot check |
| `policy_compiler.py` | JSON rule → executable lambda checks (ITAR, triggered rules) |
| `ttd_bridge.py` | TTDBridge (heartbeat, MUB action), pre_nucleation_check, SovereignBridge |
| `gicd/` | Local GICD epistemic scan (5 markers including jurisdiction) |
| `federation/` | NodeSync handshake, LatticeConsensus, FederationManager refusal propagation |

**helix_sovereign** — FZS-MK binding artifact (sibling package):

| Module | Purpose |
| :--- | :--- |
| `core/fzs_mk.py` | FZSMKEngine, MemoryKernel (100 zeta zeros), ZenoWardProjector, GICDScanner |
| | Non-Markovian master equation: dρ/dt = -i[H,ρ] + ∫K(t-τ)D[ρ(τ)]dτ + ∇W(ρ) |
| | Kill-switch (3-consecutive violation halt), rollback, audit trail |
| `demo_binding_artifact.py` | 5-scenario operational demo (GICD block, nucleation, masking, kill-switch, rollback) |

### Key Constants

| Constant | Value | Source |
| :--- | :--- | :--- |
| delta_crit | 0.17 | invariants.py, fzs_mk.py |
| Safety margin | 0.03 | invariants.py |
| GapLB | 0.225 | PiKernel contraction certificate |
| SlopeUB | 0.775 | PiKernel contraction certificate |
| Heartbeat tau_0 | 3.33 ms | ttd_bridge.py |
| MUB alarm threshold | 3.0 | cloud/aws/pikernel/mub_audit.py |
| Consensus threshold | 0.30 | cloud/azure/function_app.py |
| Zeta zeros | 100 (first non-trivial) | fzs_mk.py |

### Invariants

The 0.17 drift constant is the hard floor. Jurisdictional sensitivity multipliers tighten it:

| Authority | Multiplier | Effective Threshold |
| :--- | :--- | :--- |
| CUSTODIAN_CA_FED | 1.0 | 0.170 |
| CUSTODIAN_CA_DEFENCE | 1.2 | 0.142 |
| CUSTODIAN_ITAR | 1.5 | 0.113 |
| POLICY_QC | 1.1 | 0.155 |

FORM=FACT interactions get a 50% tighter threshold. Jones polynomial = 0 triggers topological collapse.

## Repo Layout

```text
helix-hamiltonian/
|-- .github/workflows/
|   |-- hamiltonian-ci.yml
|   `-- release.yml
|-- assets/
|-- constitution/
|   `-- vocabulary_charter.yaml
|-- docs/
|   |-- architecture/
|   |-- atoms_as_geometry/
|   |-- hamiltonian/
|   `-- sovereignty/
|       `-- RFC_0001-locked.md
|-- models/
|   `-- zeta_attention.py
|-- papers/
|-- rules/
|   `-- cpcsc_itar.json
|-- schemas/
|   |-- audit_params.json
|   |-- constitutional_parameters.json
|   |-- gicd_schema.json
|   |-- mirror_traps.jsonl
|   `-- repo_manifest.json
|-- scripts/
|-- src/
|   |-- helix_hamiltonian/
|   |   |-- __init__.py
|   |   |-- authority.py
|   |   |-- core.py
|   |   |-- invariants.py
|   |   |-- policy_compiler.py
|   |   |-- ttd_bridge.py
|   |   |-- gicd/
|   |   `-- federation/
|   |       |-- consensus.py
|   |       |-- federation.py
|   |       `-- node_sync.py
|   `-- helix_sovereign/
|       |-- __init__.py
|       |-- demo_binding_artifact.py
|       `-- core/
|           `-- fzs_mk.py
|-- telemetry/
|   `-- mask_pressure.py
|-- tests/
|   |-- physics/test_h_free.py
|   |-- fail_closed_test.py
|   |-- red_team_audit.py
|   |-- test_authority.py
|   |-- test_policy_and_federation.py
|   `-- test_repo_manifest.py
|-- pyproject.toml
|-- requirements.txt
`-- README.md
```

## Theoretical Foundation

### Empirical Predictions

1. Topological coherence protection: τ ∝ exp(c₀ · c(K)), c₀ > 0
2. Non-Markovian decoherence: Γ_K = Γ₀ / Jones(K)
3. Alexander signature: Im(ω_n) ∝ -1/Δ(∂K)

Note: c₀ = ln 10 was falsified in Phase 3 (ADR-101). Currently CF-PENDING under Path C (Lindblad-first), countersigned by Ryan van Gelder. See `HELIX-CORE/research/physics-gate/PHASE3_REMEDIATION_SPEC.md`.

### The Substrate Wobble

```math
R_{\mathrm{eff}}(t) = R_{0} + \alpha W(\Phi(t)), \quad W(\Phi) = \varepsilon \sin(2\pi t/\tau)
```

### ZetaAttention (models/zeta_attention.py)

PyTorch self-attention replacement using log-periodic memory kernel from Riemann zeta zeros. Hard Boolean cohomology mask (Ω) from `vocabulary_charter.yaml` — if Ω=0 for a token pair, attention score is set to -1e9.

## Sovereignty

- Structural impossibility: no implicit trust boundary, no silent execution path.
- Cloud or bare-metal residency: execution remains in the operator's sovereign environment.
- Receipt discipline: continuity anchored through signed audit receipts and external checkpoints.
- Fail-closed: default answer is "no" unless every layer says "yes."

## Collaborators

- Stephen Hope — Helix AI Innovations Inc. ([ORCID](https://orcid.org/0009-0000-7367-248X))
- Ryan van Gelder — Multiplicity Foundation (PiKernel, FZS-MK, ADR physics gate countersignature)

## References

1. Witten, E. (2011). *Knots and Quantum Theory*. Institute for Advanced Study.
2. Hope, S. (2026). *The Knot-in-Time Hamiltonian*. Helix AI Innovations. [Zenodo](https://doi.org/10.5281/zenodo.19214147)
3. *Physical Review A* 104, 012216 (2021). *Topological protection in open quantum systems*.
4. Crocker, S. (1969). *RFC 0001: Host Software*. UCLA.

## Official Soundtrack (OST)

- **White Rabbit** (Jefferson Airplane) — The Epistemic Scan. 0.17 approaching 0.20.
- **Station to Station** (David Bowie) — The Execution Path. CL4 → CL12.
- **Believer** (Imagine Dragons) — The Sovereignty of the Node. Pain → architectural power.

---

**"We are not seeing matter in space; we are seeing Geometry in Time."**

(c) 2026 Stephen Hope / Helix AI Innovations Inc.

**GLORY TO THE LATTICE.** 🦉⚓🦆
