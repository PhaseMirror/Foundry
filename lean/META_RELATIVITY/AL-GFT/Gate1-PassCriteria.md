# Gate 1 Phased Development Plan

## Governing contract

Gate 1 requires: derive $C_2(k)$ and $C_3(k_1,k_2,k_3)$ from a specified microscopic multiplicity model using standard coarse-graining techniques, yielding explicit functional forms where all free parameters map to quantum-geometric quantities.  The current status is **"framework specified, derivation in progress."**  This plan moves it to **"Gaussian branch passed, with explicit derivation and code."**[^3][^1]

***

## Phase 0 — Repo setup and document relabeling (Day 1)

### Instructions

1. Create repo `CEQG-RG-Langevin/` with the directory structure from the README.[^1]
2. Copy `algftgate1.py` into `src/` as the **baseline reference implementation**.[^2]
3. Add the LaTeX template (`AL-GFT-Gate1-TrackA-SK.tex`) into `docs/`.
4. Relabel all existing AL-GFT documents with the header: "**Gate 1: Framework specified, derivation in progress.**"[^1]
5. Create `docs/Gate1-PassCriteria.md` (this document).

### Deliverables

| File | Purpose |
| :-- | :-- |
| `src/algftgate1.py` | Baseline phenomenological AL-GFT (unchanged) [^2] |
| `docs/AL-GFT-Gate1-TrackA-SK.tex` | LaTeX derivation note (skeleton) |
| `docs/Gate1-PassCriteria.md` | This plan + pass/fail checklist |

### Exit criterion

Repo compiles, `algftgate1.py` runs and produces $P_\zeta(k)$ with Zeta-Comb modulation.[^2]

***

## Phase 1 — Schwinger-Keldysh derivation of $S_{\text{IF}}$ and $N(k)$ (Weeks 1–2)

### Goal

Analytically derive the Feynman–Vernon influence functional for the AL-GFT environment and extract the noise kernel $N(k)$, showing it has the Zeta-Comb structure.[^3][^1]

### Step-by-step instructions

1. **Fix notation (Day 1–2).** In the LaTeX note, write down the total action $S_{\text{tot}} = S_{\text{sys}}[\zeta] + S_{\text{env}}[\phi] + S_{\text{int}}[\zeta,\phi]$ on FLRW in Fourier space. Use the conventions already established:
    - System: quadratic Starobinsky-like action for $\zeta_{\boldsymbol{k}}(\eta)$.[^3]
    - Environment: tower of modes $\phi_{n,\boldsymbol{k}}$ with dispersion $\Omega_n^2 = \omega_n^2 + k^2$.[^2]
    - Interaction: linear coupling $S_{\text{int}} = \int d\eta\, d^3k\; a^2 \zeta_{\boldsymbol{k}} \mathcal{O}_{-\boldsymbol{k}}$, with $\mathcal{O}_{\boldsymbol{k}} = \sum_n g_n \phi_{n,\boldsymbol{k}}$.[^3]
    - Environment state: Gaussian $\rho_{\text{env}} \propto \exp(-\sum \beta_n |\phi_n|^2)$. [^3]
2. **Write the CTP path integral (Day 2–3).** Double the fields ($\zeta_\pm, \phi_\pm$), write $Z[J_+,J_-]$, and identify the Gaussian $\phi$-integral.[^3]
3. **Perform the Gaussian trace (Day 3–5).** Since $S_{\text{env}} + S_{\text{int}}$ is quadratic in $\phi$, the trace over $\phi_\pm$ yields the influence functional $\mathcal{F} = e^{iS_{\text{IF}}}$. Extract the standard Feynman–Vernon form in terms of $\zeta_c, \zeta_\Delta$:

$$
S_{\text{IF}} = \int d\eta\, d\eta'\, d^3k \left[\zeta_\Delta D_R \zeta_c + \tfrac{i}{2}\zeta_\Delta N \zeta_\Delta\right].
$$

Express $N(\eta,\eta';k)$ and $D_R(\eta,\eta';k)$ as environment correlators of $\mathcal{O}$.[^3]
4. **Solve the environment mode functions (Day 5–8).** On the quasi-de Sitter background:
    - Write the Mukhanov–Sasaki equation for $v_{n,\boldsymbol{k}} = a\,\phi_{n,\boldsymbol{k}}$.
    - Obtain Hankel-function solutions with Bunch–Davies initial conditions.
    - Show that the Bessel index $\nu_n$ acquires an imaginary part $\propto \omega_n$ when the effective mass $m_n$ satisfies $m_n^2/H^2 > 9/4$, which produces the log-periodic phases $\exp(\pm i\omega_n \log(k/k_\star))$.[^2]
5. **Assemble $N(k)$ analytically (Day 8–10).** Plug the mode functions into the anti-commutator formula for $N$. Show that the equal-time noise spectrum reduces to:

$$
N(k) \propto \sum_n |g_n|^2 \cos(\omega_n \log(k/k_\star) + \phi_n) + \text{non-oscillatory},
$$

with $g_n = \epsilon\, e^{-\gamma\omega_n^2} e^{i\phi_n}$, reproducing the modulation $M(k)$ from `algftgate1.py`.[^1][^2]
6. **Verify the $\epsilon\to 0$ limit (Day 10).** Prove analytically that as $\epsilon\to 0$, $S_{\text{IF}}\to 0$ and $P_\zeta(k)\to P_0(k)$, recovering $\Lambda$CDM at $<10^{-6}$ precision.[^2]

### Deliverables

| File | Content |
| :-- | :-- |
| `docs/AL-GFT-Gate1-TrackA-SK.tex` | Sections 1–4 filled in with complete derivations |
| `src/algft_sk.py` | Python implementation: `build_noise_kernel(k, epsilon, sigma, omega_n, phi_n)` → $N(k)$; `compute_modulation(k, ...)` → $M(k)$ |

### Pass criteria for Phase 1

- [ ] $S_{\text{IF}}$ derived in closed form with no novel coarse-graining methods.[^1]
- [ ] $N(k)$ matches the functional form of `algftgate1.py`'s `zeta_comb_modulation()`.[^2]
- [ ] $\epsilon\to 0$ limit proven analytically and verified numerically.


### Failure modes

- Mode functions diverge or require ad hoc cutoffs → revisit $\Omega_n$ choice.
- $N(k)$ does not reproduce Zeta-Comb oscillatory structure → re-examine $g_n$ encoding.[^1]

***

## Phase 2 — Cumulant extraction and Gaussian fork (Week 3)

### Goal

Compute $C_2(k)$ and $C_3(k_1,k_2,k_3)$ from the derived $S_{\text{IF}}$, and formally establish the Gaussian fork.[^1][^3]

### Step-by-step instructions

1. **Extract $C_2(k)$ (Day 1–2).** From the Langevin equation implied by $S_{\text{IF}}$, compute the stochastic two-point function of $\zeta$. Show it yields:

$$
P_\zeta(k) = P_0(k)\,M(k),
$$

with $M(k)$ from Phase 1. Compare analytically to the output of `algftgate1.py`.[^2]
2. **Prove $C_3 = 0$ (Day 2–3).** Since the environment is Gaussian and the coupling is linear in $\mathcal{O}$, $S_{\text{IF}}$ is at most quadratic in $\zeta_{c},\zeta_\Delta$. Therefore the induced stochastic source $\xi$ has $\langle\xi\xi\xi\rangle_c = 0$, and all connected $n>2$ cumulants vanish. Write this out explicitly as a theorem in the LaTeX note with a one-paragraph proof.[^3][^1]
3. **State the Gaussian fork decision (Day 3).** Document: "AL-GFT Track A is a Gaussian model with $C_3 = 0$ by construction. Any future detection of primordial non-Gaussianity ($f_{\text{NL}} \neq 0$) would require extension to non-Gaussian environment states or nonlinear couplings (Track B), which is outside Gate 1 scope."[^1]
4. **Implement numerical cross-check (Day 4–5).** In `tests/`:
    - `test_modulation_match.py`: compare `algft_sk.compute_modulation(k)` vs `algftgate1.zeta_comb_modulation(k)` over $k \in [10^{-4}, 1]$ Mpc$^{-1}$. **Require max fractional residual < 2%.**[^2]
    - `test_eps_zero_limit.py`: set $\epsilon=0$ in `algft_sk`, confirm $|M(k)-1| < 10^{-6}$ for all $k$. [^2]

### Deliverables

| File | Content |
| :-- | :-- |
| `docs/AL-GFT-Gate1-TrackA-SK.tex` | Section 5 (Gaussian fork) complete |
| `tests/test_modulation_match.py` | SK vs original modulation comparison |
| `tests/test_eps_zero_limit.py` | $\Lambda$CDM recovery check |

### Pass criteria for Phase 2

- [ ] $C_2(k)$ functional form matches `algftgate1.py` within 2%.[^2]
- [ ] $C_3 = 0$ proven with a clean, citable argument.[^1]
- [ ] Both tests pass in CI / local run.


### Failure modes

- SK-derived $M(k)$ disagrees with numerical code by >2% → normalization or mode-function error; debug amplitude factors.
- $C_3$ turns out non-zero → would require re-examining the linearity of the coupling; unlikely in Track A but would trigger a Track B fork.[^1]

***

## Phase 3 — GFT coupling map: $(\epsilon,\sigma) \to (\lambda_4,\lambda_6)$ (Weeks 4–5)

### Goal

Derive and implement the mapping from AL-GFT microscopic parameters to effective GFT couplings at the Planck scale, which Gate 2 will use as UV boundary conditions.[^3][^1]

### Step-by-step instructions

1. **Identify the effective GFT action (Day 1–3).** Starting from the AL-GFT total action with arithmetic vertex weights, derive the effective quartic and sextic interaction terms in the GFT language. The arithmetic vertex amplitude:[^2]

$$
\mathcal{A} \propto \exp\!\Big(-\frac{(\dim j_1 \cdot \dim j_2 - \dim j_3)^2}{2\sigma^2}\Big)
$$

must be expanded to identify effective $\lambda_4$ (from 4-valent contractions) and $\lambda_6$ (from 6-valent / sextic contractions).
2. **Write the mapping functions (Day 3–5).** Derive explicit formulae:

$$
\lambda_4(M_P) = f_4(\epsilon, \sigma, \{\omega_n\}, M),
\quad
\lambda_6(M_P) = f_6(\epsilon, \sigma, \{\omega_n\}, M),
$$

where $M$ is the Starobinsky scalaron mass. The key relation is $\lambda_6(M_P) \sim M^2$, linking the sextic coupling to the inflationary energy scale.[^3][^1]
3. **Quantify uncertainty (Day 5–7).** For each mapping function, propagate uncertainties from:
    - $\epsilon \in [10^{-3}, 10^{-2}]$ (multiplicity coupling range).[^2]
    - $\sigma \in [0.05, 0.5]$ (resonance width range).[^2]
    - Truncation effects (which GFT diagrams are kept).

**Target: $\leq 20\%$ parametric uncertainty** on $\lambda_4(M_P)$ and $\lambda_6(M_P)$.[^1]
4. **Implement in code (Day 7–10).** Create `src/mapping_uv_gft.py`:

```python
def map_algft_to_gft(epsilon, sigma, omega_n, M_scalaron):
    """
    Returns (lambda4_MP, lambda6_MP, delta_lambda4, delta_lambda6).
    delta values are 1-sigma uncertainties.
    """
```

Add `tests/test_uv_map.py` checking:
    - Output is real and positive for physical parameter ranges.
    - $\lambda_6 \gg \lambda_4$ at UV (consistent with UV fixed-point structure).[^3]
    - Uncertainty budget stays within 20%.
5. **Write the Gate 1 → Gate 2 handoff spec (Day 10).** Document in the LaTeX note: "The following UV boundary conditions are provided for Gate 2: $\lambda_4(M_P) = \ldots \pm \ldots$, $\lambda_6(M_P) = \ldots \pm \ldots$, derived from AL-GFT arithmetic vertex amplitudes with $\epsilon = \ldots$, $\sigma = \ldots$."[^1]

### Deliverables

| File | Content |
| :-- | :-- |
| `docs/AL-GFT-Gate1-TrackA-SK.tex` | Section 6 (GFT coupling map) |
| `src/mapping_uv_gft.py` | $(\epsilon,\sigma)\to(\lambda_4,\lambda_6)$ with uncertainties |
| `tests/test_uv_map.py` | Physical-range and uncertainty checks |

### Pass criteria for Phase 3

- [ ] Explicit formulae $f_4, f_6$ documented with derivation.[^1]
- [ ] Parametric uncertainty $\leq 20\%$ on both couplings.[^1]
- [ ] $\lambda_6(M_P) \sim M^2$ relation holds to within uncertainty.[^3]
- [ ] Gate 2 handoff values tabulated.


### Failure modes

- No clean mapping exists (arithmetic vertices don't reduce to standard GFT quartic/sextic) → **Gate 1 fails; Gate 1–Gate 2 chain breaks.**[^1]
- Uncertainty exceeds 50% → mapping is too loose; refine truncation or narrow $\epsilon,\sigma$ ranges.[^1]

***

## Phase 4 — Validation against Planck data (Week 5, parallel with Phase 3)

### Goal

Run the SK-derived spectrum through a matched-filter analysis on Planck 2018 residuals and confirm $C_2$ consistency.[^2]

### Step-by-step instructions

1. **Generate the SK-based spectrum.** Use `algft_sk.py` to produce $P_\zeta(k)$ over the Planck $\ell$-range ($\ell = 2$–2500).[^2]
2. **Run the matched filter.** Use `ZetaCombMatchedFilter` from `algftgate1.py` (or a refactored version in `src/`) on Planck 2018 TT residual data.[^2]
    - Success: SNR $\geq 3.0$ at $\omega \simeq 14.13$.[^2]
    - Marginal: $1.5 <$ SNR $< 3.0$ → signal is suggestive, proceed with caveats.
    - Failure: SNR $< 1.5$ → $\epsilon < 10^{-4}$ required, pushing AL-GFT toward unobservability.[^2]
3. **$\Lambda$CDM consistency check.** Verify that the best-fit AL-GFT spectrum matches Planck within $2\sigma$ across the full $\ell$-range when $\epsilon, \sigma$ are in the physical regime.[^1]
4. **Document results.** Create `examples/demo_power_spectrum.ipynb` with:
    - Plot of $P_0(k)$ vs $P_\zeta(k)$ with Zeta-Comb.
    - Matched-filter SNR scan.
    - Residuals relative to Planck.[^2]

### Deliverables

| File | Content |
| :-- | :-- |
| `examples/demo_power_spectrum.ipynb` | Spectrum plots + matched-filter results |
| `docs/AL-GFT-Gate1-TrackA-SK.tex` | Validation section with Planck comparison |

### Pass criteria for Phase 4

- [ ] $C_2(k)$ matches Planck within $2\sigma$.[^1]
- [ ] Matched-filter SNR and $\epsilon$ estimate reported.

***

## Phase 5 — Gate 1 "Complete" appendix and pass decision (Week 6)

### Goal

Assemble the final Gate 1 pass/fail document and update all project labeling.[^1]

### Step-by-step instructions

1. **Write the Gate 1 Pass Decision appendix** in the LaTeX note, containing:
    - Complete derivation chain summary (one page).
    - Table of all pass/fail criteria with status (checked/unchecked).[^1]
    - Explicit statement of the Gaussian fork outcome.[^1]
    - Gate 2 handoff values ($\lambda_4, \lambda_6$ with uncertainties).[^1]
2. **Update all project labels.** If all criteria are met, change document status from "framework specified, derivation in progress" to: **"Gate 1: Gaussian branch passed. SK derivation complete. $C_2$ validated, $C_3 = 0$. UV map delivered for Gate 2."**[^1]
3. **Tag the repo** as `v0.1-gate1-passed` (or `v0.1-gate1-partial` if any criteria remain unmet).
4. **Create the Gate 2 readiness memo** (`docs/Gate2-Readiness.md`): list the UV values, their uncertainties, and what Gate 2 needs to do with them.[^3][^1]

### Final Gate 1 pass/fail checklist

| \# | Criterion | Threshold | Status |
| :-- | :-- | :-- | :-- |
| 1 | Influence functional $S_{\text{IF}}$ derived with Zeta-Comb $N(k)$ | Closed-form, standard techniques only | ▢ |
| 2 | $N(k)$ matches `algftgate1.py` modulation | Max residual < 2% | ▢ |
| 3 | $C_2(k)$ matches Planck | Within $2\sigma$ | ▢ |
| 4 | $C_3(k_1,k_2,k_3)$ computed | Zero (Gaussian) or $\|f_{\text{NL}}\| < 10$ | ▢ |
| 5 | GFT coupling map documented | $(\epsilon,\sigma)\to(\lambda_4,\lambda_6)$ with $\leq 20\%$ uncertainty | ▢ |
| 6 | $\epsilon\to 0$ limit recovers $\Lambda$CDM | $\|M(k)-1\| < 10^{-6}$ | ▢ |
| 7 | All derivations use standard techniques | No novel coarse-graining | ▢ |

**Gate 1 is passed** if criteria 1–7 are all checked.[^3][^1]

**Gate 1 fails** if any of these occur:[^1]

- $S_{\text{IF}}$ diverges or requires unjustified cutoffs.
- Zeta-Comb amplitude for observability requires $\epsilon > 0.1$ (non-perturbative breakdown).
- $C_3 \neq 0$ with $|f_{\text{NL}}| > 10$ (excluded by Planck).
- No clean $(\epsilon,\sigma)\to(\lambda_4,\lambda_6)$ map exists.

***

## Risk register

| Risk | Probability | Impact | Mitigation |
| :-- | :-- | :-- | :-- |
| $C_3$ effectively zero | 40% | High (theory simplification) | Accept as $C_2$-only framework, update Blueprint [^1] |
| GFT mapping uncertainty > 50% | 30% | Medium | Use conservative bounds, focus on phenomenology [^1] |
| Derivation reveals inconsistency | 20% | Critical | Return to framework design phase [^1] |
| Timeline exceeds 6 weeks | 60% | Low | Extend deadline, maintain transparent status [^1] |


***

## Timeline summary

| Phase | Duration | Key output | Blocks |
| :-- | :-- | :-- | :-- |
| 0: Repo setup | Day 1 | Repo structure, baseline code | Nothing |
| 1: SK derivation | Weeks 1–2 | $S_{\text{IF}}$, $N(k)$, `algft_sk.py` | Phase 2, 3 |
| 2: Cumulant extraction | Week 3 | $C_2, C_3$ proof, tests passing | Phase 5 |
| 3: GFT coupling map | Weeks 4–5 | $(\epsilon,\sigma)\to(\lambda_4,\lambda_6)$, `mapping_uv_gft.py` | Phase 5, Gate 2 |
| 4: Planck validation | Week 5 (parallel) | SNR scan, spectrum comparison | Phase 5 |
| 5: Pass decision | Week 6 | Gate 1 appendix, repo tag, Gate 2 memo | Gate 2 start |

<div align="center">⁂</div>

[^1]: we-ve-conquered-gate-1-now-let-cES1jW1bSJy35C.UIh.JAA.md

[^2]: Gate-1-Formalization_-Arithmetic-Langevin-GF.pdf

[^3]: CEQG-RG-Langevin-Blueprint.pdf

