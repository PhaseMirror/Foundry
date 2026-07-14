#!/usr/bin/env python3
"""
generate_rust_vals.py
Parses basis_factors.json (verified by Lean) and produces a Rust static array
definition of shape [N_STATES][4] for use in the Kani-proofed Hamiltonian.
"""

import json
import os
from pathlib import Path

def main():
    json_path = Path("meta-theorem/basis_factors.json")
    if not json_path.exists():
        print("❌ basis_factors.json not found. Run export_basis.py first.")
        return 1

    with open(json_path) as f:
        data = json.load(f)

    primes = data["primes"]
    basis = data["basis"]   # list of {"n": int, "exponents": [int, ...]}

    # Build the valuations array as a 2D list
    vals = []
    for entry in basis:
        exps = entry["exponents"]
        vals.append(exps)

    vals_str = "[\n" + ",\n".join("    [" + ", ".join(str(v) for v in row) + "]" for row in vals) + "\n]"

    # Prepare Rust source
    rust_code = f"""// Auto-generated from Lean-verified basis_factors.json
// Do not edit manually.

pub const N_STATES: usize = {len(vals)};
pub const PRIMES: [u32; {len(primes)}] = {primes};

pub static VALS: [[u8; {len(primes)}]; {len(vals)}] = {vals_str};
"""

    out_path = Path("src/generated_vals_array.rs")
    out_path.write_text(rust_code)
    print(f"✅ Generated {out_path} with {len(vals)} states.")
    return 0

if __name__ == "__main__":
    exit(main())
