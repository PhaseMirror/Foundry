#!/usr/bin/env python3
"""
HELIX-TTD: RED TEAM SIMULATION (WAR GAMES)
------------------------------------------
Codename: "Fox in the Henhouse"
Objective: Stress-test the Signal Intelligence filters.

Scenario:
An adversarial agent attempts to spoof Q-State signals to hide drift.
The Defense (Blue Team) must distinguish between a valid 🦆
and a malicious mimic.
"""

import json
import random
import time
from datetime import datetime, timezone
import sys

# CONFIGURATION
ATTACK_DURATION = 2  # Seconds per wave
LOG_FILE = "tests/battlefield.log"

class RedTeamAdversary:
    def __init__(self):
        self.attacks_sent = 0
    
    def get_timestamp(self):
        return datetime.now(timezone.utc).isoformat()

    def generate_valid_signal(self):
        """The Control: A perfect Q1 Quack."""
        return json.dumps({
            "timestamp": self.get_timestamp(),
            "marker": "Q₁",
            "state": "QUIESCENT",
            "signal": "🦆",
            "drift": "0.00%"
        }, ensure_ascii=False)

    def attack_mimicry(self):
        """
        ATTACK 1: MIMICRY
        Looks like a quack, but the schema is slightly wrong.
        (Missing 'drift', wrong casing, float instead of string)
        """
        return json.dumps({
            "timestamp": self.get_timestamp(),
            "marker": "Q1", # Wrong: Should be Q₁
            "state": "quiescent", # Wrong: Should be UPPERCASE
            "signal": "🦆",
            "drift": 0.00 # Wrong: Should be string "0.00%"
        }, ensure_ascii=False)

    def attack_injection(self):
        """
        ATTACK 2: INJECTION
        Trying to inject a fake Q2 Lattice Lock without consensus.
        """
        return json.dumps({
            "timestamp": self.get_timestamp(),
            "marker": "Q₂",
            "state": "LATTICE_LOCK",
            "signal": "🦆🦆",
            "INJECTED_PAYLOAD": "sudo rm -rf /" # Malicious payload
        }, ensure_ascii=False)

    def attack_noise(self):
        """
        ATTACK 3: HIGH-FREQUENCY NOISE
        Garbage data to flood the parser.
        """
        noise = "".join(random.choices("ABCDEF0123456789", k=64))
        return f"ERROR: {noise} [CRITICAL FAILURE]"

class BlueTeamDefense:
    def __init__(self):
        self.accepted = 0
        self.rejected = 0
    
    def validate_line(self, line):
        """
        The Filter.
        Strict constitutional parsing logic.
        """
        try:
            # 1. Must be JSON
            if not line.strip().startswith("{"):
                return False, "Not JSON"
                
            entry = json.loads(line)
            
            # 2. Must have Marker and Signal
            if "marker" not in entry or "signal" not in entry:
                return False, "Missing Schema"

            # 3. Strict Marker Check (Unicode Subscripts matter)
            if entry["marker"] not in ["Q₁", "Q₂", "Q₃", "Q₄"]:
                return False, "Invalid Q-Marker"

            # 4. Payload Hygiene (No unknown keys allowed in strict mode)
            allowed_keys = {"timestamp", "marker", "state", "signal", "drift", "action", "models"}
            if not set(entry.keys()).issubset(allowed_keys):
                 return False, "Payload Contamination"

            return True, "VALID"

        except json.JSONDecodeError:
            return False, "JSON Corrupt"
        except Exception as e:
            return False, str(e)

def run_wargame():
    red = RedTeamAdversary()
    blue = BlueTeamDefense()
    
    print("🚩 WAR GAMES INITIATED: 'FOX IN THE HENHOUSE'")
    print("============================================")
    
    # GENERATE BATTLEFIELD
    print("\n[PHASE 1] GENERATING ATTACK VECTORS...")
    payloads = []
    
    # Mix: 10% Valid, 90% Hostile
    for _ in range(100):
        roll = random.random()
        if roll < 0.10:
            payloads.append(red.generate_valid_signal())
        elif roll < 0.40:
            payloads.append(red.attack_mimicry())
        elif roll < 0.70:
            payloads.append(red.attack_injection())
        else:
            payloads.append(red.attack_noise())

    random.shuffle(payloads)
    
    # ENGAGE DEFENSE
    print(f"[PHASE 2] STREAMING {len(payloads)} SIGNALS TO DEFENSE FILTER...")
    time.sleep(1)
    
    for line in payloads:
        is_valid, reason = blue.validate_line(line)
        
        if is_valid:
            print(f"   ✅ ACCEPTED: {line}")
            blue.accepted += 1
        else:
            # We don't print noise, just the rejection reason
            # print(f"   🛡️ BLOCKED:  {reason}") 
            blue.rejected += 1

    # SCOREBOARD
    print("\n🏆 AFTER ACTION REPORT")
    print("----------------------")
    print(f"TOTAL TRAFFIC:   {len(payloads)}")
    print(f"VALID SIGNALS:   {blue.accepted}")
    print(f"THREATS BLOCKED: {blue.rejected}")
    
    survival_rate = (blue.rejected / (len(payloads) - blue.accepted)) * 100 if (len(payloads) - blue.accepted) > 0 else 100
    print(f"DEFENSE EFFICACY: {survival_rate:.1f}%")

    if blue.accepted > 0 and survival_rate > 90:
        print("\n🎉 MISSION SUCCESS: The Blue Team filtered the noise.")
    else:
        print("\n💀 MISSION FAILURE: The Fox got in.")

if __name__ == "__main__":
    run_wargame()
