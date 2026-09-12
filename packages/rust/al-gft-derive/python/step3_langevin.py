#!/usr/bin/env python3
"""
al-gft-derive — Step 3: Langevin Equation

Varies the effective action to obtain the stochastic equation of motion
for the background condensate σ(t) with Gaussian noise ξ(t).

Outputs JSON to stdout.
"""

import json
import hashlib
import sympy as sp

def main() -> None:
    t = sp.Symbol("t", real=True)
    sigma = sp.Function("sigma")
    H = sp.Function("H")
    m_sq = sp.Symbol("m_sq", real=True)
    xi = sp.Function("xi")

    # Langevin equation: σ̈ + 3H σ̇ + m² σ = ξ(t)
    lhs = sp.Add(
        sp.diff(sigma(t), t, 2),
        sp.Mul(sp.Rational(3, 1), H(t), sp.diff(sigma(t), t)),
        sp.Mul(m_sq, sigma(t)),
    )
    rhs = xi(t)

    # Noise correlation: ⟨ξ(t) ξ(t')⟩ = N(t - t')
    tp = sp.Symbol("t'", real=True)
    N_corr = sp.Symbol("N(t-t')", real=True)
    noise_correlation = {
        "type": "Correlation",
        "operator": "langle",
        "operands": [
            {
                "type": "Mul",
                "operands": [
                    {"type": "Function", "name": "xi", "args": [{"type": "Symbol", "name": "t"}]},
                    {"type": "Function", "name": "xi", "args": [{"type": "Symbol", "name": "t_prime"}]},
                ],
            },
        ],
        "equals": {
            "type": "Symbol",
            "name": "N",
            "args": [{"type": "Sub", "operands": [{"type": "Symbol", "name": "t"}, {"type": "Symbol", "name": "t_prime"}]}],
        },
    }

    expression_tree = {
        "type": "Equation",
        "name": "LangevinCondensate",
        "lhs": {
            "type": "Add",
            "operands": [
                {"type": "Diff", "expr": {"type": "Function", "name": "sigma", "args": [{"type": "Symbol", "name": "t"}]}, "order": 2},
                {
                    "type": "Mul",
                    "operands": [
                        {"type": "Rational", "n": 3, "d": 1},
                        {"type": "Function", "name": "H", "args": [{"type": "Symbol", "name": "t"}]},
                        {"type": "Diff", "expr": {"type": "Function", "name": "sigma", "args": [{"type": "Symbol", "name": "t"}]}, "order": 1},
                    ],
                },
                {"type": "Mul", "operands": [{"type": "Symbol", "name": "m_sq"}, {"type": "Function", "name": "sigma", "args": [{"type": "Symbol", "name": "t"}]}]},
            ],
        },
        "rhs": {"type": "Function", "name": "xi", "args": [{"type": "Symbol", "name": "t"}]},
        "noise_correlation": {
            "type": "Expectation",
            "operands": [
                {"type": "Mul", "operands": [
                    {"type": "Function", "name": "xi", "args": [{"type": "Symbol", "name": "t"}]},
                    {"type": "Function", "name": "xi", "args": [{"type": "Symbol", "name": "t_prime"}]},
                ]},
            ],
            "equals": {
                "type": "Function",
                "name": "N",
                "args": [{"type": "Sub", "operands": [{"type": "Symbol", "name": "t"}, {"type": "Symbol", "name": "t_prime"}]}],
            },
        },
    }

    result = {
        "step": "langevin_equation",
        "version": "1.0",
        "expression_tree": expression_tree,
        "equation_string": str(sp.Eq(lhs, rhs)),
        "noise_correlation_string": str(noise_correlation),
        "assumptions": [
            "slow_roll",
            "gaussian_noise",
            "markovian_environment",
            "background_condensate",
        ],
        "transformation_rules": [
            "functional_variation",
            "noise_identification",
            "langevin_projection",
        ],
    }

    canonical = json.dumps(result, sort_keys=True, separators=(",", ":"))
    symbolic_hash = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    result["symbolic_hash"] = symbolic_hash

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
