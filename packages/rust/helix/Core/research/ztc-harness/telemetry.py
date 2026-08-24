"""
telemetry.py — Poseidon-receipted telemetry for ZTC harness.
Writes JSONL locally and uploads to Azure Blob Storage.
"""
import hashlib
import json
import math
import os
import time
import uuid
from pathlib import Path

# BN254 Poseidon (educational — matches pikernel implementation)
BN254_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617

def _poseidon_hash(data: bytes) -> str:
    chunks = [
        int.from_bytes(data[i:i+31], 'big') % BN254_MODULUS
        for i in range(0, len(data), 31)
    ] or [0]
    state = [0, 0, 0]
    for i, c in enumerate(chunks):
        state[i % 3] = (state[i % 3] + c) % BN254_MODULUS
    for r in range(8):
        state = [pow(s, 3, BN254_MODULUS) for s in state]
        new_state = [0, 0, 0]
        for i in range(3):
            for j in range(3):
                new_state[i] = (new_state[i] + ((i+j+1) % BN254_MODULUS) * state[j]) % BN254_MODULUS
        state = [(s + r*1000 + i*100 + 42) % BN254_MODULUS for i, s in enumerate(new_state)]
    return format(state[0], '064x')


SESSION_ID = str(uuid.uuid4())
LOCAL_DIR  = Path(os.getenv("TELEMETRY_DIR", "Z:/ztc-results"))
LOCAL_DIR.mkdir(parents=True, exist_ok=True)
JSONL_PATH = LOCAL_DIR / f"session_{SESSION_ID}.jsonl"


def record(
    model: str,
    model_version: str,
    prompt_category: str,
    prompt: str,
    response: str,
    drift_result: dict,
    elapsed_ms: float,
    token_count: int = 0,
    grammar_included: bool = True,
) -> dict:
    entry = {
        "run_id":           str(uuid.uuid4()),
        "session_id":       SESSION_ID,
        "harness_version":  "1.1.0",
        "timestamp_ms":     int(time.time() * 1000),
        "model":            model,
        "model_version":    model_version,
        "prompt_category":  prompt_category,
        "prompt_hash":      hashlib.sha256(prompt.encode()).hexdigest(),
        "response_hash":    hashlib.sha256(response.encode()).hexdigest(),
        "compliant":        drift_result["compliant"],
        "drift_code":       drift_result["drift_code"],
        "compliance_pct":   drift_result["compliance_pct"],
        "violations":       drift_result["violations"],
        "layer":            drift_result["layer"],
        "elapsed_ms":       round(elapsed_ms, 1),
        "token_count":      token_count,
        "grammar_included": grammar_included,
    }
    canonical = json.dumps(entry, sort_keys=True, separators=(',', ':'))
    entry["poseidon_digest"] = _poseidon_hash(canonical.encode())

    with open(JSONL_PATH, 'a') as f:
        f.write(json.dumps(entry) + '\n')

    return entry


def upload_to_blob(connection_string: str) -> bool:
    """Upload JSONL to Azure Blob Storage."""
    try:
        from azure.storage.blob import BlobServiceClient
        client = BlobServiceClient.from_connection_string(connection_string)
        container = client.get_container_client("ztc-telemetry")
        blob_name = f"sessions/{JSONL_PATH.name}"
        with open(JSONL_PATH, 'rb') as f:
            container.upload_blob(blob_name, f, overwrite=True)
        return True
    except Exception as e:
        print(f"[telemetry] blob upload failed: {e}")
        return False
