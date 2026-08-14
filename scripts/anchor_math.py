#!/usr/bin/env python3
"""anchor_math.py — canonical UAC State Anchor root math (ADR-PML-055).

This is the single source of truth for how operational state hashes collapse
into the on-chain anchor root. It mirrors exactly the computation in
`sidecar/state-anchor/index.ts`:

    per_category_root(events) = keccak256 binary Merkle tree over
                                  SHA-256(leaf payload) leaves
    combined_root            = SHA-256( governance || orchestrator ||
                                  chemistry  || proofs || attestations )

Keeping this in Python lets the offline integration test (and
`scripts/verify_anchor.py`) reconstruct the *exact* root the TypeScript
sidecar would submit, without requiring a live EVM/NATS deployment.
"""
from __future__ import annotations

import hashlib
import shutil
import subprocess
from pathlib import Path
from typing import Iterable

CATEGORY_ORDER = ["governance", "orchestrator", "chemistry", "proofs", "attestations"]


def sha256(b: bytes) -> bytes:
    return hashlib.sha256(b).digest()


def keccak256(b: bytes) -> bytes:
    """Keccak-256 (Ethereum variant).

    Delegates to `ethers.keccak256` via Node so the result is
    byte-identical to the TypeScript sidecar's computation. This is the
    canonical keccak used by the contract/sidecar; a pure-Python copy
    would risk diverging from `ethers`.
    """
    import shutil
    import subprocess

    node = shutil.which("node")
    if node is None:
        raise RuntimeError("node is required for keccak256; install Node.js.")
    script = (
        "const {keccak256}=require('ethers');"
        "const b=Buffer.from(process.argv[1].slice(2),'hex');"
        "process.stdout.write(keccak256(b).slice(2));"
    )
    out = subprocess.run(
        [node, "-e", script, "0x" + b.hex()],
        cwd=_ethers_cwd(),
        capture_output=True,
        check=True,
    )
    return bytes.fromhex(out.stdout.decode().strip())


def _ethers_cwd() -> str:
    """Resolve a directory that can `require('ethers')` (the sidecar's node_modules)."""
    here = Path(__file__).resolve().parent
    candidates = [
        here.parent / "sidecar" / "node_modules",
        here.parent / "sidecar" / "state-anchor" / "node_modules",
        here / "node_modules",
    ]
    for c in candidates:
        if (c / "ethers" / "package.json").exists():
            return str(c.parent)
    # Fall back to current dir; require('ethers') may still resolve via hoisting.
    return str(here)


def zero_hash() -> bytes:
    return bytes(32)


def leaf_hash(payload_hash: str) -> bytes:
    h = payload_hash[2:] if payload_hash.startswith("0x") else payload_hash
    return bytes.fromhex(h)


def category_root(events: Iterable[str]) -> bytes:
    """Binary Merkle root over a category's leaf payload hashes (keccak256 pairwise)."""
    leaves = [leaf_hash(h) for h in events]
    if not leaves:
        return zero_hash()
    while len(leaves) > 1:
        if len(leaves) % 2 == 1:
            leaves.append(leaves[-1])
        leaves = [keccak256(leaves[i] + leaves[i + 1]) for i in range(0, len(leaves), 2)]
    return leaves[0]


def combined_root(roots: dict[str, bytes]) -> bytes:
    """SHA-256 of the concatenation of the five category roots, in fixed order."""
    packed = b"".join(roots[c] for c in CATEGORY_ORDER)
    return sha256(packed)


def combined_root_from_events(per_category_events: dict[str, list[str]]) -> bytes:
    roots = {c: category_root(per_category_events.get(c, [])) for c in CATEGORY_ORDER}
    return combined_root(roots)
