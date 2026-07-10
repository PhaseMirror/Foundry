# syntax=docker/dockerfile:1.4
# Stage 1: Build the Rust MCP server
FROM rust:1.85-bookworm AS builder
WORKDIR /build
COPY . /build
RUN cargo build --release -p pscmd

# Stage 2: Python runtime with the binary and evaluation script
FROM python:3.12-slim
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the compiled MCP server binary
COPY --from=builder /build/target/release/pscmd /usr/local/bin/pscmd

# Copy the action entrypoint and evaluation script
COPY entrypoint.sh evaluate.py ./
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
