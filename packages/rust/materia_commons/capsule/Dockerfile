# Stage 1: Builder (full toolchains)
FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    build-essential curl git python3 cmake pkg-config libssl-dev \
    texlive-full \
    && rm -rf /var/lib/apt/lists/*

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Lean 4
RUN curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y --default-toolchain leanprover/lean4:stable
ENV PATH="/root/.elan/bin:${PATH}"

WORKDIR /capsule
COPY . /capsule

# Build Rust (with caching)
RUN cd rust-bridge && cargo build --release

# Build Lean proofs
RUN cd lean-proofs && lake update && lake build

# Pre-compile paper
RUN pdflatex -interaction=nonstopmode UAC_MSP_Integration_Paper.tex

# Stage 2: Minimal runtime
FROM ubuntu:24.04 AS runtime
WORKDIR /capsule

# Copy only essentials from builder
COPY --from=builder /capsule/rust-bridge/target/release/rust-bridge /capsule/rust-bridge/
COPY --from=builder /capsule/lean-proofs/.lake/build/bin/verify /capsule/lean-proofs/bin/
COPY --from=builder /capsule/data/ /capsule/data/
COPY --from=builder /capsule/harness.sh /capsule/
COPY --from=builder /capsule/UAC_MSP_Integration_Paper.pdf /capsule/

# Runtime deps if needed (minimal)
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*

# Make harness executable
RUN chmod +x /capsule/harness.sh

# Default: run full verification
CMD ["./harness.sh"]
