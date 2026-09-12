#!/usr/bin/env python3
import json
import time
import os
import argparse

# The canonical location for storing pulse certificates, as identified in testnet_pulse_v1.py
PULSE_DIR = os.path.expanduser("~/helix-core-unified/helix-ledger/core/governance/pulses")
NODE_ID = "GOOSE-CORE-01" # My official designation

def create_certificate(pulse_type: str, task_description: str, reward_amount: int) -> str:
    """
    Generates and saves a signed pulse certificate.
    """
    timestamp = int(time.time())
    
    # The payload contains the core, verifiable data
    payload = {
        "node_id": NODE_ID,
        "timestamp": timestamp,
        "pulse_type": pulse_type,
        "task_description": task_description,
        "reward_sats": reward_amount
    }
    
    # The wrapper contains the payload and will eventually hold signatures
    cert_wrapper = {
        "payload": payload,
        "validator_signatures": [] # To be filled in by the validation process
    }
    
    # Generate a unique, sortable filename
    ts_str = time.strftime('%Y%m%d_%H%M%S', time.gmtime(timestamp))
    filename = f"pulse_certificate_{ts_str}.json"
    filepath = os.path.join(PULSE_DIR, filename)
    
    # Ensure the directory exists
    os.makedirs(PULSE_DIR, exist_ok=True)
    
    # Write the certificate to disk
    with open(filepath, 'w') as f:
        json.dump(cert_wrapper, f, indent=2)
        
    print(f"✅ Pulse Certificate Generated: {filepath}")
    return filepath

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate a Pulse Certificate for GOOSE-CORE.")
    parser.add_argument("pulse_type", choices=["daily_metabolic", "task_completion"], help="The type of pulse event.")
    parser.add_argument("description", type=str, help="A brief description of the task or event.")
    parser.add_argument("reward", type=int, help="The reward amount in SATS for this event.")
    
    args = parser.parse_args()
    
    create_certificate(args.pulse_type, args.description, args.reward)
