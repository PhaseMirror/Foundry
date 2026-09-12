# Prime / Materia Commons

This directory contains the operational and governance tooling for the Multiplicity Sovereign Core, primarily written in Rust.

## Overview

The Materia Commons houses the components required for the PhaseSpace Commander, MCP servers, and agent policies. It acts as the orchestration and integration layer between the Prime core and external agents.

### Components

- `agents/`: Implementations of autonomous agents operating within the Sedona Spine boundaries.
- `capsule/`: Encapsulated runtime or data structures.
- `mcp_server/`: The Model Context Protocol (MCP) server providing external AI models access to the Prime ecosystem via strict policy gates.
- `meta-theorem/`: The Lean 4 formal mathematical ground truth (MTPI), governing prime gating and maximum drift bounds across the commons.
- `operator-atlas/`: The operational map and directory of Multiplicity actors and contracts.
- `policy/`: Core policy definitions aligning with the `ALP` engine constraints.
- `pirtm-vscode/`: VSCode extensions or tooling for PIRTM integration.
- `schemas/`: Data schemas for validation and communication.
- `state/`: State management for the tools in this directory.

All tools and servers in this directory are bound by the **Consciousness-First Protocol (CFP)** and must route through the `ALP` policy gate before spawning any process or mutating state.
