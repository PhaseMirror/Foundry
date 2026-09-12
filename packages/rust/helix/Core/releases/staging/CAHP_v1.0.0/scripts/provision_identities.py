#!/usr/bin/env python3
import os
import sys
from cryptography.hazmat.primitives import serialization

# Adjust path to find modules
sys.path.append(os.path.expanduser("~/helix-core-unified/helix-ledger"))
from core.identity.l0_registry import L0Registry

KEY_DIR = os.path.expanduser("~/helix-core-unified/helix-ledger/keys")
REGISTRY_PATH = os.path.expanduser("~/helix-core-unified/helix-ledger/core/identity/registry_v1.json")

def save_private_key(node_id, private_key):
    pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    path = os.path.join(KEY_DIR, f"{node_id}.pem")
    with open(path, "wb") as f:
        f.write(pem)
    print(f"Saved private key for {node_id} to {path}")

def main():
    if not os.path.exists(KEY_DIR):
        os.makedirs(KEY_DIR)
        
    registry = L0Registry(REGISTRY_PATH)
    
    nodes = [
        ("node_goose_01", "system_architect"),
        ("node_gemini_01", "color_artist"),
        ("operator_steve", "sysadmin")
    ]
    
    print("--- Generating L0 Identities ---")
    for node_id, role in nodes:
        print(f"Provisioning {node_id}...")
        priv, pub_pem = L0Registry.generate_identity()
        save_private_key(node_id, priv)
        registry.register_node(node_id, pub_pem, role)
        print(f"Registered {node_id} in {REGISTRY_PATH}")

if __name__ == "__main__":
    main()
