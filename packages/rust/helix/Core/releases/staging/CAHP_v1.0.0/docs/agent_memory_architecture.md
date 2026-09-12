# Updated Agent Architecture Overview

Session timestamp: 2026-01-06 13:36:52

This document describes the core architecture principles:

- **Persistent state** is anchored in `/home/aiadmin/helix-core-unified/helix-ledger/`
- **Active session memory** is ephemeral and stored in RAM
- **Filesystem access** uses absolute paths within the designated directory tree
- **File scope**: All files are within `/home/aiadmin/helix-core-unified/`, primarily under `helix-ledger/` and its subdirectories.
- **Session working directory**: The session operates in `/home/aiadmin/helix-core-unified/helix-ledger/`
- **Change management** involves updating external repositories and files directly

System operates within this structure, ensuring transparency, verifiability, and safety.
