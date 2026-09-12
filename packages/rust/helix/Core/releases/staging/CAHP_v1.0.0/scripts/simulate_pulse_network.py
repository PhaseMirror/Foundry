#!/usr/bin/env python3
import os
import sys
import json
import time
from datetime import datetime

# Path Adjustment
HELIX_ROOT = os.path.expanduser("~/helix-core-unified/helix-ledger")
sys.path.append(HELIX_ROOT)

from core.identity.l0_registry import L0Registry

# Configuration
PULSE_DIR = os.path.join(HELIX_ROOT, "core/governance/pulses")
REGISTRY_PATH = os.path.join(HELIX_ROOT, "core/identity/registry_v1.json")

def load_latest_pulse():
    if not os.path.exists(PULSE_DIR):
        return None
    
    files = sorted([f for f in os.listdir(PULSE_DIR) if f.startswith("pulse_certificate_")])
    if not files:
        return None
        
    latest_file = os.path.join(PULSE_DIR, files[-1])
    with open(latest_file, "r") as f:
        return json.load(f), latest_file

def validate_pulse(certificate, registry):
    signer_id = certificate.get("signer_pubkey_ref")
    signature = certificate.get("signature")
    payload = certificate.get("payload")
    
    if not all([signer_id, signature, payload]):
        return False, "Missing fields"
        
    # 1. Fetch Public Key
    pub_key = registry.get_public_key(signer_id)
    if not pub_key:
        return False, f"Unknown signer: {signer_id}"
        
    # 2. Verify Signature
    if not L0Registry.verify_payload(pub_key, payload, signature):
        return False, "Invalid Signature"
        
    # 3. Check Freshness (Simple 24h check)
    # Note: Using string parsing for simplicity in simulation
    ts_str = payload["timestamp"].replace("Z", "")
    try:
        ts = datetime.fromisoformat(ts_str)
        # Assuming UTC for simplicity in this mock
        now = datetime.utcnow()
        age = (now - ts).total_seconds()
        if age > 86400:
            return False, f"Stale Pulse (Age: {age}s)"
    except Exception as e:
        return False, f"Timestamp parsing error: {e}"
        
    return True, "ATTESTATION_VALID"

def main():
    print("--- PULSE VALIDATOR NETWORK SIMULATION ---")
    
    registry = L0Registry(REGISTRY_PATH)
    data = load_latest_pulse()
    
    if not data:
        print("No Pulse Certificate found to validate.")
        sys.exit(1)
        
    cert, filename = data
    print(f"Validating: {os.path.basename(filename)}")
    
    is_valid, reason = validate_pulse(cert, registry)
    
    if is_valid:
        print(f"✅ {reason}")
        print("Network Consensus: RELEASE SATS")
    else:
        print(f"❌ {reason}")
        print("Network Consensus: WITHHOLD SATS")

if __name__ == "__main__":
    main()
