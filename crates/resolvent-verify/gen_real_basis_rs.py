#!/usr/bin/env python3
"""Generate src/basis_data.rs from basis_factors.json.

Mirrors gen_real_basis.py (Lean) but emits Rust constants so the Rust/Kani
verification uses the *same* real 256-state basis (primes 2,3,5,7; max_exp 3)
instead of a mock.
"""
import json
import os
import sys


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    json_path = os.path.join(here, "..", "..", "materia_commons", "meta-theorem", "basis_factors.json")
    out_path = os.path.join(here, "src", "basis_data.rs")

    with open(json_path) as f:
        data = json.load(f)

    primes = data["primes"]
    numbers = [b["n"] for b in data["basis"]]
    vals = [b["exponents"] for b in data["basis"]]
    assert len(numbers) == len(vals)
    assert all(len(v) == len(primes) for v in vals)

    lines = []
    lines.append("// Generated from basis_factors.json by gen_real_basis_rs.py.")
    lines.append("// Real (non-mock) basis: primes = %s, %d states. Do not edit by hand."
                 % (primes, len(numbers)))
    lines.append("")
    lines.append("/// The %d basis integers n, in basis order." % len(numbers))
    lines.append("pub const NUMBERS: [usize; %d] = [" % len(numbers))
    # wrap rows of 10 for readability
    for i in range(0, len(numbers), 10):
        chunk = numbers[i:i + 10]
        lines.append("    " + ", ".join(str(x) for x in chunk) + ",")
    lines.append("];")
    lines.append("")
    lines.append("/// Valuations (exponent vectors), aligned with `NUMBERS`.")
    lines.append("pub const VALS: [[u32; %d]; %d] = [" % (len(primes), len(numbers)))
    for v in vals:
        lines.append("    [" + ", ".join(str(x) for x in v) + "],")
    lines.append("];")
    lines.append("")
    lines.append("/// Number of basis states.")
    lines.append("pub const N_STATES: usize = %d;" % len(numbers))
    lines.append("")

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w") as f:
        f.write("\n".join(lines))
    print("Wrote %s (%d states)" % (out_path, len(numbers)))


if __name__ == "__main__":
    sys.exit(main())
