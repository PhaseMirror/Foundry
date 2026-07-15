# State

This folder is the canonical PMD live-state organ referenced by ADR-022 and elevated in ADR-027 Wave 3.

It holds the runtime state surfaces that the canonical PMD packages read and update:

- `live_state.yaml` is the authoritative local snapshot of current Tooling PMD runtime state
- `epoch_index.yaml` tracks the active digital twin snapshot and snapshot history
- `dht/` remains available for adjacent state-distribution or indexing experiments without replacing the canonical local state files

In PMD terms, `state/` is the persistent substrate beneath `digital_twin/`, `rollback/`, and `daemon/`. It is the source of truth for current local runtime state, not a simulation or historical archive.