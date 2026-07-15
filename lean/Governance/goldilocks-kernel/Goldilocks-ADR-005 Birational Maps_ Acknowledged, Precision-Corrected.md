<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

## Birational Maps: Acknowledged, Precision-Corrected, and Deferred

Your analysis of the birational equivalence between Twisted Edwards (JubJub), Montgomery, and short Weierstrass (Pallas) is **mathematically correct** and the maps you've documented are the standard transformations from the Bernstein et al. literature. However, there is a **critical architectural misalignment** that needs correction before we proceed.

### The Fundamental Issue: Field Mismatch

**JubJub and Pallas operate over different base fields.** They are not directly interconvertible via birational maps because the maps are only valid **over the same field**.


| Curve | Base Field | Scalar Field (Group Order) | Native Form |
| :-- | :-- | :-- | :-- |
| **JubJub** | BLS12-381 scalar field (`q_bls12 = 0x73eda753...`) | `r_jubjub = 0x0e7db4ea...` | Twisted Edwards |
| **Pallas** | Pallas base field (`p_pallas = 0x40000000...`) | Vesta base field (= Pallas scalar field) | Short Weierstrass |

**The consequence:** You **cannot** convert a JubJub point to a Pallas point via a birational map, because they live in different fields. The map formulas require division and inversion operations that are only defined within a single field. `1 + v` in the BLS12-381 field is not the same as `1 + v` in the Pallas field.

What you **can** do:

- Convert between coordinate representations of the **same curve** over the **same field**. For example, if you have a Twisted Edwards curve over the Pallas field, you can convert it to Montgomery or Weierstrass **over the Pallas field** using the birational maps.
- Use **curve cycles** like Pallas/Vesta (where Pallas scalar field = Vesta base field) to enable recursive proof composition without leaving the field tower. But this is not a birational map—it's an embedding via field isomorphism.


### What This Means for Our Stack

The clean separation is:

1. **If we use JubJub** (Twisted Edwards over BLS12-381 scalar field), we are committing to the **BLS12-381 pairing-friendly ecosystem** (Groth16, Halo2 with BN254/BLS12-381 backend). This is orthogonal to Pallas/Vesta (which use the Pasta curve cycle) and orthogonal to Goldilocks (which is a 64-bit native field for Plonky3).
2. **If we use Pallas/Vesta** (short Weierstrass over their respective 254-bit fields), we can optionally define a **Twisted Edwards model of Pallas over the Pallas field**. This would give us the complete addition law advantages inside Plonky3 circuits that use Pallas as an EC layer. But this is **not the same curve as JubJub**—it's a Pallas-native Edwards curve.
3. **Goldilocks remains the runtime field** for all hot-path operations (`delta_pz`, resonance amplitudes, prime masks, Hamiltonian eigenvalues). EC operations (JubJub or Pallas) are proof-time only, in the limbized big-int cold path.

### The Correct Decision Tree for EC Layer Selection

```
What proof system are we using for the commitment layer?
├─ Plonky3 (Goldilocks-native)
│  └─ Do we need EC commitments inside witnesses?
│     ├─ NO → No EC layer needed (stay in 𝔽_Gold)
│     └─ YES → Use Pallas/Vesta (254-bit, matches Plonky3 security level)
│        └─ Optimize circuit efficiency?
│           ├─ Later → Use Weierstrass Pallas (current default)
│           └─ Now → Define Twisted Edwards model of Pallas over p_pallas
│
├─ Halo2 (pairing-based, BLS12-381 backend)
│  └─ Use JubJub (Twisted Edwards over BLS12-381 scalar field)
│
└─ Groth16 (pairing-based, BN254 backend)
   └─ Use Baby JubJub (Twisted Edwards over BN254 scalar field)
```

**Key insight:** The choice of EC curve is **downstream of the proof system choice**, not the other way around. If we're using Plonky3 (Goldilocks-native), the natural EC layer is Pallas/Vesta. If we're using Halo2 (BLS12-381 backend), the natural EC layer is JubJub. Mixing them requires a cross-system bridge (e.g., verifying a Halo2 proof inside a Plonky3 circuit), which is a future extension, not a v1.0 requirement.

### Why This Clarification Matters

The birational maps you documented are **correct for converting between models of the same curve over the same field**. But the narrative that we can "freely convert points between JubJub and Pallas" is **incorrect** because they're over different fields. This is not a subtle point—it's a hard mathematical boundary.

**Example:**

- A Pedersen commitment to a resonance word computed on JubJub (Twisted Edwards over BLS12-381 scalar field) produces a point `(u, v)` in that field.
- To verify this commitment inside a Plonky3 circuit (over Goldilocks), you would need to **encode the field elements** `u` and `v` as multiple Goldilocks elements (since 255 bits > 64 bits), then verify the Pedersen relation using non-native field arithmetic. This is expensive but feasible.
- You **cannot** "convert" the JubJub point to a Pallas point via a birational map because they live in different fields.

**Correct approach if we need to verify a JubJub commitment in Plonky3:**

1. Compute the commitment on JubJub (outside the circuit).
2. Serialize the point coordinates as bytes.
3. Inside the Plonky3 circuit, reconstruct the field elements using non-native arithmetic (split each 255-bit coordinate into multiple 64-bit Goldilocks elements).
4. Verify the Pedersen relation using the JubJub group law constraints (complete addition formula in Twisted Edwards).
5. Accept the circuit overhead (10-100× cost compared to native Goldilocks arithmetic).

This is the **cross-system bridge cost**. It's why we default to Pallas/Vesta (same security level as Goldilocks-based Plonky3) rather than JubJub (BLS12-381 ecosystem) unless we have a specific reason to verify Halo2 proofs.

### Corrected Recommendation: Pallas-Native Twisted Edwards

If we want the circuit efficiency benefits of Twisted Edwards **without leaving the Pallas/Vesta/Goldilocks ecosystem**, the correct path is:

1. **Define a Twisted Edwards model of Pallas** over the Pallas base field (`p_pallas = 0x40000000...`).
2. Compute the birational map parameters `(a, d)` from the Weierstrass parameters `(A=0, B=5)` using the inverse transformation.
3. Represent EC commitments (Pedersen, MSM) in Twisted Edwards coordinates inside the Plonky3 circuit (complete addition law → fewer constraints).
4. The generator point is the birationally mapped image of the Weierstrass Pallas generator.
5. External tools (Halo2 libraries, signatures) can still use Weierstrass coordinates; the conversion happens at the witness boundary.

**This is a Pallas-internal optimization, not a cross-curve conversion.** It preserves the field consistency (all operations in `p_pallas` or Goldilocks) and avoids the non-native arithmetic overhead.

### What I Will Not Document (Because It's Misleading)

I will **not** write a spec that says "convert JubJub points to Pallas points via birational maps" because that is **mathematically incorrect**. The maps only work within a single field. JubJub (BLS12-381 scalar field) and Pallas (Pallas base field) are different fields, so the maps don't apply.

### What I Will Document (If You Approve This Path)

**Option 1 (Recommended):** `pallas-twisted-edwards.md`

- Define the Twisted Edwards model of Pallas over `p_pallas`.
- Document the birational map from Weierstrass Pallas to Edwards Pallas (same curve, different coordinates).
- Provide the complete addition formulas for the Edwards model.
- Show the generator point in both Weierstrass and Edwards coordinates.
- Explain when to use this (Plonky3 circuits with EC commitments) vs. when to use Weierstrass (external APIs, Halo2 compatibility).
- **No mention of JubJub** because it's a different curve over a different field.

**Option 2 (If cross-system bridge is needed):** `cross-curve-bridges.md`

- Document how to verify a JubJub commitment inside a Plonky3 circuit using non-native field arithmetic.
- Estimate the circuit overhead (10-100× cost).
- Explain when this is necessary (verifying Halo2 proofs inside Plonky3, cross-chain interoperability).
- **Clarify that this is not a birational map**—it's a non-native field embedding.

**Option 3 (Deferred, as I recommended earlier):** No EC curve spec at all until after AZ-TFTC simulation, because EC commitments are optional in v1.0.

### My Strong Recommendation (Unchanged)

**Defer all EC curve specifications** (Pallas Weierstrass, Pallas Twisted Edwards, JubJub, cross-system bridges) until after:

1. Track B (48 hours): Witness-sealing fix.
2. Levers 2–6 (7 days): Goldilocks-native spec files.
3. AZ-TFTC simulation (first end-to-end proof with scalar Goldilocks kernel).

**Reason:** EC commitments are not on the critical path for the first spectral certification proof. The initial Plonky3 public inputs are pure Goldilocks field elements (`lambda_m`, `rho_bound`, `delta_pz`), with no EC operations. Adding EC layers before we've proven the baseline system works is premature optimization.

**If you override this recommendation** and want an EC spec now, I will deliver **Option 1 (Pallas-native Twisted Edwards)** because it's the only option that respects the field consistency requirement and avoids misleading cross-field conversions.

### Your Decision Point

Pick one:

**A. Proceed with critical path (recommended):** Draft ADR-003 (witness fix) + Lever 2 (prime indexing). Defer all EC specs to post-AZ-TFTC.

**B. Add EC layer now:** I will draft `pallas-twisted-edwards.md` (Option 1 above) with the corrected understanding that this is a Pallas-internal coordinate transformation, not a JubJub-to-Pallas conversion.

**C. Cross-system bridge investigation:** I will draft `cross-curve-bridges.md` (Option 2 above) explaining the non-native arithmetic cost of verifying JubJub commitments in Plonky3, but this is a research document, not an implementation spec.

I will execute whichever path you choose, but my recommendation remains **A (critical path)**. The birational map investigation was valuable for understanding the design space, but it revealed that JubJub and Pallas are **not interchangeable** without non-native field arithmetic overhead, which reinforces the defer decision.

What's your call?

