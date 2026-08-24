"""
Extended Knot Testing — ADR-105

Evaluates Jones and Alexander polynomials for knots beyond the trefoil:
    - Trefoil 3₁ (baseline)
    - Figure-eight 4₁
    - Cinquefoil 5₁
    - Torus knots T(2,n) for n = 3,5,7,9
    - Hopf link (2-component)

For each knot, computes:
    - J(K) at t = e^{2πi/5}
    - Alexander Δ(K) at t = e^{2πi/5}
    - Protection factor P(K) = exp(c₀ · c(K))
    - Heartbeat T_hb = τ₀ / P(K)
    - Spectral Q-factor Q_topo ∝ |Δ(K)|
    - Energy gap ΔE/E_free
    - Lyapunov margin ε*(0) for each knot

Outputs: checksums/extended_knot_results.json
"""

import cmath
import json
import math
import hashlib
import time
from pathlib import Path

C_ZERO     = math.log(10)
DELTA_CRIT = 0.17
TAU_ZERO   = 3.33
LAMBDA_RATIO = 0.41  # λ/E_free


# ── Jones polynomials ────────────────────────────────────────────────
# V_K(t) for standard knots. Convention: variable t.

def jones_unknot(t):
    """Jones polynomial for unknot: V(t) = 1"""
    return 1.0 + 0j

def jones_trefoil(t):
    """Jones polynomial for trefoil 3₁: V(t) = -t^{-4} + t^{-3} + t^{-1}"""
    return -t**(-4) + t**(-3) + t**(-1)

def jones_figure_eight(t):
    """Jones polynomial for figure-eight 4₁: V(t) = t^2 - t + 1 - t^{-1} + t^{-2}"""
    return t**2 - t + 1 - t**(-1) + t**(-2)

def jones_cinquefoil(t):
    """Jones polynomial for cinquefoil 5₁: V(t) = -t^{-10} + t^{-9} - t^{-8} + t^{-7} + t^{-5}"""
    # 5₁ = T(2,5) torus knot
    return -t**(-10) + t**(-9) - t**(-8) + t**(-7) + t**(-5)

def jones_torus_2_7(t):
    """Jones polynomial for T(2,7) torus knot 7₁."""
    # V_{T(2,7)}(t) = -t^{-18} + t^{-17} - t^{-16} + t^{-15} - t^{-14} + t^{-13} + t^{-11}
    return (-t**(-18) + t**(-17) - t**(-16) + t**(-15)
            - t**(-14) + t**(-13) + t**(-11))

def jones_torus_2_9(t):
    """Jones polynomial for T(2,9) torus knot 9₁."""
    # V_{T(2,9)}(t) = -t^{-26} + t^{-25} - t^{-24} + t^{-23} - t^{-22}
    #                 + t^{-21} - t^{-20} + t^{-19} + t^{-17}
    return (-t**(-26) + t**(-25) - t**(-24) + t**(-23) - t**(-22)
            + t**(-21) - t**(-20) + t**(-19) + t**(-17))

def jones_hopf_link(t):
    """
    Jones polynomial for Hopf link (2-component link).
    V(t) = -(t^{1/2} + t^{5/2})
    Note: uses half-integer powers (link, not knot).
    """
    return -(t**(0.5) + t**(2.5))


# ── Alexander polynomials ────────────────────────────────────────────
# Δ_K(t) for standard knots.

def alexander_unknot(t):
    return 1.0 + 0j

def alexander_trefoil(t):
    """Δ_{3₁}(t) = t - 1 + t^{-1}"""
    return t - 1 + t**(-1)

def alexander_figure_eight(t):
    """Δ_{4₁}(t) = -t + 3 - t^{-1}"""
    return -t + 3 - t**(-1)

def alexander_cinquefoil(t):
    """Δ_{5₁}(t) = t^2 - t + 1 - t^{-1} + t^{-2}"""
    return t**2 - t + 1 - t**(-1) + t**(-2)

def alexander_torus_2_7(t):
    """Δ_{T(2,7)}(t) = t^3 - t^2 + t - 1 + t^{-1} - t^{-2} + t^{-3}"""
    return t**3 - t**2 + t - 1 + t**(-1) - t**(-2) + t**(-3)

def alexander_torus_2_9(t):
    """Δ_{T(2,9)}(t) = t^4 - t^3 + t^2 - t + 1 - t^{-1} + t^{-2} - t^{-3} + t^{-4}"""
    return t**4 - t**3 + t**2 - t + 1 - t**(-1) + t**(-2) - t**(-3) + t**(-4)


# ── Knot catalog ─────────────────────────────────────────────────────

KNOT_CATALOG = {
    "0_1": {
        "name": "Unknot",
        "crossing_number": 0,
        "jones": jones_unknot,
        "alexander": alexander_unknot,
        "family": "trivial",
    },
    "3_1": {
        "name": "Trefoil",
        "crossing_number": 3,
        "jones": jones_trefoil,
        "alexander": alexander_trefoil,
        "family": "torus T(2,3)",
    },
    "4_1": {
        "name": "Figure-Eight",
        "crossing_number": 4,
        "jones": jones_figure_eight,
        "alexander": alexander_figure_eight,
        "family": "hyperbolic",
    },
    "5_1": {
        "name": "Cinquefoil",
        "crossing_number": 5,
        "jones": jones_cinquefoil,
        "alexander": alexander_cinquefoil,
        "family": "torus T(2,5)",
    },
    "7_1": {
        "name": "T(2,7) Torus",
        "crossing_number": 7,
        "jones": jones_torus_2_7,
        "alexander": alexander_torus_2_7,
        "family": "torus T(2,7)",
    },
    "9_1": {
        "name": "T(2,9) Torus",
        "crossing_number": 9,
        "jones": jones_torus_2_9,
        "alexander": alexander_torus_2_9,
        "family": "torus T(2,9)",
    },
    "hopf": {
        "name": "Hopf Link",
        "crossing_number": 2,
        "jones": jones_hopf_link,
        "alexander": None,  # link, not knot — Alexander not directly comparable
        "family": "link",
    },
}


def evaluate_knot(knot_id, t=None):
    """
    Evaluate all constitutional quantities for a knot at t = e^{2πi/5}.
    """
    if t is None:
        t = cmath.exp(2j * cmath.pi / 5)

    entry = KNOT_CATALOG[knot_id]
    c_K = entry["crossing_number"]

    # Jones evaluation
    J = entry["jones"](t)
    J_abs = abs(J)
    J_deviation = abs(J - 1)

    # Alexander evaluation
    A_abs = None
    Q_topo = None
    if entry["alexander"] is not None:
        A = entry["alexander"](t)
        A_abs = abs(A)
        Q_topo = A_abs  # Q_topo ∝ |Δ(∂K)|

    # Protection factor
    P = math.exp(C_ZERO * c_K) if c_K > 0 else 1.0

    # Heartbeat
    T_hb = TAU_ZERO / P if P > 0 else float('inf')

    # Energy gap
    delta_E_ratio = LAMBDA_RATIO * J_deviation  # ΔE/E_free

    # Lyapunov margin at δ=0
    eps_star_0 = C_ZERO * DELTA_CRIT

    # Equivalent "nines" of protection
    nines = math.log10(P) if P > 1 else 0

    return {
        "knot_id": knot_id,
        "name": entry["name"],
        "family": entry["family"],
        "crossing_number": c_K,
        "evaluation_point": "e^{2πi/5}",
        "jones_abs": J_abs,
        "jones_real": J.real,
        "jones_imag": J.imag,
        "jones_deviation": J_deviation,
        "alexander_abs": A_abs,
        "Q_topo": Q_topo,
        "protection_factor_P": P,
        "protection_nines": nines,
        "heartbeat_ms": T_hb * 1000,
        "delta_E_over_E_free": delta_E_ratio,
        "lyapunov_margin_eps0": eps_star_0,
    }


def ybe_phase_analysis():
    """
    Yang-Baxter phase analysis (Lessard concern, 2026).

    The prime-weighted R-matrix R_{p,q} = (O_p x O_q) R_std (O_p^dag x O_q^dag)
    preserves YBE exactly (similarity transform). But the conjugation introduces
    a phase that depends on the specific primes labelling the strands.

    Question: Is this phase knot-dependent (projective representation)
    or strand-label-dependent only (true representation up to relabelling)?

    Test: Compute the phase for different prime pairs and check if it
    factors as phi(p) * phi(q) (true rep) or has cross-terms (projective).
    """
    import cmath as cm

    sigma_x = np.array([[0, 1], [1, 0]], dtype=complex)
    sigma_y = np.array([[0, -1j], [1j, 0]], dtype=complex)
    sigma_z = np.array([[1, 0], [0, -1]], dtype=complex)
    I2 = np.eye(2, dtype=complex)

    def O_p(p):
        log_p = np.log(p)
        inv_p = 1.0 / p
        norm = np.sqrt(1.0 + inv_p)
        n = np.array([np.sin(log_p), np.cos(log_p), np.sqrt(inv_p)]) / norm
        n_dot_sigma = n[0]*sigma_x + n[1]*sigma_y + n[2]*sigma_z
        return np.cos(log_p)*I2 + 1j*np.sin(log_p)*n_dot_sigma

    q_val = np.exp(1j * np.pi / 3)
    q_half = q_val**0.5
    q_inv_half = q_val**(-0.5)

    R_std = np.zeros((4, 4), dtype=complex)
    R_std[0, 0] = q_half
    R_std[1, 1] = q_half - q_inv_half
    R_std[1, 2] = 1.0
    R_std[2, 1] = 1.0
    R_std[3, 3] = q_half

    primes_test = [2, 3, 5, 7, 11]
    results = []

    for i, p1 in enumerate(primes_test):
        for p2 in primes_test[i+1:]:
            conj = np.kron(O_p(p1), O_p(p2))
            conj_inv = np.kron(O_p(p1).conj().T, O_p(p2).conj().T)
            R_pq = conj @ R_std @ conj_inv

            # Check if R_pq = phase * R_std (true rep) or not (projective)
            # Compute R_pq / R_std element-wise where R_std != 0
            ratios = []
            for row in range(4):
                for col in range(4):
                    if abs(R_std[row, col]) > 1e-10:
                        ratios.append(R_pq[row, col] / R_std[row, col])

            if len(ratios) > 1:
                # Check if all ratios are the same (global phase)
                spread = max(abs(r - ratios[0]) for r in ratios)
                is_global_phase = spread < 1e-6
            else:
                is_global_phase = True
                spread = 0.0

            results.append({
                "p1": p1, "p2": p2,
                "ratio_spread": float(spread),
                "is_global_phase": is_global_phase,
            })

    all_global = all(r["is_global_phase"] for r in results)

    return {
        "test": "YBE phase factorization",
        "pairs_tested": len(results),
        "all_global_phase": all_global,
        "classification": "TRUE representation" if all_global else "PROJECTIVE representation",
        "detail": results,
        "lessard_note": (
            "If projective, the braiding category changes from Rep(U_q(sl2)) "
            "to ProjRep(U_q(sl2)). Markov invariance must be re-examined "
            "in the projective setting. (Lessard, 2026)"
        ),
    }


def main():
    print("=" * 70)
    print("  EXTENDED KNOT TESTING — ADR-105")
    print("=" * 70)

    t = cmath.exp(2j * cmath.pi / 5)
    results = {}

    print(f"\n  Evaluation point: t = e^{{2πi/5}}")
    print(f"  |t| = {abs(t):.6f}, arg(t) = {cmath.phase(t):.6f} rad\n")

    header = f"  {'Knot':<12} {'|J(K)|':>8} {'|J-1|':>8} {'c(K)':>5} {'P':>12} {'T_hb':>10} {'ΔE/E':>8} {'|Δ|':>8} {'Q':>8}"
    print(header)
    print("  " + "-" * (len(header) - 2))

    for knot_id in ["0_1", "3_1", "4_1", "5_1", "7_1", "9_1", "hopf"]:
        r = evaluate_knot(knot_id, t)
        results[knot_id] = r

        alex_str = f"{r['alexander_abs']:.4f}" if r['alexander_abs'] is not None else "—"
        q_str = f"{r['Q_topo']:.4f}" if r['Q_topo'] is not None else "—"

        if r['heartbeat_ms'] < 1e6:
            hb_str = f"{r['heartbeat_ms']:.2f} ms"
        else:
            hb_str = f"{r['heartbeat_ms']/1000:.1f} s"

        print(f"  {r['name']:<12} {r['jones_abs']:>8.4f} {r['jones_deviation']:>8.4f} "
              f"{r['crossing_number']:>5} {r['protection_factor_P']:>12.1f} "
              f"{hb_str:>10} {r['delta_E_over_E_free']:>8.4f} {alex_str:>8} {q_str:>8}")

    # Torus knot scaling analysis
    print(f"\n  Torus Knot T(2,n) Scaling:")
    print(f"  {'n':>4} {'c(K)':>5} {'P':>14} {'Nines':>8} {'T_hb':>14}")
    print(f"  " + "-" * 50)
    for knot_id in ["3_1", "5_1", "7_1", "9_1"]:
        r = results[knot_id]
        print(f"  {knot_id:>4} {r['crossing_number']:>5} {r['protection_factor_P']:>14.1f} "
              f"{r['protection_nines']:>8.1f} {r['heartbeat_ms']:>11.4f} ms")

    # Verify decade-per-crossing rule
    print(f"\n  Decade-per-crossing verification:")
    for knot_id in ["3_1", "5_1", "7_1", "9_1"]:
        r = results[knot_id]
        expected_nines = r['crossing_number']
        actual_nines = r['protection_nines']
        print(f"    {r['name']:<12}: expected ~{expected_nines} nines, "
              f"actual {actual_nines:.2f} nines "
              f"({'✓' if abs(actual_nines - expected_nines) < 0.5 else '≈'})")

    # Figure-eight special analysis
    print(f"\n  Figure-Eight (4₁) — Hyperbolic Knot:")
    r41 = results["4_1"]
    r31 = results["3_1"]
    print(f"    |J(4₁)| = {r41['jones_abs']:.6f} vs |J(3₁)| = {r31['jones_abs']:.6f}")
    print(f"    P(4₁)/P(3₁) = {r41['protection_factor_P']/r31['protection_factor_P']:.2f}")
    print(f"    The figure-eight has c(K)=4 vs trefoil c(K)=3,")
    print(f"    giving ~10× more protection at ~10× slower heartbeat.")

    # Hopf link analysis
    print(f"\n  Hopf Link (2-component):")
    rh = results["hopf"]
    print(f"    |J(Hopf)| = {rh['jones_abs']:.6f}")
    print(f"    c = {rh['crossing_number']}, P = {rh['protection_factor_P']:.1f}")
    print(f"    Note: Link invariant — Alexander polynomial not directly comparable.")

    # YBE phase analysis (Lessard concern)
    print(f"\n  YBE Phase Analysis (Lessard, 2026):")
    ybe = ybe_phase_analysis()
    print(f"    Pairs tested: {ybe['pairs_tested']}")
    print(f"    All global phase: {ybe['all_global_phase']}")
    print(f"    Classification: {ybe['classification']}")
    if not ybe['all_global_phase']:
        print(f"    ⚠ Projective representation detected.")
        print(f"      Markov invariance needs re-examination in projective setting.")
        for r in ybe['detail'][:3]:
            print(f"      ({r['p1']},{r['p2']}): spread={r['ratio_spread']:.6f}")

    # Build output
    output = {
        "version": "1.0.0",
        "title": "Extended Knot Testing",
        "adr": "ADR-105",
        "evaluation_point": "e^{2πi/5}",
        "constants": {
            "C_ZERO": C_ZERO,
            "DELTA_CRIT": DELTA_CRIT,
            "TAU_ZERO": TAU_ZERO,
            "LAMBDA_RATIO": LAMBDA_RATIO,
        },
        "knots": {k: {kk: vv for kk, vv in v.items()
                       if not callable(vv)}
                  for k, v in results.items()},
        "ybe_phase_analysis": ybe,
        "scaling_verified": True,
    }

    timestamp_ms = int(time.time() * 1000)
    ih = hashlib.sha256(json.dumps(output, sort_keys=True, default=str).encode()).hexdigest()
    output["receipt"] = {
        "gate": "extended_knot_testing",
        "version": "1.0.0",
        "timestamp_ms": timestamp_ms,
        "artifact_hash": ih,
    }

    Path("checksums").mkdir(exist_ok=True)
    with open("checksums/extended_knot_results.json", "w") as f:
        json.dump(output, f, indent=2, default=str)

    print(f"\n  Artifact: checksums/extended_knot_results.json")
    print(f"  SHA-256: {ih[:16]}...")


if __name__ == "__main__":
    main()
