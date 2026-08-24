# ~/helix_ledger/modules/bitcoin/pricing_engine_v9_stable.py
# Implements all V8 hardening features with critical bug fixes for stability.

import datetime
import json
import os
import re
import sys
import hashlib
import subprocess
from typing import Optional, Dict, Any

import requests

class PricingEngineV9_Stable:
    # Corrected typo: BASE_MARKer_COSTS -> BASE_MARKER_COSTS
    BASE_MARKER_COSTS = {"[FACT]": 15, "[REASONED]": 10, "[HYPOTHESIS]": 5}
    LOG_FILE = "audit_log.json"
    FEE_API_URL = "https://mempool.space/api/v1/fees/recommended"
    
    DAILY_BURN_RATE = 1000
    RUNWAY_THRESHOLD_DAYS = 30
    POW_DIFFICULTY = 4

    def _scrub_pii(self, text: str) -> str:
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
        scrubbed_text = re.sub(email_pattern, '[REDACTED]', text)
        scrubbed_text = re.sub(ip_pattern, '[REDACTED]', scrubbed_text)
        return scrubbed_text

    def _get_network_multiplier(self) -> float:
        try:
            fees = requests.get(self.FEE_API_URL, timeout=5).json()
            fee = fees.get("hourFee", 1)
            multiplier = 1.0 + (max(0, fee - 1) / 10)
            print(f"DEBUG: Current hourFee is {fee} sat/vB. Applying cost multiplier of {multiplier:.2f}x.")
            return multiplier
        except Exception:
            return 1.0

    def sha256_pow(self, data: str, difficulty: int) -> (str, int):
        print(f"INFO: Starting PoW with difficulty {difficulty}...")
        nonce = 0
        prefix = '0' * difficulty
        while True:
            attempt = f"{data}:{nonce}"
            h = hashlib.sha256(attempt.encode()).hexdigest()
            if h.startswith(prefix):
                print(f"INFO: PoW solved. Nonce: {nonce}, Hash: {h[:10]}...")
                return h, nonce
            nonce += 1

    def process_and_settle(self, cognitive_output: str, target_action: str, current_balance_sats: int):
        runway_days = current_balance_sats / self.DAILY_BURN_RATE
        if runway_days < self.RUNWAY_THRESHOLD_DAYS:
            print(f"[UNCERTAIN] Runway Alert: {runway_days:.1f} days remaining is below the {self.RUNWAY_THRESHOLD_DAYS}-day threshold. Halting action.")
            return

        scrubbed_output = self._scrub_pii(cognitive_output)
        marker = re.match(r"^\[(FACT|REASONED|HYPOTHESIS)\]", scrubbed_output)
        if not marker: return

        multiplier = self._get_network_multiplier()
        # Corrected typo: self.BASE_MARKer_COSTS -> self.BASE_MARKER_COSTS
        base_cost = self.BASE_MARKER_COSTS[marker.group(0)]
        dynamic_cost = int(base_cost * multiplier)

        log_data_for_pow = json.dumps({"output": scrubbed_output, "action": target_action, "cost": dynamic_cost})
        pow_hash, nonce = self.sha256_pow(log_data_for_pow, self.POW_DIFFICULTY)

        log_entry = {
            "Timestamp": datetime.datetime.now(datetime.UTC).isoformat(),
            "Epistemic Marker": marker.group(0),
            "Target Action": target_action,
            "Scrubbed Output Preview": scrubbed_output[:150],
            "Dynamic Cost": dynamic_cost,
            "PoW Hash": pow_hash,
            "PoW Nonce": nonce
        }
        with open(self.LOG_FILE, "a") as f:
            f.write(json.dumps(log_entry) + os.linesep)
        print(f"SETTLED: {marker.group(0)} | Cost: {dynamic_cost} sats (Base: {base_cost})")

if __name__ == "__main__":
    engine = PricingEngineV9_Stable()
    print("--- Running Hardened Sovereign Metabolism Simulation (V9 Stable) ---")
    
    # Corrected SyntaxError: Replaced unterminated string with separate print() calls.
    print()
    print("--- SCENARIO 1: Sufficient fuel, action is processed. ---")
    engine.process_and_settle(
        "[FACT] User stephen@example.com connected from 192.168.1.100.",
        "user_login_audit",
        current_balance_sats=197340
    )

    print()
    print("--- SCENARIO 2: Low fuel, action is halted by RAG Bands. ---")
    engine.process_and_settle(
        "[REASONED] This action is too expensive given the low fuel state.",
        "costly_operation",
        current_balance_sats=29000
    )
