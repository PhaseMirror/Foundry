# key-vault-rs: Secure Secret Management

Threshold secret sharing and encrypted seed storage for Multiplicity actors.

## Features
- **Shamir Secret Sharing**: $(k, n)$ threshold sharing over $GF(256)$ with optimized generator.
- **Seed Vault**: AES-256-GCM encryption with HKDF-SHA256 key derivation.
- **Serialized Parity**: Matches the TypeScript reference implementation for cross-platform interop.

## Verification
```bash
cargo test
```
