# ADR 0001: Async Runtime Choice: Tokio

Status: Accepted
Date: 2026-05-24

## Context
The migration requires a high-performance asynchronous runtime to support concurrent agent operations, mTLS handshakes, and transport bridging.

## Decision
Tokio has been chosen as the primary asynchronous runtime for all Rust components in this project.

## Consequences
- High performance and scalability.
- Extensive ecosystem support.
- Increased complexity compared to synchronous code.
EOF
