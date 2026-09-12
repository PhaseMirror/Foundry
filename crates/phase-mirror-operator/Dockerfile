# syntax=docker/dockerfile:1
# ── Build Stage ──────────────────────────────────────────────
FROM rust:1.78-slim-bookworm AS builder

RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/phase-mirror
COPY . .

# We only build the operator binary to keep the cache lean
RUN cargo build --release --bin phase-mirror-operator

# ── Runtime Stage ────────────────────────────────────────────
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/phase-mirror/target/release/phase-mirror-operator /usr/local/bin/phase-mirror-operator

# WebSocket/metrics port (we’ll bind inside the operator)
EXPOSE 3030

USER 1000:1000
ENTRYPOINT ["phase-mirror-operator"]
