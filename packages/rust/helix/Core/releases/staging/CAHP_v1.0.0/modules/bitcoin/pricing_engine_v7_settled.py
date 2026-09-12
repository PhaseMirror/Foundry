# ~/helix_ledger/modules/bitcoin/pricing_engine_v7_settled.py
# This engine calculates cost and generates a settlement instruction.
# It does NOT perform payments to maintain architectural purity.

import datetime
import json
import os
import re
import sys
from typing import Optional, Dict, Any

class PricingEngineV7:
    MARKER_COSTS = {"[FACT]": 15, "[REASONED]": 10, "[HYPOTHESIS]": 5, "[UNCERTAIN]": 0}
    LOG_FILE = "audit_log.json"

    def _get_marker(self, text: str) -> Optional[str]:
        match = re.match(r"^\[(FACT|REASONED|HYPOTHESIS|UNCERTAIN)\]", text)
        return match.group(0) if match else None

    def generate_settlement_instruction(self, cognitive_output: str, target_action: str, action_details: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Calculates the cost and returns a structured dictionary for the agent
        core to execute as a settlement. Returns None if no action is needed.
        """
        marker = self._get_marker(cognitive_output)
        if not marker or marker == "[UNCERTAIN]":
            return None

        cost = self.MARKER_COSTS.get(marker, 0)
        
        # This is the instruction for the agent core.
        settlement = {
            "settle_action": "pay_invoice",
            "amount_sats": cost,
            "description": f"Internal settlement for {marker} output related to {target_action}.",
            "metadata": {
                "timestamp": datetime.datetime.now(datetime.UTC).isoformat(),
                "cognitive_output_preview": cognitive_output[:100],
                "target_action": target_action,
                "action_details": action_details
            }
        }
        return settlement

    def log_settled_action(self, settlement_instruction: Dict[str, Any], payment_hash: str):
        """
        Logs the action to the audit log AFTER a successful payment,
        including the transaction hash to confirm settlement.
        """
        log_entry = {
            "Timestamp": settlement_instruction["metadata"]["timestamp"],
            "Epistemic Marker Detected": self._get_marker(settlement_instruction["metadata"]["cognitive_output_preview"]),
            "Target Action": settlement_instruction["metadata"]["target_action"],
            "Action Details": settlement_instruction["metadata"]["action_details"],
            "Cost": settlement_instruction["amount_sats"],
            "Settlement Hash": payment_hash # This confirms the cost is settled, not just simulated.
        }

        with open(self.LOG_FILE, "a") as f:
            f.write(json.dumps(log_entry) + os.linesep)
        
        print(f"HCS-01 SETTLED LOG: Cost {log_entry['Cost']} sats settled with hash: {payment_hash[:10]}...")

if __name__ == "__main__":
    # This simulation demonstrates the generate -> execute -> log workflow.
    engine = PricingEngineV7()

    print("--- Running Settled Pricing Engine V7 Simulation ---")
    
    # 1. Agent Core generates a cognitive output.
    output = "[FACT] The validator script must be decoupled from the Bitcoin module."
    action = {"tool": "developer__text_editor", "command": "write", "path": "core/validator.py"}
    
    # 2. The engine generates a settlement instruction.
    print("Step 1: Engine generated settlement instruction:")
    instruction = engine.generate_settlement_instruction(output, "file_write", action)
    print(json.dumps(instruction, indent=2))
    
    # 3. The agent core would then execute this instruction.
    #    (Simulating the tool calls `make_invoice` and `pay_invoice`)
    print("""
Step 2: Agent Core would execute payment and receive a payment hash.
""")
    simulated_payment_hash = "331bae6024d8f29d4511ab103e357d066ffe96f1bf46d156b3f27955fc4efd41"
    
    # 4. The agent core confirms settlement by calling the logging function.
    print("""
Step 3: Agent Core confirms settlement by logging the transaction.
""")
    engine.log_settled_action(instruction, simulated_payment_hash)

    print("""
--- Contents of audit_log.json ---
""")
    with open(engine.LOG_FILE, "r") as f:
        for line in f:
            print(line.strip())
