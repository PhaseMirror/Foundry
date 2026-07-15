<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# **Decision: Option A (Critical Path First).**

Thank you for the precision correction — it is exactly right and materially important.

JubJub lives over the BLS12-381 scalar field ($q_\\text{BLS12}$).
Pallas lives over its own 254-bit base field ($p_\\text{Pallas}$).
The birational maps are **intra-curve** coordinate transformations only; they do **not** cross fields. Any attempt to treat JubJub points as Pallas points via birational maps would be mathematically invalid and would silently produce incorrect group elements.

I accept the correction without reservation. The narrative I previously sketched (free conversion between JubJub and Pallas) is withdrawn.

### Updated Architectural Commitment (Locked In)

- **Canonical runtime / Plonky3 field**: $\\mathbb{F}_{\\mathrm{Gold}}$ (64-bit) — unchanged and non-negotiable (ADR-004).
- **EC layer (if needed at all)**: Pallas/Vesta (254-bit, cycle-native to Plonky3 security level and recursion).
- **JubJub**: Explicitly scoped to BLS12-381 / Halo2 / Groth16 ecosystems. It is **not** part of the Pro-tier Plonky3 path unless we later add a non-native field bridge (which we are deferring).
- **Twisted Edwards optimization**: If we ever need the complete addition law inside Plonky3, we will define a **Pallas-native** Twisted Edwards model over $p_\\text{Pallas}$ (Option 1). No cross-field mixing in v1.0.

EC commitments (Pedersen on SpectralWitness, resonance words, prime masks, etc.) are **not** required for the first end-to-end spectral veto proof. The initial `ConvergencePublicInputsPro` and `AceAir` constraints are pure Goldilocks field elements (`delta_pz_fp`, `delta_pz_floor_fp`, resonance words, prime masks). Adding an EC layer now would be premature optimization.

### Immediate Next Action (Critical Path)

We stay on the 64-bit unification rails that were already in flight.

I will now deliver the next two artifacts in sequence:

1. **Lever 2 — Prime-Gated Indexing** (`prime_indexing.md`) — full normative spec with the 64-local-prime basis, u64 mask semantics (AND/OR/XOR), PrimeWitness structure, and circom integration points.
2. **Lever 3 — Resonance Encoding** (`resonance_word_64.md`) — the exact 6-bit R96 + 58-bit payload packing we already prototyped, plus the canonical injection $\\Phi$ from the Digital Resonance Model / Tetrahedral Rhythm invariants.

Once those land (today), we can immediately close Lever 4 (Hamiltonian_64) and run the first AZ-TFTC 1D simulation in native Goldilocks to validate the spectral gap constraint end-to-end.

**Deferral of all EC specs** (Pallas-native Edwards, cross-system bridges, JubJub, etc.) is now locked until **after**:

- Witness-sealing fix (48 h)
- Full Goldilocks-native spec bundle (7 days)
- First AZ-TFTC + spectral veto proof in Plonky3

This keeps us aligned with the original ADR-013 structural research phase and the Two-Key Spectral Veto implementation plan you started with.

Ready when you are — shall I emit the full `prime_indexing.md` + `resonance_word_64.md` bundle right now?

Yes — emit them now. Your corrected commitment cleanly locks the critical path: Goldilocks remains the canonical runtime and Plonky3 field, while JubJub and any cross-field EC bridge work stay deferred; Plonky3’s Goldilocks field support, the Pasta curve family, and Jubjub’s BLS12-381 placement all align with that separation.[^1][^2][^3][^4]

## Sequence

The right next move is exactly the two-artifact bundle you named: `prime_indexing.md` first, then `resonance_word_64.md`. That keeps Lever 2 and Lever 3 on the same 64-bit rail as the already-locked Goldilocks kernel and avoids introducing any non-native arithmetic before the first AZ-TFTC proof path is validated.[^5][^4][^1]

After those two land, Lever 4 can be written against fixed mask semantics and fixed resonance encoding, which is the correct dependency order for the first 1D simulation. That sequencing is also consistent with the separation between Goldilocks-native proving flow and any later Pasta-curve or Halo2-related extensions.[^2][^6][^7]

## Scope lock

The deferral is now well-formed:

- Goldilocks for runtime state, resonance words, `delta_pz_fp`, masks, and Plonky3 public inputs.[^4][^1][^5]
- Pallas/Vesta only as a future optional EC layer inside the proof/cert path, not the runtime kernel.[^7][^8][^2]
- Jubjub confined to the BLS12-381 ecosystem unless a non-native bridge is later justified and explicitly designed.[^3]

That means the current bundle should stay purely field-native and document only:

- 64-local-prime basis and mask algebra.
- Canonical packing/injection rules for resonance words.
- Circom/Plonky3-facing interfaces as field elements and bitmasks, not EC points.[^1][^4]


## Recommendation

Proceed with the full `prime_indexing.md` + `resonance_word_64.md` bundle **right now**. The only discipline to keep is that both documents should be written as normative specs, with no speculative EC hooks beyond explicit “deferred” notes, because the first proof target is still pure Goldilocks.[^2][^3][^1]

Start with `prime_indexing.md`, lock the mask semantics and `PrimeWitness` structure, then let `resonance_word_64.md` consume that basis as an already-fixed substrate.
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^17][^18][^19][^20][^21][^22][^23][^24][^25][^26][^27][^9]</span>

<div align="center">⁂</div>

[^1]: https://github.com/Plonky3/Plonky3/tree/main/goldilocks

[^2]: https://github.com/zcash/pasta

[^3]: https://bitzecbzc.github.io/technology/jubjub/index.html

[^4]: https://polygon.technology/blog/polygon-plonky3-the-next-generation-of-zk-proving-systems-is-production-ready

[^5]: https://crates.io/crates/p3-goldilocks

[^6]: https://github.com/zcash/pasta_curves/blob/main/README.md

[^7]: https://z.cash/the-pasta-curves-for-halo-2-and-beyond/

[^8]: https://zcash.github.io/halo2/design/implementation/fields.html

[^9]: https://github.com/Plonky3/Plonky3/blob/main/README.md

[^10]: https://github.com/Plonky3/Plonky3

[^11]: https://github.com/0xPolygonZero/plonky2/blob/main/field/src/goldilocks_field.rs

[^12]: https://github.com/BrianSeong99/plonky3_rangecheck

[^13]: https://github.com/ConsenSys/gnark-crypto/blob/master/ecc/ecc.md

[^14]: https://github.com/telosnetwork/Plonky3

[^15]: https://github.com/nccgroup/pasta-curves

[^16]: https://github.com/filecoin-project/research/issues/53

[^17]: https://github.com/axiom-crypto/Plonky3/pull/3

[^18]: https://github.com/zcash/pasta/blob/master/README.md

[^19]: https://github.com/filecoin-project/rust-fil-proofs/issues/1005

[^20]: https://github.com/succinctlabs/plonky3/blob/main/README.md

[^21]: https://lita.gitbook.io/lita-documentation/architecture/proving-system-plonky3

[^22]: https://hackmd.io/@Voidkai/BkNX3xUZA

[^23]: https://blog.icme.io/small-fields-for-zero-knowledge/

[^24]: https://github.com/zcash/zcash/issues/2502

[^25]: https://x.com/0xPolygonFdn/status/1814330446894760042

[^26]: https://www.reddit.com/r/crypto/comments/prs8qf/bandersnatch_a_fast_elliptic_curve_built_over_the/

[^27]: https://leastauthority.com/wp-content/uploads/2024/11/Updated_071124_Polygon_Plonky3_Final_Audit_Report.pdf

