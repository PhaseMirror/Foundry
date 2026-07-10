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
