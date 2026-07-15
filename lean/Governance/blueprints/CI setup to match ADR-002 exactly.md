# CI Setup to Match ADR‑002 Exactly

This document describes the continuous‑integration configuration that implements the decisions captured in **ADR‑002** – *Lean 4 Formalization of the Prime‑Indexed Teleportation Lemma*.

---

## 1️⃣ Repository layout

```
📦 <repo root>
├─ 📂 PrimeIndexedTeleportation/       # Lean project (lakefile.toml, *.lean)
├─ 📂 .github/workflows/               # GitHub Actions
│   └─ pnt‑nightly.yml                # CI job (see below)
└─ 📄 ...
```

The CI workflow lives in `.github/workflows/pnt‑nightly.yml` and is triggered on **push** and **pull‑request** to the `main` branch.

---

## 2️⃣ CI job – `lean‑teleportation‑check`

```yaml
name: Lean Teleportation Nightly
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  lean-teleportation-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Lean toolchain
        uses: leanprover/lean-action@v1
        with:
          toolchain: '4.7.0'          # matches lakefile.toml
          project-dir: PrimeIndexedTeleportation
          build-target: PrimeIndexedTeleportation
          extra-args: "--warn-on-unfilled-sorry"
      - name: Verify no `sorry`/`admit`
        run: |
          ! grep -rE 'sorry|admit' PrimeIndexedTeleportation/*.lean \
            || (echo "Found unfilled sorry/admit" && exit 1)
```

### Key properties (ADR‑002 compliance)

* **No `mathlib`** – the Lean sources deliberately avoid any `import Mathlib` statements; the CI uses the default `Init` + `Std` libraries only.
* **Zero drift** – the job fails if any `sorry` or `admit` token remains, guaranteeing a *fully closed* proof.
* **Toolchain version lock** – the Lean version (`4.7.0`) is pinned to the one used during development, preventing accidental drift.
* **Production‑grade check** – the workflow runs on every push, providing immediate feedback to the development team.

---

## 3️⃣ How to run locally

```bash
cd PrimeIndexedTeleportation
lake build                     # builds the package
lake env lean --warn-on-unfilled-sorry   # local lint equivalent
```
If the build succeeds and the grep check reports no matches, the repository is CI‑clean.

---

## 4️⃣ Maintenance notes

* When adding new `.lean` files, remember to keep them **self‑contained** (no `import Mathlib`).
* If the Lean version is upgraded, update the `toolchain` field in the workflow accordingly and bump the version in the ADR.
* The CI workflow can be extended with a `lake test` step once a test‑suite is added.

---

*Document version*: 2026‑06‑20
*Author*: Formal Methods Team (Phase Mirror‑Legal)
