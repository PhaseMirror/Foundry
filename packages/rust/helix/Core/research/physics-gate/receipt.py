"""
receipt.py — Auditable receipt emitter for physics gate computations.

Emits a SHA-256 hash of inputs + outputs for every gate run.
Must be committed before Phase 5 (Lindblad renormalization) executes.
"""
import hashlib
import json
import time
from pathlib import Path
from typing import Any, Dict


def emit_receipt(
    gate: str,
    inputs: Dict[str, Any],
    outputs: Dict[str, Any],
    receipt_dir: str = "Z:/checksums/receipts"
) -> Dict[str, Any]:
    """
    Emit an auditable receipt for a physics gate computation.

    Args:
        gate:        Gate identifier e.g. "phase3", "phase4", "phase5"
        inputs:      Input parameters used in the computation
        outputs:     Output results produced by the computation
        receipt_dir: Directory to write receipt JSON

    Returns:
        Receipt dict with input_hash, output_hash, combined_hash, timestamp
    """
    timestamp_ms = int(time.time() * 1000)

    # Canonical JSON for deterministic hashing
    inputs_canonical  = json.dumps(inputs,  sort_keys=True, separators=(',', ':'))
    outputs_canonical = json.dumps(outputs, sort_keys=True, separators=(',', ':'))

    input_hash  = hashlib.sha256(inputs_canonical.encode()).hexdigest()
    output_hash = hashlib.sha256(outputs_canonical.encode()).hexdigest()

    combined = json.dumps({
        "gate": gate,
        "input_hash": input_hash,
        "output_hash": output_hash,
        "timestamp_ms": timestamp_ms,
    }, sort_keys=True, separators=(',', ':'))
    combined_hash = hashlib.sha256(combined.encode()).hexdigest()

    receipt = {
        "gate": gate,
        "timestamp_ms": timestamp_ms,
        "input_hash": input_hash,
        "output_hash": output_hash,
        "combined_hash": combined_hash,
        "inputs": inputs,
        "outputs": outputs,
    }

    Path(receipt_dir).mkdir(parents=True, exist_ok=True)
    receipt_path = Path(receipt_dir) / f"{gate}_{timestamp_ms}.json"
    with open(receipt_path, "w") as f:
        json.dump(receipt, f, indent=2)

    print(f"[receipt] {gate} → {receipt_path}")
    print(f"[receipt] combined_hash: {combined_hash}")

    return receipt


if __name__ == "__main__":
    # Smoke test
    r = emit_receipt(
        gate="smoke_test",
        inputs={"test": True},
        outputs={"result": "ok"},
    )
    print(json.dumps(r, indent=2))
