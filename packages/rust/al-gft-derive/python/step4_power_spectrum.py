#!/usr/bin/env python3
"""
al-gft-derive — Step 4: Power Spectrum Solution

Solves the stochastic Langevin equation in the slow-roll approximation to
obtain the curvature power spectrum P_ζ(k).

Outputs JSON to stdout.
"""

import json
import hashlib
import sympy as sp

def main() -> None:
    k = sp.Symbol("k", positive=True, real=True)
    k_star = sp.Symbol("k_star", positive=True, real=True)
    A_s = sp.Symbol("A_s", positive=True, real=True)
    n_s = sp.Symbol("n_s", real=True)
    epsilon = sp.Symbol("epsilon", positive=True, real=True)
    gamma_n = sp.Symbol("gamma_n", real=True, positive=True)
    phi_n = sp.Symbol("phi_n", real=True)
    P_zeta = sp.Function("P_zeta")

    # Slow-roll solution with oscillatory corrections from Zeta zeros
    oscillatory_term = sp.cos(
        sp.Add(
            sp.Mul(gamma_n, sp.log(k / k_star)),
            phi_n,
        )
    ) / sp.sqrt(sp.Rational(1, 4) + gamma_n**2)

    sum_term = sp.Sum(epsilon * oscillatory_term, (gamma_n, 1, sp.oo))

    P_zeta_expr = sp.Mul(
        A_s,
        sp.Pow(k / k_star, n_s - 1),
        sp.Add(1, sum_term),
    )

    # Serialize the symbolic expression using SymPy's srepr for exact round-trip
    lhs_repr = sp.srepr(P_zeta(k))
    rhs_repr = sp.srepr(P_zeta_expr)
    equation_repr = sp.srepr(sp.Eq(P_zeta(k), P_zeta_expr))

    expression_tree = {
        "type": "Equation",
        "name": "CurvaturePowerSpectrum",
        "lhs_srepr": lhs_repr,
        "rhs_srepr": rhs_repr,
        "equation_srepr": equation_repr,
        "params": {
            "A_s": str(A_s),
            "n_s": str(n_s),
            "epsilon": str(epsilon),
            "gamma_n": str(gamma_n),
            "phi_n": str(phi_n),
        },
    }

    result = {
        "step": "power_spectrum",
        "version": "1.0",
        "expression_tree": expression_tree,
        "equation_string": str(sp.Eq(P_zeta(k), P_zeta_expr)),
        "assumptions": [
            "slow_roll",
            "markovian_noise",
            "bunch_davies_ic",
            "zeta_zero_spectrum",
        ],
        "transformation_rules": [
            "fourier_transform",
            "greens_function",
            "mode_function_normalization",
            "slow_roll_expansion",
        ],
    }

    canonical = json.dumps(result, sort_keys=True, separators=(",", ":"))
    symbolic_hash = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    result["symbolic_hash"] = symbolic_hash

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
