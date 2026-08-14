# Prime ABI v0: Final Specification & Conformance Suite

**Document Status**: Stable  
**ABI Name**: `prime-abi-v0`  
**Style**: Host Buffers (ABI A)  
**Determinism Core**: Canonical CBOR (RFC 8949) + Fuel-Based Execution

## 1. Deterministic CBOR: Critical Implementation Notes

The RFC 8949 "core deterministic encoding" requirements (Section 4.2.1) are non-negotiable. For implementers, this means:

**Host MUST reject at ingress:**
- Indefinite-length items
- Non-minimal integer encodings (e.g., `0x1800` for `0x00`)
- Duplicate map keys
- Non-sorted map keys when `canonical=True` is specified
- Floating-point values not using the shortest form that preserves the value

## 2. Wasmtime Configuration for Determinism
See implementation in `crates/archivum-core/src/lib.rs`.
- `consume_fuel(true)`
- `epoch_interruption(false)`
- SIMD and relaxed SIMD disabled
- Bulk memory enabled

## 3. Prime Module Validation Checklist
Before accepting any module, hosts must verify:
1. Byte-for-byte module hash matches registry entry
2. `prime_info` output matches expected manifest
3. Determinism flags are truthful

## 4. Conformance Test Vector Specification
**File Format**: Canonical CBOR (`.cbor` extension)
**Naming**: `test-{id}-{description}.cbor`
**Hash Companion**: `.hash` containing BLAKE3 hash
