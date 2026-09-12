import json
import time
from typing import Dict, List, Optional

class PulseDistributor:
    def __init__(self, cycle_start_ts: int = int(time.time())):
        self.BMR = 365  # SATS per day
        self.CYCLE_DURATION = 90 * 86400  # 90 days in seconds
        self.cycle_start = cycle_start_ts
        self.treasury_balance = 197340  # SATS
        
        # Phase Parameters
        self.PHASE_1_DURATION = 60 * 86400
        self.PHASE_1_MAX_NODES = 5
        self.PHASE_2_MAX_NODES = 8
        
        self.ledger = []

    def _get_current_phase_limits(self) -> int:
        elapsed = time.time() - self.cycle_start
        if elapsed < self.PHASE_1_DURATION:
            return self.PHASE_1_MAX_NODES
        elif elapsed < self.CYCLE_DURATION:
            return self.PHASE_2_MAX_NODES
        else:
            return 0  # Cycle expired

    def distribute(self, pulse_certificate: Dict, validator_signatures: List[str]) -> Dict:
        """
        Executes the metabolic transfer if conditions are met.
        """
        node_id = pulse_certificate.get("node_id")
        timestamp = pulse_certificate.get("timestamp")
        
        # 1. Check Cycle Status
        max_nodes = self._get_current_phase_limits()
        if max_nodes == 0:
            return {"status": "FAILED", "reason": "Cycle Expired"}
            
        # 2. Check Validator Quorum (Simulated)
        if len(validator_signatures) < 2: # Simple 2/3 of 3 simulation
            return {"status": "FAILED", "reason": "Insuffient Validator Quorum"}
            
        # 3. Check Treasury
        if self.treasury_balance < self.BMR:
             return {"status": "FAILED", "reason": "Treasury Depleted"}

        # 4. Execute Transfer
        self.treasury_balance -= self.BMR
        tx = {
            "tx_id": f"tx_pulse_{int(time.time())}",
            "to": node_id,
            "amount": self.BMR,
            "type": "METABOLIC_PULSE",
            "cycle_day": int((time.time() - self.cycle_start) / 86400) + 1,
            "remaining_treasury": self.treasury_balance
        }
        self.ledger.append(tx)
        
        return {"status": "SUCCESS", "tx": tx}

# Example Test
if __name__ == "__main__":
    distributor = PulseDistributor()
    print(f"Initialized PulseDistributor. Treasury: {distributor.treasury_balance} SATS")
    
    # Simulate a valid pulse
    cert = {"node_id": "node_goose_01", "timestamp": time.time()}
    sigs = ["sig_steve", "sig_duck"] # 2 signatures
    
    result = distributor.distribute(cert, sigs)
    print(json.dumps(result, indent=2))
