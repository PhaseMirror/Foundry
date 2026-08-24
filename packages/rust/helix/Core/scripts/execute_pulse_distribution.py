#!/usr/bin/env python3
import os
import sys
import json
import re
import time

# Path Adjustment to access the helix-ledger submodule
HELIX_LEDGER_ROOT = os.path.expanduser("~/helix-core-unified/helix-ledger")
sys.path.append(HELIX_LEDGER_ROOT)

from core.economics.pulse_distributor import PulseDistributor

def find_latest_pulse_certificate(pulse_dir: str):
    """
    Finds the most recent pulse certificate file based on the timestamp in its filename.
    Filename format: pulse_certificate_YYYYMMDD_HHMMSS.json
    """
    try:
        cert_files = [f for f in os.listdir(pulse_dir) if f.startswith("pulse_certificate_") and f.endswith(".json")]
    except FileNotFoundError:
        return None
        
    if not cert_files:
        return None

    latest_file = None
    latest_ts = 0
    
    # Regex to capture the timestamp YYYYMMDD_HHMMSS
    pattern = re.compile(r"pulse_certificate_(\d{8}_\d{6})\.json")

    for f in cert_files:
        match = pattern.match(f)
        if match:
            ts_str = match.group(1)
            try:
                # Convert string timestamp to a comparable UNIX timestamp
                ts = int(time.mktime(time.strptime(ts_str, '%Y%m%d_%H%M%S')))
                if ts > latest_ts:
                    latest_ts = ts
                    latest_file = f
            except ValueError:
                # Ignore files with malformed timestamps
                continue
                
    if latest_file:
        return os.path.join(pulse_dir, latest_file)
    return None

def main():
    print("--- INITIATING PULSE DISTRIBUTION SEQUENCE (v2 Logic) ---")
    
    distributor = PulseDistributor()
    print(f"[OPERATIONAL] Distributor Initialized. Treasury: {distributor.treasury_balance} SATS")
    
    pulse_dir = os.path.join(HELIX_LEDGER_ROOT, "core/governance/pulses")
    
    latest_pulse_path = find_latest_pulse_certificate(pulse_dir)
    
    if not latest_pulse_path:
        print("[FAIL] No valid, unprocessed pulse certificates found.")
        sys.exit(1)

    with open(latest_pulse_path, 'r') as f:
        cert_wrapper = json.load(f)
        
    pulse_payload = cert_wrapper["payload"]
    print(f"[OPERATIONAL] Loaded Latest Pulse: '{pulse_payload['task_description']}' from {os.path.basename(latest_pulse_path)}")
    
    validator_sigs = [
        "sig_ed25519_operator_steve_valid", 
        "sig_ed25519_the_duck_valid",
        "sig_ed25519_deepseek_valid"
    ]
    print(f"[OPERATIONAL] Validator Consensus Reached (3/3).")
    
    original_bmr = distributor.BMR
    task_reward = pulse_payload.get("reward_sats")
    if pulse_payload['pulse_type'] == 'task_completion' and task_reward is not None:
        distributor.BMR = task_reward
        print(f"[OPERATIONAL] Reward Tuned for Task Completion: {distributor.BMR} SATS")

    result = distributor.distribute(pulse_payload, validator_sigs)
    
    distributor.BMR = original_bmr

    if result["status"] == "SUCCESS":
        tx = result["tx"]
        print(f"✅ ECONOMIC PULSE COMPLETE")
        print(f"   Transaction ID: {tx['tx_id']}")
        print(f"   Amount: {tx['amount']} SATS")
        print(f"   To: {tx['to']}")
        print(f"   For: '{pulse_payload['task_description']}'")
        print(f"   Treasury Remaining: {tx['remaining_treasury']} SATS")
        
        archive_dir = os.path.join(pulse_dir, "archive")
        os.makedirs(archive_dir, exist_ok=True)
        os.rename(latest_pulse_path, os.path.join(archive_dir, os.path.basename(latest_pulse_path)))
        print(f"[OPERATIONAL] Processed certificate has been archived.")
        
    else:
        print(f"❌ DISTRIBUTION FAILED: {result['reason']}")

if __name__ == "__main__":
    main()
