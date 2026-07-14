#!/usr/bin/env python3
import json
import argparse
from math import log
from itertools import product

def generate_basis(primes, max_exp):
    exponents = product(range(max_exp + 1), repeat=len(primes))
    numbers = []
    for exps in exponents:
        n = 1
        for p, e in zip(primes, exps):
            n *= p ** e
        if n > 0:
            numbers.append(n)
    return sorted(set(numbers))

def compute_valuations(numbers, primes):
    val_dict = {}
    for n in numbers:
        exps = []
        for p in primes:
            v = 0
            tmp = n
            while tmp % p == 0:
                v += 1
                tmp //= p
            exps.append(v)
        val_dict[str(n)] = exps
    return val_dict

def main():
    parser = argparse.ArgumentParser(description="Export basis factorization to JSON")
    parser.add_argument("--primes", type=str, default="2,3,5,7", help="Comma-separated primes")
    parser.add_argument("--max_exp", type=int, default=3, help="Maximum exponent per prime")
    parser.add_argument("--output", type=str, default="basis_factors.json", help="Output JSON file")
    args = parser.parse_args()

    primes = [int(p) for p in args.primes.split(",")]
    numbers = generate_basis(primes, args.max_exp)
    valuations = compute_valuations(numbers, primes)

    data = {
        "primes": primes,
        "max_exp": args.max_exp,
        "basis": [{"n": n, "exponents": valuations[str(n)]} for n in numbers]
    }

    with open(args.output, "w") as f:
        json.dump(data, f, indent=2)

    print(f"Exported {len(numbers)} numbers to {args.output}")

if __name__ == "__main__":
    main()
