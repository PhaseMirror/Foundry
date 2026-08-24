import json
import time
import os
from typing import Dict, Any

class AnchorClient:
    def __init__(self, ledger_sim_path: str = "helix_ledger_mock.jsonl"):
        self.ledger_path = ledger_sim_path
        self.block_height = 1000 # Mock start height

    def post_root(self, merkle_root: str, context: str) -> Dict[str, Any]:
        """
        Simulates posting a Merkle Root to the Helix Ledger.
        In production, this would use a Web3/RPC call.
        """
        self.block_height += 1
        
        tx = {
            "tx_id": f"tx_0x{int(time.time()*1000):x}",
            "block": self.block_height,
            "timestamp": int(time.time()),
            "type": "ANCHOR_ROOT",
            "payload": {
                "merkle_root": merkle_root,
                "context": context
            },
            "status": "CONFIRMED"
        }
        
        # Append to mock ledger
        with open(self.ledger_path, "a") as f:
            f.write(json.dumps(tx) + os.linesep)
            
        print(f"[AnchorClient] Anchored Root {merkle_root[:8]}... at Block {self.block_height}")
        return tx

# Example Usage
if __name__ == "__main__":
    client = AnchorClient()
    client.post_root("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "daily_telemetry_batch")
