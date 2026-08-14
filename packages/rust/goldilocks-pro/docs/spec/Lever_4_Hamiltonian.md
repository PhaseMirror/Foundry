# Lever 4: Sparse Hamiltonian (Normative)

## 1. Hamiltonian Representation
$H = \sum_i c_i P_i$
where:
- $c_i$: Resonance-modulated coefficient.
- $P_i$: Sparse operator gated by a Prime Mask.

## 2. Gating Law
A term in the Hamiltonian is active iff its mask intersects with the system's active prime mask.
- `active = (term_mask & active_mask) != 0`.

## 3. Modulation Law
The coefficient $c_i$ is multiplied by the payload of the corresponding resonance word.
- `val = base_coeff * resonance_payload`.
