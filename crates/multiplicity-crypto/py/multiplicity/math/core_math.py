import sympy
import numpy as np
from sympy import primefactors, factorint
from functools import reduce

# Try to get dynamic Λ_m from protocols
try:
    from multiplicity.cert.lambda_m_protocols import derive_lambda_m
    Λ_m = float(derive_lambda_m().get("lambda_m", 1.61803398875))
except (ImportError, Exception):
    Λ_m = 1.61803398875  # Universal Multiplicity Constant (fallback)

def get_lambda_m():
    """Return the current dynamic Λ_m constant."""
    return Λ_m

def lawful(n):
    """
    Check if a number is prime-lawful: all v_p(n) <= log_p(Λ_m).
    """
    if n <= 1:
        return True
    factors = factorint(n)
    return all(
        factors.get(p, 0) <= np.log(Λ_m)/np.log(p)
        for p in factors.keys()
    )

def entropy(n):
    """
    Compute entropic complexity Sp(n) = sum of p-adic depths.
    """
    if n <= 1:
        return 0.0
    factors = factorint(n)
    return float(sum(factors.values()))

def Ξ(n, depth=5):
    """
    Recursive factorization loop for stability.
    """
    history = [n]
    for _ in range(depth):
        factors = primefactors(history[-1])
        recomposed = reduce(lambda x, y: x * y, factors, 1)
        history.append(recomposed)
        if history[-1] == history[-2]:
            break
    return history[-1]
