#!/usr/bin/env python3
"""
ADR-045: LawfulRecursionHash verification and epoch attestation.
Ties deployment epochs to the active CRMF audit ledger.
"""

import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

CRMF_LEDGER = Path("/var/log/multiplicity/crmf_worm.jsonl")


def compute_lawful_recursion_hash(epoch_data: str) -> str:
    """Compute SHA-256 hash for the deployment epoch."""
    return hashlib.sha256(epoch_data.encode()).hexdigest()


def verify_hash(epoch_hash: str, epoch_data: str) -> bool:
    """Verify that epoch_hash matches the SHA-256 of epoch_data."""
    computed = compute_lawful_recursion_hash(epoch_data)
    return computed == epoch_hash


def log_crmf_event(event: str, detail: str, lawful_hash: str) -> None:
    """Append a CRMF WORM ledger entry."""
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "adr": "ADR-045",
        "lawful_recursion_hash": lawful_hash,
        "event": event,
        "detail": detail,
    }
    with open(CRMF_LEDGER, "a") as f:
        f.write(json.dumps(entry) + "\n")


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: verify_lawful_recursion_hash.py <epoch_hash> <epoch_data>")
        return 1

    epoch_hash = sys.argv[1]
    epoch_data = sys.argv[2]

    if verify_hash(epoch_hash, epoch_data):
        print(f"[PASS] LawfulRecursionHash verified: {epoch_hash}")
        log_crmf_event("lawful_recursion_hash_verified", f"hash={epoch_hash}", epoch_hash)
        return 0
    else:
        print(f"[FAIL] LawfulRecursionHash mismatch: expected {epoch_hash}")
        log_crmf_event("lawful_recursion_hash_failed", f"hash={epoch_hash}", epoch_hash)
        return 1


if __name__ == "__main__":
    sys.exit(main())
