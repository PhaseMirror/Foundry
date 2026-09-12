# ADR-102: Missing Object Formalization (Spec ℤ ×_{𝔽₁} Spec ℤ)

## Status
Accepted (v0.17.0–v0.21.0 shipped; crux localized at v0.21.0)

## Context
Over function fields, RH is a theorem because the Frobenius acts on étale cohomology and a positivity (Rosati/Weil) confines its eigenvalues to the critical circle. Over ℚ the analogous object is missing — `Spec ℤ` is already the base, so there is no lower geometry to take cohomology relative to. The Arithmetic Site (Connes–Consani, 2014–2021) built the 1-dimensional curve `Spec ℤ/𝔽₁` and its scaling flow; the 2-dimensional square with intersection theory is **not built**.

Two attacks — analytic (Li's `λₙ ≥ 0`) and geometric (Hodge index on `C × C`) — **converge** to a single statement: the missing object is the arithmetic surface `Spec ℤ ×_{𝔽₁} Spec ℤ` equipped with a Hodge index theorem (negative-definiteness of its intersection pairing on `H^⊥`). That negative-definiteness is simultaneously the analytic positivity, the prime-oscillation cancellation, and the spectral confinement.

## Decision

### 1. Named Target
Declare the **single missing object**:
```
𝕊 = Spec ℤ ×_{𝔽₁} Spec ℤ
```
with:
- Two projections recovering the arithmetic-site curve (`𝕊 → Spec ℤ/𝔽₁`).
- A divisor group `Div(𝕊)` and class group `Cl(𝕊) = Div(𝕊)/∼`, finitely generated.
- Distinguished classes: two fiber rulings `F_h, F_v`, diagonal `Δ`, graph classes `Γ_n` of the scaling/Frobenius maps `Fr_n`.
- An intrinsic intersection pairing `⟨·,·⟩ : Cl × Cl → ℝ` with product-surface boundary conditions: `⟨F_h,F_v⟩=1`, `⟨F_h,F_h⟩=⟨F_v,F_v⟩=0`, `⟨Δ,F_h⟩=⟨Δ,F_v⟩=1`.
- A Hodge index theorem: the pairing is negative-definite on `H^⊥` for an ample class `H`.

### 2. Three Obstructions (named exactly)
1. **Place asymmetry.** ℚ places include primes (non-archimedean) + ℝ (archimedean); no Frobenius at the archimedean place.
2. **No geometry under Spec ℤ.** A curve sits *over* `𝔽_q`; `Spec ℤ` is the base — unless made "a curve over `𝔽₁`" via characteristic-1 idempotence.
3. **Finite → infinite.** Function-field zeta has finitely many zeros (finite-dimensional operator); `ζ` has infinitely many — requires infinite-dimensional self-adjoint operator (Hilbert–Pólya).

### 3. Verification Ladder (T1–T5)
| rung | requirement | status entering v0.21.0 |
|---|---|---|
| T1 | 2-dimensional over `𝔽₁` | verified at point-set level (finite Deitmar product) |
| T2 | class group + distinguished classes | verified (rulings, diagonal, scaling graphs) |
| T3 | intersection pairing reproducing boundary numbers | partial (template sourced, not intrinsic) |
| T4 | H¹ / trace identity (Hilbert–Pólya) | open constraint |
| T5 | Hodge index = RH | **none** (the crux) |

### 4. v0.20.0 Bridge (dictionary forced)
`⟨Cₙ,Cₙ⟩ = −2λₙ` is no longer an interface field but a **theorem** (`intrinsicH1_dict`), derived from a genuine rank-4 Néron–Severi-style lattice (`WeilLattice.lean`) with vanishing cycle `Δ−Γ` proven primitive.

### 5. v0.21.0 Atlas & Localization
The UOR Atlas (`AtlasSpectrum`, `AtlasRules`, `GaugeTower`, `StageG`) was formalized and the gate ran. The forced signature did **not** come out positive — `genuine_crux_frontier_located` pins the frontier. Posture: **LOCALIZED**. `hodgeIndexHolds` / `liPositivityHolds` stay `none`.

### 6. Bright Line (permanent)
`hodgeIndexHolds` / `liPositivityHolds` flip `none → some true` **iff** a genuine, audited, axiom-clean proof of the universal lands. Anything short stays an explicit interface. The gate decides what is asserted, not ambition.

## Consequences
- All F1-Square surface probes (Deitmar product, blueprint square, tropical approximations) are **falsifiable** against T1–T5.
- The honest boundary makes overclaiming impossible: the ledger records exactly what is proven, assumed, and open.
- v0.22.0 carries frontier research (Sonine projection, discharged interfaces) **to exhaustion** — until crux closes or the work is judged complete to publish.
- The convergence of attacks 1 and 2 (Li cancellation = Hodge negativity) is a theorem about the problem structure, not partial progress.

## References
- `Prime/missing_object_over_Q.md`
- `Prime/f1_square_intersection_theory.md`
- `Prime/F1Square Lean Formalization.md`
- `Prime/Formal F1-Square Conditional Riemann Proof.md`
- `ROADMAP.md` (v0.15.0–v0.22.0 stages)
- `docs/adr/ADR-001-Combined-Mandate.md`
- `docs/adr/ADR-013-F1-Square-Signature-Check.md`
