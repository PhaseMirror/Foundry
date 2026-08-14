# Prime / State

This directory is the immutable ledger for the Prime Materia Commons.

## Overview

The `state/` directory is used to persist critical operational data that must be auditable and immutable. The most important component here is the `archivum/`.

### Archivum

The `archivum/` sub-directory serves as the governance ledger. According to the **Consciousness-First Protocol (CFP)**:
- Every execution, tool call, and policy gate check produces exactly one `UnifiedWitness`.
- These witnesses are recorded locally in the Archivum (e.g., `witnesses.jsonl`).
- The contents of this directory are automatically committed to Git to provide a cryptographically secure, immutable audit trail of the system's operational history.

This directory must never be manually edited or purged outside of officially sanctioned governance protocols.

## PMD Live-State Organ

This folder also serves as the canonical PMD live-state organ referenced by ADR-022 and elevated in ADR-027 Wave 3.
It holds the runtime state surfaces that the canonical PMD packages read and update:

- `live_state.yaml` is the authoritative local snapshot of current Tooling PMD runtime state
- `epoch_index.yaml` tracks the active digital twin snapshot and snapshot history
- `dht/` remains available for adjacent state-distribution or indexing experiments without replacing the canonical local state files

In PMD terms, `state/` is the persistent substrate beneath `digital_twin/`, `rollback/`, and `daemon/`. It is the source of truth for current local runtime state, not a simulation or historical archive.
