#!/usr/bin/env python3
"""
Exploratory Defect Script for Generalized Prime-Composition Functors (Option 5)
==============================================================================
Tests affine transformations T_{a,b}(s) = a*s + b where both s and p = T(s) are prime.
Evaluates the non-vanishing sums |S(γ)| over the generated prime channels for the first 20 zeros.
Identifies functors that maintain a strong non-vanishing bound.
"""

import math
import itertools

P_MAX = 1_000_000
ZERO_FILE = "data/zeros_100.txt"
TEST_ZEROS_COUNT = 20

def prime_sieve(n: int):
    is_prime = bytearray(b'\x01') * (n + 1)
    if n >= 0: is_prime[0] = 0
    if n >= 1: is_prime[1] = 0
    for i in range(2, int(n ** 0.5) + 1):
        if is_prime[i]:
            step = i
            start = i * i
            is_prime[start:n+1:step] = b'\x00' * ((n - start) // step + 1)
    return is_prime

def get_affine_primes(a: int, b: int, limit: int, is_prime: bytearray):
    """Generate primes p = a*s + b <= limit where s is also prime."""
    for s in range(2, limit):
        if not is_prime[s]:
            continue
        p = a * s + b
        if p > limit:
            break
        if p >= 2 and is_prime[p]:
            yield p

def main():
    try:
        with open(ZERO_FILE, "r") as f:
            gammas = [float(line.strip()) for line in f if line.strip()][:TEST_ZEROS_COUNT]
    except FileNotFoundError:
        print(f"File {ZERO_FILE} not found.")
        return

    print(f"Building prime sieve up to {P_MAX}...")
    is_prime = prime_sieve(P_MAX)

    # Grid of (a, b) to test
    a_vals = [1, 2, 3, 4, 6]
    b_vals = [-5, -3, -1, 1, 2, 3, 5]
    
    results = []
    print(f"{'Functor':<12} | {'Primes Count':<12} | {'Min |S(γ)|':<12} | {'Max |S(γ)|':<12}")
    print("-" * 58)

    for a, b in itertools.product(a_vals, b_vals):
        # Skip trivial or highly degenerate cases
        if math.gcd(a, abs(b)) > 1:
            continue
            
        affine_p = list(get_affine_primes(a, b, P_MAX, is_prime))
        if len(affine_p) < 100:
            continue
            
        min_abs = float('inf')
        max_abs = 0.0
        
        for gamma in gammas:
            re = 0.0
            im = 0.0
            for p in affine_p:
                logp = math.log(p)
                amp = logp / math.sqrt(p)
                phase = gamma * logp
                re += amp * math.cos(phase)
                im -= amp * math.sin(phase)
            abs_val = math.hypot(re, im)
            if abs_val < min_abs:
                min_abs = abs_val
            if abs_val > max_abs:
                max_abs = abs_val
                
        results.append({
            "a": a,
            "b": b,
            "count": len(affine_p),
            "min_s": min_abs,
            "max_s": max_abs
        })
        
        functor_label = f"T(s)={a}s+{b}" if b >= 0 else f"T(s)={a}s{b}"
        print(f"{functor_label:<12} | {len(affine_p):<12} | {min_abs:<12.6f} | {max_abs:<12.6f}")

    results.sort(key=lambda x: x['min_s'], reverse=True)
    print("\nBest functors (highest minimum bounds, representing most stable channels):")
    for r in results[:5]:
        b_str = f"+{r['b']}" if r['b'] >= 0 else f"{r['b']}"
        print(f"T(s) = {r['a']}s {b_str:<3} : Min |S| = {r['min_s']:.6f} (Primes mapped: {r['count']})")

if __name__ == "__main__":
    main()
