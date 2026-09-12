import os
import json
import time
from typing import Dict, Optional, Tuple
from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.hazmat.primitives import serialization

class L0Registry:
    def __init__(self, registry_path: str = "l0_registry.json"):
        self.registry_path = registry_path
        self.registry = self._load_registry()

    def _load_registry(self) -> Dict:
        if os.path.exists(self.registry_path):
            with open(self.registry_path, 'r') as f:
                return json.load(f)
        return {}

    def _save_registry(self):
        with open(self.registry_path, 'w') as f:
            json.dump(self.registry, f, indent=2)

    def register_node(self, node_id: str, public_key_pem: bytes, role: str):
        """Register a node's public key."""
        # In a real system, this would be a governance action.
        # Here we just store it.
        pub_hex = public_key_pem.hex()
        self.registry[node_id] = {
            "public_key_hex": pub_hex,
            "role": role,
            "registered_at": time.time(),
            "status": "active"
        }
        self._save_registry()

    def get_public_key(self, node_id: str) -> Optional[ed25519.Ed25519PublicKey]:
        if node_id not in self.registry:
            return None
        hex_key = self.registry[node_id]["public_key_hex"]
        pem_bytes = bytes.fromhex(hex_key)
        return serialization.load_pem_public_key(pem_bytes)

    @staticmethod
    def generate_identity() -> Tuple[ed25519.Ed25519PrivateKey, bytes]:
        """Generates a new Ed25519 keypair."""
        private_key = ed25519.Ed25519PrivateKey.generate()
        public_key = private_key.public_key()
        
        public_pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        return private_key, public_pem

    @staticmethod
    def sign_payload(private_key: ed25519.Ed25519PrivateKey, payload: Dict) -> str:
        """Signs a JSON payload (canonicalized)."""
        data = json.dumps(payload, sort_keys=True).encode()
        signature = private_key.sign(data)
        return signature.hex()

    @staticmethod
    def verify_payload(public_key: ed25519.Ed25519PublicKey, payload: Dict, signature_hex: str) -> bool:
        """Verifies a signature against a payload."""
        try:
            data = json.dumps(payload, sort_keys=True).encode()
            signature = bytes.fromhex(signature_hex)
            public_key.verify(signature, data)
            return True
        except Exception:
            return False

# Example usage for setup script
if __name__ == "__main__":
    reg = L0Registry("core/identity/registry_v1.json")
    print("L0 Registry initialized.")
