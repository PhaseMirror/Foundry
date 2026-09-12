# Arithmetic Gravity

This crate models the De Bruijn–Newman deformation of a prime‑indexed open quantum channel.
A deformation parameter `g` (the “gravitational” strength) changes the phase of the
Kraus operators via

```
θ_p = γ log p + i·max(0, -g)·log p
```

When `g ≥ 0` the channel is strictly contractive; for `g < 0` the contraction can fail
for sufficiently large primes, signalling that zeros leave the critical line.

## Running the Kani proofs

```bash
# Verify contraction for non‑negative gravity
cargo kani --tests --harness verify_contraction_for_non_negative_gravity

# Verify a concrete failure for negative gravity
cargo kani --tests --harness verify_contraction_failure_for_negative_gravity

# Symbolic existence of a prime that breaks contraction for g = -0.1
cargo kani --tests --harness exists_prime_breaking_contraction_for_negative_g
```

**Note:** Kani’s current floating‑point support is partial. For fully rigorous bounds,
replace the `f64` calculations with rational interval arithmetic (see `src/lib.rs` for
the `_rational` helper). The harnesses above demonstrate the logical structure and
will compile and run as symbolic tests in Kani’s abstract domain.
