#!/usr/bin/env python3
"""
Extended Safe‑Prime Non‑Vanishing Validation (Option 2)
========================================================
For each imaginary part γ in zeros_100.txt, compute

    S(γ) = Σ_{p ≤ P_MAX, p safe}  log(p) / √p * exp(-i γ log p)

and verify |S(γ)| > ε (default 1e‑6). Uses a fast sieve up to 10^7.
Reports the minimum |S(γ)| and a pass/fail summary.
"""

import math
import sys
import time
import json

# ---------- Configuration ----------
P_MAX = 10_000_000          # upper bound for prime sieve
EPSILON = 1e-6              # non‑vanishing threshold
ZERO_FILE = "data/zeros_100.txt"
# -----------------------------------

# Sieve of Eratosthenes (bytearray for speed)
def prime_sieve(n: int):
    """Return a bytearray `is_prime` of length n+1, where is_prime[i]==1 iff i prime."""
    is_prime = bytearray(b'\x01') * (n + 1)
    if n >= 0:
        is_prime[0] = 0
    if n >= 1:
        is_prime[1] = 0
    for i in range(2, int(n ** 0.5) + 1):
        if is_prime[i]:
            step = i
            start = i * i
            is_prime[start:n+1:step] = b'\x00' * ((n - start) // step + 1)
    return is_prime

def safe_primes_from_sieve(limit: int, is_prime: bytearray):
    """Generate safe primes p = 2s+1 ≤ limit, where s and p are prime."""
    # we iterate over possible p (odd numbers), but better: iterate over s prime
    # and check if 2s+1 prime and ≤ limit.
    for s in range(2, (limit - 1) // 2 + 1):
        if is_prime[s]:
            p = 2 * s + 1
            if p <= limit and is_prime[p]:
                yield p

def main():
    try:
        with open(ZERO_FILE, "r") as f:
            gammas = [float(line.strip()) for line in f if line.strip()]
    except FileNotFoundError:
        print(f"File {ZERO_FILE} not found.")
        sys.exit(1)

    print(f"Building prime sieve up to {P_MAX}...", end=" ", flush=True)
    t0 = time.time()
    is_prime = prime_sieve(P_MAX)
    t1 = time.time()
    print(f"done ({t1 - t0:.2f}s)")

    print("Collecting safe primes...", end=" ", flush=True)
    safe_p = list(safe_primes_from_sieve(P_MAX, is_prime))
    t2 = time.time()
    print(f"{len(safe_p)} safe primes found ({t2 - t1:.2f}s)")

    min_abs = float("inf")
    results = []
    print("Evaluating S(γ) for each zero...")
    for n, gamma in enumerate(gammas, start=1):
        re = 0.0
        im = 0.0
        for p in safe_p:
            logp = math.log(p)
            amp = logp / math.sqrt(p)
            phase = gamma * logp
            re += amp * math.cos(phase)
            im -= amp * math.sin(phase)
        abs_val = math.hypot(re, im)
        results.append((n, gamma, abs_val))
        if abs_val < min_abs:
            min_abs = abs_val
        print(f"γ_{n:3d} = {gamma:12.8f}  |S| = {abs_val:.10f}")

    print(f"\nMinimum |S| among {len(gammas)} zeros: {min_abs:.10f}")
    
    result_data = {
        "p_max": P_MAX,
        "zeros_count": len(gammas),
        "min_abs_s": min_abs,
        "epsilon": EPSILON,
        "status": "PASS" if min_abs > EPSILON else "FAIL"
    }
    
    with open("safe_prime_cyclicity_status.json", "w") as f:
        json.dump(result_data, f, indent=2)

    if min_abs > EPSILON:
        print("✅  All sums bounded away from zero. Safe‑Prime Cyclicity passes.")
    else:
        print("❌  Some sum too close to zero – conjecture may be false or need larger P_MAX.")

if __name__ == "__main__":
    main()
