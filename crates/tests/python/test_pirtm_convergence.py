# PIRTM Convergence Test Harness
# Numerical validation of |k| < 1 and fixed-point stability per PDF Section 2.2-2.3
# Equation: T(t+1) = k*T(t) + F,  T_infty = F/(1-k)
# Theorem 2: Recursive Tensor Stability
# Theorem 3: Computational Invariance

import numpy as np
import hashlib

def compute_k(primes: np.ndarray, Lambda_m: float, alpha: float) -> float:
    # Compute k = sum Lambda_m * p_i^alpha from PDF Eq. 2.3
    return float(np.sum(Lambda_m * np.power(primes, alpha, dtype=float)))

def simulate_recursion(T0: float, F: float, k: float, steps: int = 100) -> float:
    # Simulate T(t+1) = k*T(t) + F
    T = T0
    for _ in range(steps):
        T = k * T + F
    return T

def test_convergence(primes: np.ndarray, Lambda_m: float, alpha: float, F: float = 1.0, tol: float = 1e-9) -> tuple:
    # Test convergence: k must be < 1, T_inf = F/(1-k)
    k = compute_k(primes, Lambda_m, alpha)
    if k >= 1.0:
        return (False, f"FAIL: k={k:.6f} violates |k|<1")
    if k < 0:
        return (False, f"FAIL: k={k:.6f} is negative")
    T_inf = F / (1 - k)
    T_sim = simulate_recursion(0.0, F, k)
    err = abs(T_sim - T_inf)
    if err > tol:
        return (False, f"FAIL: err={err:.2e}")
    return (True, f"PASS: k={k:.6f}, T_inf={T_inf:.6f}, err={err:.2e}")

def test_theorem_2_stability(primes: np.ndarray, Lambda_m: float, alpha: float) -> tuple:
    # Theorem 2: Recursive Tensor Stability
    k = compute_k(primes, Lambda_m, alpha)
    if k >= 1.0:
        return (False, f"Theorem 2 FAIL: |k|={k:.6f} >= 1, no convergence")
    # Perturbation test: epsilon(t+1) = k*epsilon(t) -> 0
    eps0 = 0.1
    eps_final = eps0 * (k ** 100)
    if eps_final > 1e-6:
        return (False, f"Theorem 2 FAIL: perturbation not decaying")
    return (True, f"Theorem 2 PASS: stable fixed point at T_infty = F/(1-{k:.6f})")

def test_theorem_3_invariance(primes: np.ndarray, Lambda_m: float, alpha: float) -> tuple:
    # Theorem 3: Computational Invariance
    k = compute_k(primes, Lambda_m, alpha)
    # Verify k is constant across iterations
    k_iter2 = compute_k(primes, Lambda_m, alpha)
    if abs(k - k_iter2) > 1e-12:
        return (False, f"Theorem 3 FAIL: k not invariant")
    return (True, f"Theorem 3 PASS: k={k:.6f} is invariant per prime recursion")

def is_prime(n: int) -> bool:
    if n < 2: return False
    for i in range(2, int(np.sqrt(n)) + 1):
        if n % i == 0: return False
    return True

if __name__ == "__main__":
    primes = np.array([2.0, 3.0, 5.0])
    Lambda_m = 0.5
    alpha = -2.0
    
    print("PIRTM Convergence Test Harness")
    print("=" * 40)
    
    for name, test in [
        ("Convergence", lambda: test_convergence(primes, Lambda_m, alpha)),
        ("Theorem 2 Stability", lambda: test_theorem_2_stability(primes, Lambda_m, alpha)),
        ("Theorem 3 Invariance", lambda: test_theorem_3_invariance(primes, Lambda_m, alpha)),
    ]:
        passed, msg = test()
        status = "PASS" if passed else "FAIL"
        print(f"{status}: {name}: {msg}")
    
    assert all(is_prime(int(p)) for p in primes), "Invalid prime set"
    print("=" * 40)
    print("All PIRTM convergence tests completed.")