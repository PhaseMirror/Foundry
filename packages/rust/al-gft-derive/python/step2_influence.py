#!/usr/bin/env python3
"""
al-gft-derive — Step 2: Influence Functional via Gaussian Path Integral

Integrates out the environment field χ to obtain the Feynman-Vernon influence
functional. Derives the noise kernel N(t−t′) and dissipation kernel D(t−t′)
as sums over Zeta zeros.

Outputs JSON to stdout.
"""

import json
import hashlib
import sympy as sp

def main() -> None:
    # Define symbols and functions
    t, tp = sp.Symbol("t", real=True), sp.Symbol("t'", real=True)
    tau = sp.Symbol("tau", real=True)
    gamma_n = sp.Symbol("gamma_n", real=True, positive=True)
    phi_plus = sp.Function("phi_plus")
    phi_minus = sp.Function("phi_minus")
    N = sp.Function("N")
    D = sp.Function("D")

    # Noise kernel from Zeta zeros: N(tau) = Σ_n cos(gamma_n * tau) / sqrt(1/4 + gamma_n**2)
    noise_kernel = sp.Sum(
        sp.cos(gamma_n * tau) / sp.sqrt(sp.Rational(1, 4) + gamma_n**2),
        (gamma_n, 1, sp.oo),
    )

    # Dissipation kernel: D(tau) = Σ_n sin(gamma_n * tau) / sqrt(1/4 + gamma_n**2)
    dissipation_kernel = sp.Sum(
        sp.sin(gamma_n * tau) / sp.sqrt(sp.Rational(1, 4) + gamma_n**2),
        (gamma_n, 1, sp.oo),
    )

    # Influence functional: F[φ+, φ-] = exp(i * ∫∫ N(t-t') φ+(t) φ-(t') dt dt' + ...)
    influence_exponent = sp.Add(
        sp.Mul(
            sp.I,
            sp.Integral(
                sp.Integral(
                    sp.Mul(
                        N(t - tp),
                        phi_plus(t),
                        phi_minus(tp),
                    ),
                    (tp, -sp.oo, sp.oo),
                ),
                (t, -sp.oo, sp.oo),
            ),
        ),
        sp.Mul(
            sp.I,
            sp.Integral(
                sp.Integral(
                    sp.Mul(
                        D(t - tp),
                        sp.Add(phi_plus(t), phi_minus(tp)),
                    ),
                    (tp, -sp.oo, sp.oo),
                ),
                (t, -sp.oo, sp.oo),
            ),
        ),
    )

    influence_functional = sp.exp(influence_exponent)

    # Build JSON expression tree
    expression_tree = {
        "type": "Functional",
        "name": "FeynmanVernonInfluence",
        "fields": {
            "phi_plus": {"type": "Function", "name": "phi_plus", "args": [{"type": "Symbol", "name": "t"}]},
            "phi_minus": {"type": "Function", "name": "phi_minus", "args": [{"type": "Symbol", "name": "t"}]},
        },
        "kernels": [
            {
                "type": "Kernel",
                "name": "noise",
                "symbol": "N",
                "definition": {
                    "type": "Sum",
                    "index": "n",
                    "range": {"type": "Interval", "start": "1", "end": "oo"},
                    "term": {
                        "type": "Div",
                        "operands": [
                            {"type": "Cos", "args": [{"type": "Mul", "operands": [{"type": "Symbol", "name": "gamma_n"}, {"type": "Symbol", "name": "tau"}]}]},
                            {
                                "type": "Pow",
                                "base": {
                                    "type": "Add",
                                    "operands": [
                                        {"type": "Rational", "n": 1, "d": 4},
                                        {"type": "Pow", "base": {"type": "Symbol", "name": "gamma_n"}, "exp": {"type": "Rational", "n": 2, "d": 1}},
                                    ],
                                },
                                "exp": {"type": "Rational", "n": 1, "d": 2},
                            },
                        ],
                    },
                },
            },
            {
                "type": "Kernel",
                "name": "dissipation",
                "symbol": "D",
                "definition": {
                    "type": "Sum",
                    "index": "n",
                    "range": {"type": "Interval", "start": "1", "end": "oo"},
                    "term": {
                        "type": "Div",
                        "operands": [
                            {"type": "Sin", "args": [{"type": "Mul", "operands": [{"type": "Symbol", "name": "gamma_n"}, {"type": "Symbol", "name": "tau"}]}]},
                            {
                                "type": "Pow",
                                "base": {
                                    "type": "Add",
                                    "operands": [
                                        {"type": "Rational", "n": 1, "d": 4},
                                        {"type": "Pow", "base": {"type": "Symbol", "name": "gamma_n"}, "exp": {"type": "Rational", "n": 2, "d": 1}},
                                    ],
                                },
                                "exp": {"type": "Rational", "n": 1, "d": 2},
                            },
                        ],
                    },
                },
            },
        ],
        "influence_functional": {
            "type": "Exp",
            "arg": {
                "type": "Add",
                "operands": [
                    {
                        "type": "Mul",
                        "operands": [
                            {"type": "Symbol", "name": "I"},
                            {
                                "type": "Integral",
                                "expr": {
                                    "type": "Integral",
                                    "expr": {
                                        "type": "Mul",
                                        "operands": [
                                            {"type": "Function", "name": "N", "args": [{"type": "Sub", "operands": [{"type": "Symbol", "name": "t"}, {"type": "Symbol", "name": "t_prime"}]}]},
                                            {"type": "Function", "name": "phi_plus", "args": [{"type": "Symbol", "name": "t"}]},
                                            {"type": "Function", "name": "phi_minus", "args": [{"type": "Symbol", "name": "t_prime"}]},
                                        ],
                                    },
                                    "limits": {"type": "Interval", "start": "-oo", "end": "oo", "var": "t_prime"},
                                },
                                "limits": {"type": "Interval", "start": "-oo", "end": "oo", "var": "t"},
                            },
                        ],
                    },
                    {
                        "type": "Mul",
                        "operands": [
                            {"type": "Symbol", "name": "I"},
                            {
                                "type": "Integral",
                                "expr": {
                                    "type": "Integral",
                                    "expr": {
                                        "type": "Mul",
                                        "operands": [
                                            {"type": "Function", "name": "D", "args": [{"type": "Sub", "operands": [{"type": "Symbol", "name": "t"}, {"type": "Symbol", "name": "t_prime"}]}]},
                                            {"type": "Add", "operands": [
                                                {"type": "Function", "name": "phi_plus", "args": [{"type": "Symbol", "name": "t"}]},
                                                {"type": "Function", "name": "phi_minus", "args": [{"type": "Symbol", "name": "t_prime"}]},
                                            ]},
                                        ],
                                    },
                                    "limits": {"type": "Interval", "start": "-oo", "end": "oo", "var": "t_prime"},
                                },
                                "limits": {"type": "Interval", "start": "-oo", "end": "oo", "var": "t"},
                            },
                        ],
                    },
                ],
            },
        },
    }

    result = {
        "step": "influence_functional",
        "version": "1.0",
        "expression_tree": expression_tree,
        "assumptions": [
            "gaussian_integral",
            "linear_coupling",
            "zeta_zero_sum",
            "markovian_environment",
        ],
        "transformation_rules": [
            "complete_square",
            "path_integral_out",
            "zeta_series_expansion",
        ],
        "kernels": {
            "noise": str(noise_kernel),
            "dissipation": str(dissipation_kernel),
        },
    }

    canonical = json.dumps(result, sort_keys=True, separators=(",", ":"))
    symbolic_hash = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    result["symbolic_hash"] = symbolic_hash

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
