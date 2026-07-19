#!/usr/bin/env python3
"""verify_anchor.py — reconstruct and verify UAC State Anchor roots (ADR-PML-055).

This tool lets anyone independently verify that the off-chain WORM archive agrees
with the on-chain `AnchorRegistry` root for a given day.

Workflow:
  1. Reconstruct the combined Merkle root from the WORM archive state events.
  2. Fetch the on-chain root anchored at (or nearest before) a target date.
  3. Compare. A match is cryptographic proof that the operational record was
     not retroactively altered.

The combined root matches the contract/sidecar definition:
    combined = SHA256( governance || orchestrator || chemistry || proofs || attestation )
where each per-category root is a keccak256 binary Merkle tree over per-event
SHA-256 leaf hashes.

Usage:
    python scripts/verify_anchor.py --date 2026-07-18 \
        --worm-dir ./worm_archive \
        --rpc https://rpc.testnet.example \
        --registry 0xAbC... \
        --event-log ./worm_archive/state_events.jsonl
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

CATEGORY_ORDER = ["governance", "orchestrator", "chemistry", "proofs", "attestations"]

# Use the canonical anchor math from anchor_math.py when present so the
# reconstruction path is byte-identical to the sidecar's computation.
try:  # pragma: no cover - depends on CWD / packaging
    from anchor_math import category_root as _category_root, combined_root as _combined_root  # type: ignore
except Exception:  # pragma: no cover
    _category_root = None


def sha256_bytes(b: bytes) -> bytes:
    return hashlib.sha256(b).digest()


def keccak256(b: bytes) -> bytes:
    # eth_hash is the canonical keccak from the ethereum ecosystem; fall back to
    # a pure-python implementation only if unavailable.
    try:
        from eth_hash.auto import keccak as _keccak  # type: ignore
        return _keccak(b)
    except Exception:
        return _py_keccak256(b)


def _py_keccak256(b: bytes) -> bytes:
    """Minimal Keccak-256 (Ethereum variant) fallback.

    Raises a clear error if the user needs exact on-chain compatibility and
    should install `eth-hash[pycryptodome]` instead.
    """
    raise RuntimeError(
        "pycryptodome/eth-hash not available; install `pip install eth-hash[pycryptodome]` "
        "for exact keccak256 matching the on-chain contract."
    )


def zero_hash() -> bytes:
    return bytes(32)


@dataclass
class StateEvent:
    category: str
    payload_hash: str  # hex, with or without 0x

    def leaf(self) -> bytes:
        h = self.payload_hash
        if h.startswith("0x"):
            h = h[2:]
        return bytes.fromhex(h)


def category_root(events: list[StateEvent]) -> bytes:
    """Binary Merkle root over a category's events (keccak256 pairwise)."""
    if _category_root is not None:
        return _category_root([e.payload_hash for e in events])
    leaves = [e.leaf() for e in events]
    if not leaves:
        return zero_hash()
    while len(leaves) > 1:
        if len(leaves) % 2 == 1:
            leaves.append(leaves[-1])
        leaves = [keccak256(leaves[i] + leaves[i + 1]) for i in range(0, len(leaves), 2)]
    return leaves[0]


def combined_root(roots: dict[str, bytes]) -> bytes:
    if _combined_root is not None:
        return _combined_root(roots)
    packed = b"".join(roots[c] for c in CATEGORY_ORDER)
    return sha256_bytes(packed)


def reconstruct_from_events(events: list[StateEvent]) -> bytes:
    per_category: dict[str, list[StateEvent]] = {c: [] for c in CATEGORY_ORDER}
    for e in events:
        if e.category not in per_category:
            continue
        per_category[e.category].append(e)
    roots = {c: category_root(per_category[c]) for c in CATEGORY_ORDER}
    return combined_root(roots)


def load_events(event_log: Path) -> list[StateEvent]:
    events: list[StateEvent] = []
    with event_log.open() as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            category = obj.get("category") or obj.get("subject", "").split(".")[-1]
            payload_hash = obj.get("hash") or sha256_bytes(
                json.dumps(obj, sort_keys=True).encode()
            ).hex()
            events.append(StateEvent(category=category, payload_hash=payload_hash))
    return events


def fetch_onchain_root(rpc: str, registry: str, target_date: str) -> tuple[str, int] | None:
    """Return (root_hex, block_number) for the latest AnchorSubmitted at/before target_date.

    Uses a Web3 provider if available; otherwise requires --onchain-root override.
    """
    try:
        from web3 import Web3  # type: ignore
    except Exception:
        raise RuntimeError(
            "web3 not installed; pass --onchain-root <0x...> to skip RPC lookup."
        )
    w3 = Web3(Web3.HTTPProvider(rpc))
    abi = [
        {
            "anonymous": False,
            "inputs": [
                {"indexed": True, "name": "root", "type": "bytes32"},
                {"indexed": False, "name": "timestamp", "type": "uint256"},
                {"indexed": False, "name": "blockNumber", "type": "uint256"},
            ],
            "name": "AnchorSubmitted",
            "type": "event",
        }
    ]
    contract = w3.eth.contract(address=Web3.to_checksum_address(registry), abi=abi)
    target_ts = int(datetime.strptime(target_date, "%Y-%m-%d").replace(
        tzinfo=timezone.utc).timestamp())

    logs = contract.events.AnchorSubmitted().get_logs(from_block=0, to_block="latest")
    best: tuple[str, int] | None = None
    for log in logs:
        ts = log["args"]["timestamp"]
        if ts <= target_ts:
            best = (log["args"]["root"].hex(), log["args"]["blockNumber"])
    return best


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="Verify UAC State Anchor roots (ADR-PML-055).")
    p.add_argument("--date", required=True, help="Target UTC date YYYY-MM-DD.")
    p.add_argument("--event-log", required=True, type=Path, help="JSONL of state events.")
    p.add_argument("--rpc", default=None, help="EVM RPC URL.")
    p.add_argument("--registry", default=None, help="AnchorRegistry contract address.")
    p.add_argument("--onchain-root", default=None, help="Override on-chain root (0x...).")
    args = p.parse_args(argv)

    events = load_events(args.event_log)
    reconstructed = reconstruct_from_events(events)
    recon_hex = "0x" + reconstructed.hex()
    print(f"[verify] reconstructed root : {recon_hex}")
    print(f"[verify] events loaded      : {len(events)}")

    onchain_hex: str | None = args.onchain_root
    block_no: int = -1
    if onchain_hex is None:
        if not (args.rpc and args.registry):
            print("[verify] ERROR: provide --rpc + --registry or --onchain-root", file=sys.stderr)
            return 2
        result = fetch_onchain_root(args.rpc, args.registry, args.date)
        if result is None:
            print(f"[verify] no on-chain anchor found at/before {args.date}", file=sys.stderr)
            return 3
        onchain_hex, block_no = result

    print(f"[verify] on-chain root      : {onchain_hex} (block {block_no})")

    if onchain_hex.lower() == recon_hex.lower():
        print("[verify] MATCH — operational record is cryptographically consistent.")
        return 0
    print("[verify] MISMATCH — WORM archive does not match on-chain anchor.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
