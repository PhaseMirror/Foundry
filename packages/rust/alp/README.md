# alp-rs: Atomic Language Processing

High-performance Rust implementation of the ALP (Atomic Language Processing) protocol.

## Features
- **Grapheme Decomposition**: Exact Unicode grapheme-cluster segmentation using `unicode-segmentation`.
- **Prime-Indexed Mapping**: Deterministic allocation of prime moduli to unique graphemes.
- **PETC Construction**: Generates Prime-Encoded Tensor Calculation (PETC) signatures for language units.
- **Reversibility**: Guarantees that `reassemble(decompose(s)) == s` for all Unicode strings.

## Usage
### Build
```bash
cargo build --release
```

### Test
```bash
cargo test
```

## Contracts
Aligned with **ADR-091: L1 Grapheme Decomposition**.
- **INV-M04-1**: Same grapheme → same prime modulus.
- **INV-M04-2**: Reversibility.
- **INV-M04-3**: Full Unicode 15.0 support.
