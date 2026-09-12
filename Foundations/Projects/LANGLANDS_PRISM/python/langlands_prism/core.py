"""Core mathematical constants, prime generation, Dirichlet characters, and L-functions."""

import math

LAMBDA_M = 0.6180339887498949  # (sqrt(5) - 1) / 2
PHI = 1.6180339887498949       # (1 + sqrt(5)) / 2

DEFAULT_PRIMES_5 = [2, 3, 5, 7, 11]
DEFAULT_PRIMES_8 = [2, 3, 5, 7, 11, 13, 17, 19]

def is_prime(n: int) -> bool:
    """Trial division primality test."""
    if n < 2:
        return False
    if n in (2, 3):
        return True
    if n % 2 == 0 or n % 3 == 0:
        return False
    d = 5
    while d * d <= n:
        if n % d == 0 or n % (d + 2) == 0:
            return False
        d += 6
    return True

def sieve_primes(limit: int) -> list[int]:
    """Sieve of Eratosthenes."""
    if limit < 2:
        return []
    is_p = [True] * (limit + 1)
    is_p[0] = is_p[1] = False
    p = 2
    while p * p <= limit:
        if is_p[p]:
            for m in range(p * p, limit + 1, p):
                is_p[m] = False
        p += 1
    return [i for i, flag in enumerate(is_p) if flag]

def first_n_primes(n: int) -> list[int]:
    """Generate first n prime numbers."""
    primes = []
    cand = 2
    while len(primes) < n:
        if is_prime(cand):
            primes.append(cand)
        cand += 1
    return primes

def dirichlet_char_4(n: int) -> int:
    """Dirichlet character mod 4."""
    if n % 2 == 0:
        return 0
    elif n % 4 == 1:
        return 1
    else:
        return -1

def dirichlet_euler_factor(p: int, s: float = 1.0, chi: int | None = None) -> float:
    """Evaluate Dirichlet L-function Euler factor: (1 - chi(p)*p^-s)^-1."""
    if chi is None:
        chi = dirichlet_char_4(p)
    if chi == 0:
        return 1.0
    denom = 1.0 - (chi * (p ** (-s)))
    if abs(denom) < 1e-12:
        return 1e12
    return 1.0 / denom
