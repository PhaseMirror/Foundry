#!/usr/bin/env python3
"""Generate the CX-10 oracle artifacts.

Run once; the outputs are committed. NumPy is not a dependency of this
repository --- it is an oracle *outside* the Rust ecosystem entirely, which is
what settles lineage independence by construction (D-1). Every Rust GEMM crate
shares a language, a compiler, and often a kernel author; NumPy shares none of
those, so agreement with it is evidence of a different kind.

The element type is int64 and the accumulation is int64, so NumPy wraps exactly
where a two's complement accumulator does. That is the same ring homomorphism
this library relies on (S3.4), which is why the comparison is byte equality
with no exempted region.
"""

import hashlib
import json
import pathlib

import numpy as np

HERE = pathlib.Path(__file__).parent
SEED = 20260724

# Awkward on purpose: zero, one, primes, and a depth past int32 so that the
# wrapping half of the claim is exercised rather than assumed.
SHAPES = [
    (0, 0, 0), (1, 1, 1), (3, 7, 11), (13, 17, 19),
    (5, 97, 7), (8, 64, 8), (2, 4096, 2), (1, 100000, 1),
]


def xorshift(state):
    """The same generator the Rust corpus uses, so the fills are comparable."""
    while True:
        state ^= (state << 13) & 0xFFFFFFFFFFFFFFFF
        state ^= state >> 7
        state ^= (state << 17) & 0xFFFFFFFFFFFFFFFF
        yield np.int64(np.uint64(state >> 33).astype(np.int64) % 1000 - 500)


def main():
    cases = []
    gen = xorshift(SEED)
    for (m, k, n) in SHAPES:
        a = np.array([next(gen) for _ in range(m * k)], dtype=np.int64).reshape(m, k)
        b = np.array([next(gen) for _ in range(k * n)], dtype=np.int64).reshape(k, n)
        # int64 in, int64 out, wrapping on overflow --- the same semantics a
        # two's complement accumulator has.
        c = np.matmul(a, b, dtype=np.int64)

        stem = f"{m}x{k}x{n}"
        for name, arr in (("a", a), ("b", b), ("expected", c)):
            path = HERE / f"{stem}.{name}.bin"
            path.write_bytes(arr.astype("<i8").tobytes())
        cases.append({
            "shape": {"m": m, "k": k, "n": n},
            "a_sha256": "sha256:" + hashlib.sha256((HERE / f"{stem}.a.bin").read_bytes()).hexdigest(),
            "b_sha256": "sha256:" + hashlib.sha256((HERE / f"{stem}.b.bin").read_bytes()).hexdigest(),
            "expected_sha256": "sha256:" + hashlib.sha256(
                (HERE / f"{stem}.expected.bin").read_bytes()).hexdigest(),
            "stem": stem,
        })

    manifest = {
        "id": "CX-10",
        "oracle": "numpy",
        "numpy_version": np.__version__,
        "dtype": "int64",
        "byte_order": "little-endian",
        "entry": "numpy.matmul",
        "seed": SEED,
        "spec": "uor-matmul/1",
        "note": (
            "Out of process and outside the Rust ecosystem, which is the point: "
            "it settles lineage independence by construction. int64 accumulation "
            "wraps exactly where a two's complement accumulator does, so the "
            "comparison is byte equality with no exempted region."
        ),
        "cases": cases,
    }
    (HERE / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"wrote {len(cases)} cases against numpy {np.__version__}")


if __name__ == "__main__":
    main()
