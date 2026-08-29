# Automorphic Learning: Lean 4 Formalization

This directory contains the Lean 4 formalization of the automorphic learning framework.

## Structure

```
automorphic-lean/
├── lakefile.lean              # Lake project configuration
├── Automorphic.lean           # Main module (re-exports all submodules)
└── Automorphic/
    ├── Group.lean             # AGL(1,p) group actions, CRT embeddings, Legendre symbol
    ├── Projection.lean        # Weighted-ℓ₁ projection, KKT certificates, Lipschitz bounds
    ├── Unitary.lean           # Permutation-equivariant unitarization, spectral diagnostics
    └── Tests.lean             # Test harness with examples and proofs
```

## Building

```bash
lake build
```

## Testing

```bash
lake test
```

## Key Theorems

1. **AGL(1,p) Composition Associativity**: `agl_compose_assoc`
2. **CRT Embedding Injectivity**: `crt_embedding_injective`
3. **Softmax Upper Bound**: `softmax_ub_le_half`
4. **Projection Preserves Budget**: `projection_preserves_budget`
5. **Bistochastic Spectral Radius**: `bistochastic_spectral_radius_le_one`

## Proof Status

- [x] Type definitions (complete)
- [ ] Modular arithmetic proofs (sorry placeholders)
- [ ] Real number optimization proofs (sorry placeholders)
- [ ] Matrix exponential properties (sorry placeholders)

## Dependencies

- Lean 4
- Mathlib (optional, for advanced tactics)

## License

MIT
