import numpy as np
from scipy import stats
from sympy import nextprime
import math

PHI = (1 + 5**0.5) / 2

def sieve_primes(n):
    primes = []
    p = 2
    while len(primes) < n:
        primes.append(p)
        p = nextprime(p)
    return primes

def xi(p): return np.log(p) / np.log(PHI)

def build_prime_weights(n):
    primes = sieve_primes(n)
    w = np.array([1.0 / xi(p) for p in primes])
    return w / w.sum()

def build_random_weights(n, seed=42):
    rng = np.random.default_rng(seed)
    w = rng.uniform(0, 1, n)
    return w / w.sum()

def contraction_step(T, k, F, weights):
    return k * np.tanh(weights * T) + F

def l_eff_samples(weights, k, n_samples=1000):
    rng = np.random.default_rng(0)
    T1 = rng.standard_normal((n_samples, len(weights)))
    T2 = rng.standard_normal((n_samples, len(weights)))
    F = rng.standard_normal(len(weights))
    out1 = np.array([contraction_step(t, k, F, weights) for t in T1])
    out2 = np.array([contraction_step(t, k, F, weights) for t in T2])
    diffs_in  = np.linalg.norm(T1 - T2, axis=1)
    diffs_out = np.linalg.norm(out1 - out2, axis=1)
    ratios = diffs_out / (diffs_in + 1e-12)
    return ratios

def cohens_d(x, y):
    nx = len(x)
    ny = len(y)
    dof = nx + ny - 2
    return (np.mean(x) - np.mean(y)) / np.sqrt(((nx-1)*np.std(x, ddof=1)**2 + (ny-1)*np.std(y, ddof=1)**2) / dof)

def run_analysis(N, TRIALS=1000, k=0.5):
    p_weights = build_prime_weights(N)
    r_weights = build_random_weights(N)

    p_leff = l_eff_samples(p_weights, k, TRIALS)
    r_leff = l_eff_samples(r_weights, k, TRIALS)

    d = cohens_d(p_leff, r_leff)
    
    # Convergence iters
    def convergence_iters(weights, k_val, tol=1e-6, max_iter=500):
        rng = np.random.default_rng(0)
        counts = []
        for _ in range(TRIALS):
            F = rng.standard_normal(len(weights))
            T = rng.standard_normal(len(weights))
            for i in range(max_iter):
                T_new = contraction_step(T, k_val, F, weights)
                if np.linalg.norm(T_new - T) < tol:
                    counts.append(i + 1)
                    break
                T = T_new
            else:
                counts.append(max_iter)
        return np.array(counts)

    p_iters = convergence_iters(p_weights, k)
    r_iters = convergence_iters(r_weights, k)
    
    ks_stat, pval = stats.ks_2samp(p_iters, r_iters)
    
    print(f"--- Analysis for dim={N} ---")
    print(f"Prime L_eff mean:  {np.mean(p_leff):.6f} ± {np.std(p_leff):.6f}")
    print(f"Random L_eff mean: {np.mean(r_leff):.6f} ± {np.std(r_leff):.6f}")
    print(f"Cohen's d:         {d:.4f}")
    print(f"KS p-value:        {pval:.4e}")
    print(f"Prime mean iters:  {np.mean(p_iters):.2f}")
    print(f"Random mean iters: {np.mean(r_iters):.2f}")
    
    # CI Thresholds
    KS_P_THRESHOLD = 0.05
    COHENS_D_MIN = 0.2
    
    if pval > KS_P_THRESHOLD:
        print(f"FAIL: KS p-value {pval:.4e} > {KS_P_THRESHOLD}")
        return False
    if d < COHENS_D_MIN:
        print(f"FAIL: Cohen's d {d:.4f} < {COHENS_D_MIN}")
        return False
        
    print("PASS: Structural signal verified.")
    return True

if __name__ == "__main__":
    import sys
    if not run_analysis(128):
        sys.exit(1)
    sys.exit(0)
