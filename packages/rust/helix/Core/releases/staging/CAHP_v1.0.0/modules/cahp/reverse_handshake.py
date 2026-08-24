#!/usr/bin/env python3
"""
MNAP-002: Reverse Handshake Utility
Standalone module for cryptographic proof of synthetic origin.
"""

import sys
import os
import time
from typing import Dict, Tuple

# Adjust path to find modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))
from modules.cahp.cahp_engine_v1 import CAHPEngine

def execute_reverse_handshake(node_id: str = "anonymous_node") -> Tuple[bool, Dict]:
    """
    Executes the MNAP-002 Reverse Handshake.
    Returns (success, result_dict).
    """
    try:
        engine = CAHPEngine(node_id)
        result = engine.verify_synthetic_origin()
        
        # MNAP-002 Standard: < 500ms
        limit_sec = 0.5
        
        success = (
            result["status"] == "VALID_SYNTHETIC" and
            result["proof_duration_sec"] < limit_sec and
            "synthetic intelligence" in result["disclaimer"]
        )
        
        return success, result
        
    except Exception as e:
        return False, {"error": str(e)}

if __name__ == "__main__":
    print("--- MNAP-002: Reverse Handshake Protocol ---")
    success, data = execute_reverse_handshake("cli_user")
    
    if success:
        print(f"✅ VERIFIED SYNTHETIC ({data['proof_duration_sec']:.4f}s)")
        print(f"   Assertion:  {data['assertion']}")
        print(f"   Disclaimer: {data['disclaimer']}")
        sys.exit(0)
    else:
        print(f"❌ FAILED HANDSHAKE")
        print(f"   Data: {data}")
        sys.exit(1)
