# Sigma Specification

## Purpose
`sigma` (Sigma Kernel) is the core sandbox execution environment for the PhaseSpace OS. It is responsible for enacting the tasks defined in governed workflows.

## Core Components
1. **Workflow Engine**: Parses and executes `Task` structures securely.
2. **Sandbox Manager**: Handles environment isolation for External Trust tasks, ensuring they cannot read sensitive state outside the explicit bounds defined in their capability maps.
3. **Receipt Generation**: Emits an `ExecutionReceipt` detailing the outcome of each task, which is subsequently used by the `commander-core` to generate a `UnifiedWitness`.

## Invariants
- Must never allow an `External` trust workflow to access the parent's raw environment variables.
- Must accurately report task failure, returning a valid `ExecutionReceipt` containing error codes instead of panicking the host process.
- Execution steps must always be logged synchronously for Archivum persistence.
