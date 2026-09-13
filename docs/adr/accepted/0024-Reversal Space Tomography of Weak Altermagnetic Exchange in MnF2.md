# ADR-0024: Reversal-Space Tomography of Weak Altermagnetic Exchange in MnF₂

**Status:** Proposed

## Context
The δJ7 principle (ADR-0023) identifies a weak seventh-neighbor exchange imbalance as a candidate source coordinate for the altermagnetic chiral response in MnF₂, at the few-µeV scale, coexisting with a larger dipolar contribution. Weak sources need engineered readout multiplication: a control variable can increase the measurement derivative |∂O/∂λ| without changing |λ|. The paper provides the quantitative design discipline for that readout engineering and for certifying the sign of the measured response.

## Decision
Adopt reversal-space tomography as the engineering framework for signed readouts of weak altermagnetic exchange in MnF₂.

- **Binary design coordinates.** Partner momentum, magnetic-field sign, incident polarization, and magnetic-domain sign are treated as independent binary design coordinates of a (ℤ₂)^N reversal experiment.
- **Walsh–Hadamard contrast decomposition.** The measured response is decomposed into exact Walsh–Hadamard factorial contrasts, indexed by the subsets A of reversal coordinates (ÎA = 2⁻ᴺ Σ_s (∏_{i∈A} sᵢ) I(s)).
- **Path-consistency gate.** Interpreting those contrasts as characters of the physical (ℤ₂)^N reversal group additionally requires the realized reversals to behave as independent involutions on the prepared state: rᵢ² ≃ I and rᵢrⱼ ≃ rⱼrᵢ within tolerance. Hysteresis or path-dependent preparation can violate the group interpretation even though the contrast algebra remains valid.
- **Falsification channels.** A coefficient in a parity sector forbidden by the model is a built-in obstruction channel; a significant nonzero value signals leakage, uncontrolled nuisance structure, or missing physics.
- **Signed source readout.** δJ7 ≡ J7b − J7a is measured as a signed quantity only after the bond-label convention is fixed; the few-µeV scale is resolved by gain in transduction, not by changing the microscopic coefficient.

## Consequences
* Weak-exchange readouts become certifiably signed and falsifiable rather than amplitude-dependent.
* Measures gain in transduction while explicitly not claiming the coefficient has become large (selection vs amplification).
* The path-consistency gate admits and tests hysteresis, domain history, and preparation drift.
* Supplies the operational readout protocol whose source-sector attribution ADR-0023 defines and whose null taxonomy ADR-0022 interprets.

## Traceability & Artifact Links
* **[Source File]** `docs/adr/proposed/Paper3 Reversal-Space Tomography of Weak Altermagnetic Exchange in MnF2- Path Validated Signed Readout Engineering - JHaines 2026.pdf` — "Reversal-Space Tomography of Weak Altermagnetic Exchange in MnF₂: Path-Validated Signed Readout Engineering" (John Haines, Sept 12, 2026).
* **[Related ADR]** ADR-0023 — the δJ7 source-sector convention whose sign this framework reads out.
* **[Related ADR]** ADR-0022 — polarization-channel separation this protocol multiplies in transduction.
* **[Related ADR]** ADR-0027 — group-character coding as a specialization of the general null-witness duality.
* **[Related ADR]** ADR-0028 — target-first design that justifies which reversal coordinate to add (design gain ΔC).