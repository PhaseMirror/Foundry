#!/usr/bin/env python3
"""
Lobian Guard: Deterministic Gatekeeper for Spectral Parameter Modification.
Enforces the Ξ-Constitution v1.0 mandate for contractivity pre-checks.
"""

import sys
import json

def check_contractivity(spectral_radius):
    """
    Validates that the proposed spectral radius remains below the stability threshold.
    Metric: ρ ≤ 0.7 for specialized ensembles.
    """
    if spectral_radius <= 0.7:
        return True, "GREEN: Contractivity preserved."
    else:
        return False, f"REJECTED: Spectral radius {spectral_radius} violates the stability bound (ρ > 0.7)."

def main():
    if len(sys.argv) < 2:
        print("Usage: lobian_guard.py <spectral_radius>")
        sys.exit(1)

    try:
        rho = float(sys.argv[1])
    except ValueError:
        print("Error: Spectral radius must be a float.")
        sys.exit(1)

    is_safe, message = check_contractivity(rho)
    
    result = {
        "status": "PASS" if is_safe else "FAIL",
        "message": message,
        "rho": rho,
        "threshold": 0.7
    }

    print(json.dumps(result, indent=2))
    
    if not is_safe:
        sys.exit(1)

if __name__ == "__main__":
    main()
