# Lever 6: Plonky3 Circuit (Normative)

## 1. Prime-Resonance AIR Invariants
The prover chip MUST enforce bit-level correctness for exported public inputs.

## 2. Constraints
- **Bit-Decomposition:** The $u64$ mask and resonance word are correctly reconstructed from boolean columns.
- **Booleanity:** All bits in the trace are $\in \{0, 1\}$.
- **R96 Validation:** Resonance class (bits 0–5) < 96.
- **Gating Relation:** Resonance Bit 0 $\cdot$ (1 - Mask Bit 0) = 0.

## 3. Public Inputs Vector
- `[prime_mask_fp, resonance_word_fp, delta_pz_fp, rho_bound_fp, lambda_m_fp, veto_flag_fp]`
- All elements interpreted as $\mathbb{F}_{Gold}$ elements.
