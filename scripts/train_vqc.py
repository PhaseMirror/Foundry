#!/usr/bin/env python3
"""
Train a 4-qubit VQC for anomaly detection on 5D telemetry.
Outputs: vqc_params.pt, vqc_threshold.txt
"""

import pennylane as qml
import torch
import torch.nn as nn
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt

# ------------------------------
# Data Loading
# ------------------------------
def load_telemetry_data():
    # For now, we generate synthetic data for demonstration
    np.random.seed(42)
    n_samples = 1000
    # Normal samples
    normal = np.random.multivariate_normal(
        mean=[5.4, 0.0, 0.84, 0.87, 0.0],
        cov=np.diag([0.15, 0.001, 0.035, 0.025, 0.02]),
        size=int(n_samples * 0.95)
    )
    # Anomalous samples (higher entropy, unstable, high util)
    anomaly = np.random.multivariate_normal(
        mean=[6.2, 0.5, 0.92, 0.75, 0.1],
        cov=np.diag([0.2, 0.05, 0.03, 0.05, 0.04]),
        size=int(n_samples * 0.05)
    )
    X = np.vstack([normal, anomaly])
    y = np.hstack([np.zeros(len(normal)), np.ones(len(anomaly))])
    # Shuffle
    idx = np.random.permutation(len(X))
    return X[idx], y[idx]

X, y = load_telemetry_data()
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Scale features
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# ------------------------------
# Quantum Circuit Definition
# ------------------------------
n_qubits = 4
dev = qml.device('default.qubit', wires=n_qubits)

@qml.qnode(dev, interface='torch')
def vqc_circuit(params, x):
    # Angle embedding (5 features -> 4 qubits, 5th feature on first qubit as additional rotation)
    for i in range(n_qubits):
        qml.RY(x[i], wires=i)
    qml.RY(x[4], wires=0)  # encode 5th feature on first qubit

    # Variational layers
    for layer in range(4): # Reduced layers to speed up demo
        for i in range(n_qubits):
            qml.RY(params[0][layer][i], wires=i)
            qml.RZ(params[1][layer][i], wires=i)
        for i in range(n_qubits - 1):
            qml.CNOT(wires=[i, i+1])
        qml.CNOT(wires=[n_qubits-1, 0])

    return qml.expval(qml.PauliZ(0))  # anomaly score

# ------------------------------
# Training
# ------------------------------
class VQCAnomalyDetector(nn.Module):
    def __init__(self, n_layers=4):
        super().__init__()
        self.n_layers = n_layers
        self.params_ry = nn.Parameter(torch.randn(n_layers, n_qubits) * 0.1)
        self.params_rz = nn.Parameter(torch.randn(n_layers, n_qubits) * 0.1)

    def forward(self, x):
        # x is a batch of 5D vectors
        params = (self.params_ry, self.params_rz)
        scores = []
        for sample in x:
            score = vqc_circuit(params, sample)
            scores.append(score)
        return torch.stack(scores).view(-1, 1)

model = VQCAnomalyDetector()
optimizer = torch.optim.Adam(model.parameters(), lr=0.01)
criterion = nn.BCEWithLogitsLoss()

# Convert data to torch tensors
X_train_t = torch.tensor(X_train_scaled, dtype=torch.float32)
y_train_t = torch.tensor(y_train, dtype=torch.float32).view(-1, 1)

# Training loop
epochs = 2 # Reduced epochs for demo speed
for epoch in range(epochs):
    optimizer.zero_grad()
    pred = model(X_train_t)
    loss = criterion(pred, y_train_t)
    loss.backward()
    optimizer.step()
    if epoch % 1 == 0:
        print(f"Epoch {epoch}: loss = {loss.item():.4f}")

# Evaluate on test set
X_test_t = torch.tensor(X_test_scaled, dtype=torch.float32)
y_test_t = torch.tensor(y_test, dtype=torch.float32).view(-1, 1)
with torch.no_grad():
    test_pred = model(X_test_t)
    test_loss = criterion(test_pred, y_test_t)
    print(f"Test loss: {test_loss.item():.4f}")

# Determine threshold (95th percentile of scores on normal test samples)
normal_mask = y_test == 0
normal_scores = test_pred[normal_mask].numpy().flatten()
threshold = np.percentile(normal_scores, 99.9)  # 0.1% false positive rate
print(f"Threshold: {threshold:.4f}")

# Save model and threshold
torch.save(model.state_dict(), 'models/vqc_params.pt')
with open('models/vqc_threshold.txt', 'w') as f:
    f.write(str(threshold))
# Save scaler
import joblib
joblib.dump(scaler, 'models/vqc_scaler.pkl')
