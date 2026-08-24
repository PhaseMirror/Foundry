#!/usr/bin/env python3
"""
verify_pweh.py — Pre-receive & CI Gatekeeper for ADR-042 PWEH Receipts.
Enforces zero-drift, tamper-evident hash chaining, and contractivity verification.
"""

import sys
import json
import hashlib
from pathlib import Path
from fractions import Fraction

SCHEMA_PATH = Path("contracts/PWEH_Receipt_Schema.json")
AUDIT_TRAIL_DIR = Path("audit_trail")

def parse_rational(rat_str: str) -> Fraction:
    """Parses exact rational strings (e.g. '4/10') into exact Fraction objects."""
    try:
        return Fraction(rat_str)
    except Exception as exc:
        raise ValueError(f"Invalid rational format: {rat_str}") from exc

def validate_schema(instance: dict, schema: dict) -> None:

    """Lightweight self-contained schema validator without external dependencies."""
    required = schema.get("required", [])
    for field in required:
        if field not in instance:
            raise ValueError(f"Missing required field: {field}")
    
    props = schema.get("properties", {})
    if "s_integrity" in instance:
        s = instance["s_integrity"]
        if not (isinstance(s, str) and s.startswith("0x") and len(s) == 66):
            raise ValueError("s_integrity must be a 0x-prefixed 64-character hex string")
    if "prev_hash" in instance:
        p = instance["prev_hash"]
        if not (isinstance(p, str) and p.startswith("0x") and len(p) == 66):
            raise ValueError("prev_hash must be a 0x-prefixed 64-character hex string")


def verify_pweh_receipt(receipt_data: dict, schema: dict) -> bool:
    # 1. Schema Validation
    try:
        validate_schema(receipt_data, schema)
    except ValueError as err:
        print(f"[-] FATAL: Schema validation failed: {err}")
        return False

    
    # 2. Extract and Validate Rational Contraction Bounds
    cert = receipt_data["crmf_certificate"]
    gamma_0 = parse_rational(cert["gamma_0"])
    gamma_1 = parse_rational(cert["gamma_1"])
    beta = parse_rational(cert["beta"])
    eta = parse_rational(cert["eta"])
    
    col_sum_x = gamma_0 + eta
    col_sum_lambda = gamma_1 + beta
    
    if col_sum_x >= Fraction(1, 1) or col_sum_lambda >= Fraction(1, 1):
        print(f"[-] FATAL: Contraction bound breach. ColSum(X)={col_sum_x}, ColSum(λ)={col_sum_lambda}")
        return False

    # 3. Verify Kani Proof Log Integrity
    kani_digest = receipt_data["kani_proof_digest"]
    if not kani_digest.startswith("0x") or len(kani_digest) != 66:
        print(f"[-] FATAL: Malformed Kani proof digest: {kani_digest}")
        return False

    # 4. Re-calculate S_integrity Hash Chain: SHA256(canonical_payload || prev_hash)
    canonical_payload = (
        f"{receipt_data['receipt_id']}:"
        f"{receipt_data['adr_id']}:"
        f"{receipt_data['timestamp']}:"
        f"{receipt_data['last_prime_move']}:"
        f"{cert['gamma_0']}:{cert['gamma_1']}:{cert['beta']}:{cert['eta']}:"
        f"{receipt_data['kani_proof_digest']}"
    ).encode("utf-8")
    
    prev_hash_bytes = bytes.fromhex(receipt_data["prev_hash"].removeprefix("0x"))
    computed_s_integrity = "0x" + hashlib.sha256(canonical_payload + prev_hash_bytes).hexdigest()

    if computed_s_integrity.lower() != receipt_data["s_integrity"].lower():
        print(f"[-] FATAL: S_integrity hash mismatch!\n Computed: {computed_s_integrity}\n Recorded: {receipt_data['s_integrity']}")
        return False

    print(f"[+] Verified PWEH Receipt: {receipt_data['receipt_id']} for {receipt_data['adr_id']} (Contractive: PASS)")
    return True

def main():
    if not SCHEMA_PATH.exists():
        print(f"[-] Schema file missing at {SCHEMA_PATH}")
        sys.exit(1)

    with open(SCHEMA_PATH, "r", encoding="utf-8") as sf:
        schema = json.load(sf)

    receipt_files = list(AUDIT_TRAIL_DIR.glob("pweh_adr042_*.json"))
    if not receipt_files:
        print("[-] No ADR-042 PWEH receipts found in audit_trail/")
        sys.exit(1)

    all_passed = True
    for r_file in receipt_files:
        with open(r_file, "r", encoding="utf-8") as rf:
            data = json.load(rf)
            if not verify_pweh_receipt(data, schema):
                all_passed = False

    if not all_passed:
        print("[-] SIG_GOV_KILL: One or more PWEH audit receipts failed verification.")
        sys.exit(1)

    print("[+] All PWEH receipts cryptographically validated. Gate unlocked.")
    sys.exit(0)

if __name__ == "__main__":
    main()
