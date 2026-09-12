#!/usr/bin/env python3
"""
al-gft-derive — Step 1: Action Specification

Defines the total action S_total[φ,χ] for the GFT field φ and the
Zeta-Comb environment χ, including the interaction g ∫ φ χ.

Outputs JSON to stdout with:
  - expression_tree: canonical symbolic structure
  - assumptions: list of physical assumptions
  - transformation_rules: algebraic steps applied
  - symbolic_hash: SHA-256 of canonical JSON
"""

import json
import hashlib
import sympy as sp

def main() -> None:
    # Define symbols and functions
    t = sp.Symbol("t", real=True)
    g = sp.Symbol("g", positive=True, real=True)
    m_eff = sp.Symbol("m_eff", positive=True, real=True)
    phi = sp.Function("phi")
    chi = sp.Function("chi")

    # GFT action (simplified quadratic)
    # S_GFT = 1/2 ∫ [ (∂_t φ)^2 + m_eff^2 φ^2 ] dt
    dphi = sp.Function("dphi")
    S_GFT = sp.Integral(
        sp.Mul(sp.Rational(1, 2), sp.Add(sp.Symbol("dphi")**2, m_eff**2 * phi(t)**2)),
        (t, -sp.oo, sp.oo),
    )

    # Environment action for Zeta-Comb χ
    # S_env = 1/2 ∫ [ (∂_t χ)^2 + ω(τ)^2 χ^2 ] dt
    omega = sp.Function("omega")
    dchi = sp.Function("dchi")
    S_env = sp.Integral(
        sp.Mul(sp.Rational(1, 2), sp.Add(sp.Symbol("dchi")**2, omega(t)**2 * chi(t)**2)),
        (t, -sp.oo, sp.oo),
    )

    # Interaction term: S_int = g ∫ φ χ dt
    S_int = sp.Integral(g * phi(t) * chi(t), (t, -sp.oo, sp.oo))

    # Total action
    S_total = sp.Add(S_GFT, S_env, S_int)

    # Build expression tree as JSON-serializable dict
    expression_tree = {
        "type": "Add",
        "operands": [
            {
                "type": "Integral",
                "id": "S_GFT",
                "integrand": {
                    "type": "Mul",
                    "operands": [
                        {"type": "Rational", "n": 1, "d": 2},
                        {
                            "type": "Add",
                            "operands": [
                                {"type": "Pow", "base": {"type": "Symbol", "name": "dphi"}, "exp": {"type": "Rational", "n": 2, "d": 1}},
                                {
                                    "type": "Pow",
                                    "base": {"type": "Symbol", "name": "m_eff"},
                                    "exp": {"type": "Rational", "n": 2, "d": 1},
                                },
                                {"type": "Pow", "base": {"type": "Function", "name": "phi", "args": [{"type": "Symbol", "name": "t"}]}, "exp": {"type": "Rational", "n": 2, "d": 1}},
                            ],
                        },
                    ],
                },
                "limits": {"type": "Interval", "start": "-oo", "end": "oo", "var": "t"},
            },
            {
                "type": "Integral",
                "id": "S_env",
                "integrand": {
                    "type": "Mul",
                    "operands": [
                        {"type": "Rational", "n": 1, "d": 2},
                        {
                            "type": "Add",
                            "operands": [
                                {"type": "Pow", "base": {"type": "Symbol", "name": "dchi"}, "exp": {"type": "Rational", "n": 2, "d": 1}},
                                {
                                    "type": "Pow",
                                    "base": {"type": "Function", "name": "omega", "args": [{"type": "Symbol", "name": "t"}]},
                                    "exp": {"type": "Rational", "n": 2, "d": 1},
                                },
                                {"type": "Pow", "base": {"type": "Function", "name": "chi", "args": [{"type": "Symbol", "name": "t"}]}, "exp": {"type": "Rational", "n": 2, "d": 1}},
                            ],
                        },
                    ],
                },
                "limits": {"type": "Interval", "start": "-oo", "end": "oo", "var": "t"},
            },
            {
                "type": "Integral",
                "id": "S_int",
                "integrand": {
                    "type": "Mul",
                    "operands": [
                        {"type": "Symbol", "name": "g"},
                        {"type": "Function", "name": "phi", "args": [{"type": "Symbol", "name": "t"}]},
                        {"type": "Function", "name": "chi", "args": [{"type": "Symbol", "name": "t"}]},
                    ],
                },
                "limits": {"type": "Interval", "start": "-oo", "end": "oo", "var": "t"},
            },
        ],
    }

    result = {
        "step": "action_specification",
        "version": "1.0",
        "expression_tree": expression_tree,
        "assumptions": [
            "gaussian_field",
            "linear_coupling",
            "zeta_comb_environment",
            "quadratic_action",
        ],
        "transformation_rules": [
            "canonical_form",
            "field_separation",
            "quadratic_decomposition",
        ],
        "params": {
            "g": str(g),
            "m_eff": str(m_eff),
            "fields": ["phi", "chi"],
        },
    }

    canonical = json.dumps(result, sort_keys=True, separators=(",", ":"))
    symbolic_hash = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    result["symbolic_hash"] = symbolic_hash

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
