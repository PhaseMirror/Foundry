//! Port of `generate_rust_vals.py` — renders the Kani-proofed Hamiltonian's
//! static valuations array from `basis_factors.json`.
//!
//! Output is byte-identical to the Python generator (see `tests/fidelity.rs`).

use crate::model::BasisData;

/// Render `generated_vals_array.rs` for a `BasisData`.
pub fn render_generated_vals(data: &BasisData) -> String {
    let n_states = data.basis.len();
    let n_primes = data.primes.len();
    let primes = data
        .primes
        .iter()
        .map(|p| p.to_string())
        .collect::<Vec<_>>()
        .join(", ");
    let rows = data
        .basis
        .iter()
        .map(|e| {
            let row = e
                .exponents
                .iter()
                .map(|v| v.to_string())
                .collect::<Vec<_>>()
                .join(", ");
            format!("    [{row}]")
        })
        .collect::<Vec<_>>()
        .join(",\n");
    format!(
        "// Auto-generated from Lean-verified basis_factors.json\n\
         // Do not edit manually.\n\
         \n\
         pub const N_STATES: usize = {n_states};\n\
         pub const PRIMES: [u32; {n_primes}] = [{primes}];\n\
         \n\
         pub static VALS: [[u8; {n_primes}]; {n_states}] = [\n\
         {rows}\n\
         ];\n"
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::BasisEntry;

    #[test]
    fn row_format_matches_generator() {
        let data = BasisData {
            primes: vec![2, 3],
            max_exp: 1,
            basis: vec![
                BasisEntry { n: 1, exponents: vec![0, 0] },
                BasisEntry { n: 6, exponents: vec![1, 1] },
            ],
        };
        let out = render_generated_vals(&data);
        assert_eq!(
            out,
            concat!(
                "// Auto-generated from Lean-verified basis_factors.json\n",
                "// Do not edit manually.\n",
                "\n",
                "pub const N_STATES: usize = 2;\n",
                "pub const PRIMES: [u32; 2] = [2, 3];\n",
                "\n",
                "pub static VALS: [[u8; 2]; 2] = [\n",
                "    [0, 0],\n",
                "    [1, 1]\n",
                "];\n"
            )
        );
    }
}