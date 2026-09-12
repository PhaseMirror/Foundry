import cbor2
import blake3
import json
import os

def generate_test_vector(test_id, desc, input_data, expected_output, max_fuel=1000000):
    expected_cbor = cbor2.dumps(expected_output, canonical=True)
    expected_hash = blake3.blake3(expected_cbor).digest()
    
    # We create a dummy decomposition hash here, in a real scenario this is calculated from full output
    decomp_hash = blake3.blake3(expected_cbor).digest()
    
    test_vector = {
        "test_id": test_id,
        "description": desc,
        "registry_hash": bytes.fromhex("32bd4f7e00000000000000000000000000000000000000000000000000000000"),
        "object_cbor": cbor2.dumps(input_data, canonical=True),
        "expected": {
            "decomposition_hash": decomp_hash,
            "results": [
                {
                    "prime_id": "core/media-type",
                    "prime_version": "1.0.0",
                    "output_cbor": expected_cbor,
                    "output_hash": expected_hash
                }
            ]
        },
        "limits": {
            "max_fuel": max_fuel,
            "max_time_ms": 1000,
            "max_memory_pages": 256
        }
    }
    
    out_dir = "../tests/vectors"
    os.makedirs(out_dir, exist_ok=True)
    
    cbor_path = os.path.join(out_dir, f"{test_id}.cbor")
    with open(cbor_path, "wb") as f:
        cbor2.dump(test_vector, f, canonical=True)
        
    hash_path = os.path.join(out_dir, f"{test_id}.hash")
    with open(cbor_path, "rb") as f:
        file_hash = blake3.blake3(f.read()).hexdigest()
    with open(hash_path, "w") as f:
        f.write(file_hash)

if __name__ == "__main__":
    generate_test_vector(
        "test-001-plain-text",
        "Simple UTF-8 text, NFC normalized",
        {
            "cid_raw": "b5d4045c",
            "media_type": "text/plain",
            "norm_repr": b"Hello world\nThis is a test."
        },
        "text/plain"
    )
    print("Test vectors generated.")
