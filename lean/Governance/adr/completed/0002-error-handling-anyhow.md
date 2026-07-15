# ADR 0002: Error Handling with Anyhow

Status: Accepted
Date: 2026-05-24

## Context
A consistent, robust error handling strategy is required across all crates for maintainability and debugging.

## Decision
`anyhow` will be used for application-level error handling. Custom error types should be defined using `thiserror` for library-level errors.

## Consequences
- Simplified error handling and propagation (`?` operator).
- Improved backtraces and debugging information.
- Clear distinction between library and application errors.
EOF
