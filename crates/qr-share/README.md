# qr-share-rs: Multi-Frame QR Sharing

High-performance Rust implementation of the multi-frame QR code sharing protocol for the Multiplicity substrate.

## Features
- **Frame Protocol**: Implements the `LP2` multi-frame version for splitting large payloads into chunks suitable for QR transport.
- **Aggregator**: Robust reassembly engine with checksum validation (CRC32) and missing-chunk tracking.
- **Type Safety**: Fully typed `Frame` structures using `serde`.
- **Integrity**: Built-in CRC32 checksums for both individual chunks and full payloads.

## Usage
### Build
```bash
cargo build --release
```

### Test
```bash
cargo test
```
