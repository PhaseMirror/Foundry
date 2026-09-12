# Contributing to Genesis Governance

Welcome to the Genesis ecosystem. This project operates under a **Governed Development Model**. All contributions must respect the **Protected Innovation Budget** and the architectural invariants established in ADR-001 through ADR-011.

## Core Rules

1.  **Immutable Core:** Never modify files in `src/genesis_governance/core/`.
2.  **Quarantine:** All new research (substrates, perturbations) must live in their own modules or exploratory tiers.
3.  **Validation:** Every contribution must pass `make test` and `make test-arch`.
4.  **Provenance:** All artifacts generated during your research must carry a `run_id`, `schema_version`, and your `provenance` metadata.

## Workflow

1.  **Fork and Branch:** Create a feature branch for your research.
2.  **Develop:** Implement your new substrate or perturbation family.
3.  **Interrogate:** Use the `genesis sweep` or `genesis run` commands to generate a `ShrapnelMap`.
4.  **Review:** Run `genesis review --input your_run.json` to generate a Governance Review Packet.
5.  **Submit:** Include the Review Packet and your generated ShrapnelMap in your Pull Request.

## Contributor Scaffold

Use the CLI to generate a template for a new substrate:
```bash
genesis contrib --template substrate --name MyNewSubstrate
```

*Note: The `contrib` command is currently being implemented in v0.5.1-rc.*
