#!/usr/bin/env python3
"""Generate src/SemanticArithmetic/RealBasis.lean from basis_factors.json.

This replaces the mock `states` / `number_of_state` / `valuations` in
SpectralBridge.lean with the *real* 256-state basis so that the Hamiltonian
matrices carry non-trivial data (the mock returned identically-zero
valuations, which made Xi_simple and the interaction term vanish).
"""
import json
import sys
import os


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    json_path = os.path.join(here, "basis_factors.json")
    out_path = os.path.join(here, "src", "SemanticArithmetic", "RealBasis.lean")

    with open(json_path) as f:
        data = json.load(f)

    primes = data["primes"]
    numbers = [b["n"] for b in data["basis"]]
    vals = [b["exponents"] for b in data["basis"]]
    assert len(numbers) == len(vals)
    assert all(len(v) == len(primes) for v in vals)

    def fmt_nat_list(xs):
        return "[" + ", ".join(str(x) for x in xs) + "]"

    def fmt_val_list(vss):
        return "[" + ", ".join(fmt_nat_list(v) for v in vss) + "]"

    lines = []
    lines.append("/-")
    lines.append("RealBasis.lean")
    lines.append("Generated from basis_factors.json by gen_real_basis.py.")
    lines.append("Real (non-mock) basis data: primes = %s, %d states."
                 % (primes, len(numbers)))
    lines.append("Do not edit by hand; re-run gen_real_basis.py instead.")
    lines.append("-/")
    lines.append("")
    lines.append("import SemanticArithmetic.Core")
    lines.append("")
    lines.append("namespace SemanticArithmetic.RealBasis")
    lines.append("")
    lines.append("def primes : List Nat := " + fmt_nat_list(primes))
    lines.append("")
    lines.append("/-- The %d basis integers n, in basis order. -/"
                 % len(numbers))
    lines.append("def basisNumbers : List Nat := " + fmt_nat_list(numbers))
    lines.append("")
    lines.append("/-- Valuations (exponent vectors) aligned with `basisNumbers`. -/")
    lines.append("def basisValuations : List (List Nat) := " + fmt_val_list(vals))
    lines.append("")
    lines.append("/-- Number of basis states. -/")
    lines.append("def N_states : Nat := " + str(len(numbers)))
    lines.append("")
    lines.append("/-- Look up the valuation vector of a basis integer (defaults to zeros). -/")
    lines.append("def valuationOf (n : Nat) : List Nat :=")
    lines.append("  (List.zip basisNumbers basisValuations).lookup n |>.getD (List.replicate primes.length 0)")
    lines.append("")
    lines.append("end SemanticArithmetic.RealBasis")
    lines.append("")

    with open(out_path, "w") as f:
        f.write("\n".join(lines))
    print("Wrote %s (%d states)" % (out_path, len(numbers)))


if __name__ == "__main__":
    sys.exit(main())
