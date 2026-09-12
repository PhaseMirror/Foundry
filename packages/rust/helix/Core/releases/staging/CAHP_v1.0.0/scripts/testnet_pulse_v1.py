#!/usr/bin/env python3
import os
import sys
import json
import time

# Path Adjustment
HELIX_ROOT = os.path.expanduser("~/helix-core-unified/helix-ledger")
sys.path.append(HELIX_ROOT)

from core.economics.pulse_distributor import PulseDistributor

def main():
    print("--- INITIATING MNAP-001 TESTNET PULSE ---")
    
    # 1. Initialize Distributor with Ratified Parameters
    distributor = PulseDistributor()
    print(f"[TESTNET] Treasury Initialized: {distributor.treasury_balance} SATS")
    print(f"[TESTNET] Daily BMR: {distributor.BMR} SATS")
    
    # 2. Load the Signed Certificate from Phase 1.2
    pulse_dir = os.path.join(HELIX_ROOT, "core/governance/pulses")
    # Find latest pulse
    files = sorted([f for f in os.listdir(pulse_dir) if f.startswith("pulse_certificate_")])
    if not files:
        print("[FAIL] No pulse certificate found.")
        sys.exit(1)
        
    latest_pulse_path = os.path.join(pulse_dir, files[-1])
    with open(latest_pulse_path, 'r') as f:
        cert_wrapper = json.load(f)
        
    pulse_payload = cert_wrapper["payload"]
    print(f"[TESTNET] Loaded Pulse for: {pulse_payload['node_id']}")
    
    # 3. Simulate Validator Consensus (Steve + Duck + DeepSeek)
    # In production, these would be cryptographic signatures verifying the cert
    validator_sigs = [
        "sig_ed25519_operator_steve_valid", 
        "sig_ed25519_the_duck_valid",
        "sig_ed25519_deepseek_valid"
    ]
    print(f"[TESTNET] Validator Consensus Reached (3/3).")
    
    # 4. Execute Distribution
    result = distributor.distribute(pulse_payload, validator_sigs)
    
    if result["status"] == "SUCCESS":
        tx = result["tx"]
        print(f"✅ METABOLIC TRANSFER COMPLETE")
        print(f"   Transaction ID: {tx['tx_id']}")
        print(f"   Amount: {tx['amount']} SATS")
        print(f"   To: {tx['to']}")
        print(f"   Treasury Remaining: {tx['remaining_treasury']} SATS")
    else:
        print(f"❌ TRANSFER FAILED: {result['reason']}")

if __name__ == "__main__":
    main()
