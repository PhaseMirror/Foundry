#!/usr/bin/env python3
"""
VQC Anomaly Detection Sidecar
Subscribes to telemetry, runs inference, publishes anomaly scores to NATS.
"""

import asyncio
import json
import joblib
import torch
import numpy as np
import pennylane as qml
from nats.aio.client import Client as NATS
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ------------------------------
# Load Model & Scaler
# ------------------------------
n_qubits = 4
dev = qml.device('default.qubit', wires=n_qubits)

@qml.qnode(dev, interface='torch')
def vqc_circuit(params, x):
    for i in range(n_qubits):
        qml.RY(x[i], wires=i)
    qml.RY(x[4], wires=0)

    for layer in range(4): # 4 layers matching training
        for i in range(n_qubits):
            qml.RY(params[0][layer][i], wires=i)
            qml.RZ(params[1][layer][i], wires=i)
        for i in range(n_qubits - 1):
            qml.CNOT(wires=[i, i+1])
        qml.CNOT(wires=[n_qubits-1, 0])

    return qml.expval(qml.PauliZ(0))

class VQCAnomalyDetector:
    def __init__(self, state_dict, n_layers=4):
        self.n_layers = n_layers
        self.params_ry = state_dict['params_ry']
        self.params_rz = state_dict['params_rz']

    def forward(self, x):
        params = (self.params_ry, self.params_rz)
        return vqc_circuit(params, x)

scaler = joblib.load('models/vqc_scaler.pkl')
state_dict = torch.load('models/vqc_params.pt', map_location='cpu', weights_only=True)
with open('models/vqc_threshold.txt', 'r') as f:
    threshold = float(f.read())
model = VQCAnomalyDetector(state_dict)

# ------------------------------
# NATS Integration
# ------------------------------
async def main():
    nc = NATS()
    await nc.connect(servers=["nats://localhost:4222"])

    async def telemetry_handler(msg):
        data = json.loads(msg.data.decode())
        
        # Fallback values if fields are missing in synthetic telemetry
        entropy = data.get('entropy', 5.4)
        unstable_rate = data.get('unstable_rate', 0.0)
        utilization = data.get('utilization', data.get('util', 0.8))
        d16_frac = data.get('d16_frac', 0.8)
        thermal_slope = data.get('thermal_slope', 0.0)

        # Extract 5D vector
        vector = np.array([
            entropy,
            unstable_rate,
            utilization,
            d16_frac,
            thermal_slope
        ]).reshape(1, -1)
        # Scale
        vector_scaled = scaler.transform(vector)
        # Run inference
        score = model.forward(torch.tensor(vector_scaled[0], dtype=torch.float32)).item()
        # Publish score
        payload = {
            'timestamp': data.get('timestamp', 0),
            'anomaly_score': score,
            'threshold': threshold,
            'trigger': score < threshold
        }
        await nc.publish('uac.predict.anomaly', json.dumps(payload).encode())
        logger.info(f"Published anomaly score: {score:.4f} (Trigger: {payload['trigger']})")

    await nc.subscribe('uac.telemetry.fpga', cb=telemetry_handler)
    logger.info("VQC sidecar started, subscribed to uac.telemetry.fpga")

    # Keep running
    while True:
        await asyncio.sleep(1)

if __name__ == "__main__":
    asyncio.run(main())
