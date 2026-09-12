from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
import json

app = FastAPI(
    title="Zeta-ROS Lattice API",
    description="Live queryable research service for the conscious tensor metrics.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def read_json_safe(filepath: str):
    path = Path(filepath)
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text())
    except Exception:
        return None

@app.get("/")
def root():
    return {"status": "online", "message": "Zeta-ROS API is active."}

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.get("/metrics")
def get_metrics():
    metrics = read_json_safe("benchmarks/metrics.json")
    if metrics is None:
        raise HTTPException(status_code=404, detail="Metrics not found")
    return {"metrics": metrics}

@app.get("/attestation")
def get_stark_receipt():
    receipt = read_json_safe("artifacts/stark_receipt.json")
    if receipt is None:
        raise HTTPException(status_code=404, detail="STARK receipt not found")
    return {"stark_receipt": receipt}
