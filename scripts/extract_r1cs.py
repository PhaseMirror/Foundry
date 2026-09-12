#!/usr/bin/env python3
"""
Extract R1CS matrices from langlandsCheck.circom and produce a Rust module.

Usage:
  python3 scripts/extract_r1cs.py circuits/langlandsCheck.circom --output crates/core/src/r1cs_constants.rs
"""

import json
import subprocess
import argparse
import os

def compile_circuit(circuit_path):
    """Compile the circom circuit to R1CS."""
    base = os.path.splitext(circuit_path)[0]
    cmd = ["circom", circuit_path, "--r1cs", "--wasm", "-o", os.path.dirname(circuit_path), "-l", "circuits/node_modules"]
    subprocess.run(cmd, check=True)
    return f"{base}.r1cs"

def export_r1cs_json(r1cs_path, json_path):
    """Export R1CS to JSON using snarkjs."""
    cmd = ["npx", "--yes", "snarkjs", "r1cs", "export", "json", r1cs_path, json_path]
    subprocess.run(cmd, check=True)

def json_to_rust(json_path, output_path):
    """Read the R1CS JSON and write Rust arrays."""
    with open(json_path) as f:
        data = json.load(f)

    # Extract matrix data (snarkjs format uses sparse representation)
    # We convert to dense (nConstraints × nWires) arrays.
    n_constraints = data["constraints"].__len__()
    # To get number of wires we can check max index in matrices + 1
    # The JSON structure: { "constraints": [ { "A": { "0": "1", ... }, "B": {...}, "C": {...} } ] }
    # We'll collect all wire indices.
    max_wire = 0
    for con in data["constraints"]:
        for i_mat in range(3):
            for idx_str in con[i_mat]:
                idx = int(idx_str)
                if idx > max_wire:
                    max_wire = idx
    n_wires = max_wire + 1

    # Initialize dense matrices
    A = [[0 for _ in range(n_wires)] for _ in range(n_constraints)]
    B = [[0 for _ in range(n_wires)] for _ in range(n_constraints)]
    C = [[0 for _ in range(n_wires)] for _ in range(n_constraints)]

    BN254_PRIME = 21888242871839275222246405745257275088548364400416034343698204186575808495617
    GOLDILOCKS = 18446744069414584321

    for i, con in enumerate(data["constraints"]):
        for i_mat, mat in enumerate([A, B, C]):
            for idx_str, val_str in con[i_mat].items():
                idx = int(idx_str)
                val = int(val_str)
                if val > BN254_PRIME // 2:
                    val = val - BN254_PRIME
                val = val % GOLDILOCKS
                mat[i][idx] = val

    # Write Rust module
    with open(output_path, "w") as out:
        out.write("// Auto-generated R1CS constants\n")
        out.write("use crate::langlands_zk::GoldilocksField;\n\n")
        out.write(f"pub const NUM_CONSTRAINTS: usize = {n_constraints};\n")
        out.write(f"pub const NUM_WIRES: usize = {n_wires};\n\n")

        def format_matrix(name, mat):
            lines = []
            lines.append(f"pub const {name}: [[GoldilocksField; NUM_WIRES]; NUM_CONSTRAINTS] = [")
            for row in mat:
                row_str = ", ".join(f"GoldilocksField({v})" for v in row)
                lines.append(f"    [{row_str}],")
            lines.append("];\n")
            return "\n".join(lines)

        for name, mat in [("A", A), ("B", B), ("C", C)]:
            out.write(format_matrix(name, mat) + "\n")

    print(f"Rust module written to {output_path}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("circuit", help="Path to langlandsCheck.circom")
    parser.add_argument("--output", default="crates/core/src/r1cs_constants.rs")
    args = parser.parse_args()

    r1cs = compile_circuit(args.circuit)
    json_file = os.path.splitext(r1cs)[0] + ".json"
    export_r1cs_json(r1cs, json_file)
    json_to_rust(json_file, args.output)

if __name__ == "__main__":
    main()
