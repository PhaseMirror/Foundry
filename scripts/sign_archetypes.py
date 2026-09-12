import json
import base64
import os
from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.hazmat.primitives import serialization

# 1. Generate or load a local Ed25519 keypair for signing
private_key_path = "ed25519_private.pem"
try:
    with open(private_key_path, "rb") as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None
        )
    print("Loaded existing private key.")
except FileNotFoundError:
    private_key = ed25519.Ed25519PrivateKey.generate()
    with open(private_key_path, "wb") as key_file:
        key_file.write(
            private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            )
        )
    print("Generated and saved new private key.")

public_key = private_key.public_key()
pub_bytes = public_key.public_bytes(
    encoding=serialization.Encoding.Raw,
    format=serialization.PublicFormat.Raw
)
pub_b64 = base64.b64encode(pub_bytes).decode('utf-8')
print(f"Ed25519 Public Key (Base64): {pub_b64}")

def sign_archetype(input_path, output_path):
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found.")
        return
        
    with open(input_path, 'r') as f:
        data = json.load(f)
    
    content_hash_hex = data['contentHash']
    # Sign the raw bytes of the contentHash string
    sig_bytes = private_key.sign(content_hash_hex.encode('utf-8'))
    sig_b64 = base64.b64encode(sig_bytes).decode('utf-8')
    
    # Update signatories with real public key and signature
    for signatory in data['signatories']:
        signatory['publicKey'] = pub_b64
        signatory['signature'] = sig_b64
    
    # Update review notes indicating automated sign
    data['auditMetadata']['notes'] += " Signed via Ed25519 batch utility."
    data['auditMetadata']['auditStatus'] = "Approved"
    
    with open(output_path, 'w') as f:
        json.dump(data, f, indent=2)
    print(f"Signed {input_path} -> Saved to {output_path}")

sign_archetype("baa_initial.json", "baa_signed.json")
sign_archetype("dpa_initial.json", "dpa_signed.json")
