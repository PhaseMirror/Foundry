"""
Educational Poseidon hash over BN254 scalar field.

This is a reference implementation for demonstration purposes.
For production, use a well-audited cryptographic library.
"""

# BN254 scalar field modulus (order of G1)
BN254_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617


def poseidon_hash(*inputs: int, modulus: int = BN254_MODULUS) -> int:
    """
    Educational Poseidon hash (simplified sponge construction).
    
    WARNING: This is NOT a secure implementation. It's a pedagogical example
    showing the structure of a sponge-based hash function over a prime field.
    
    For production use, integrate a proper Poseidon implementation like:
    - circomlib's Poseidon
    - Neptune (Rust)
    - dusk-poseidon
    
    Args:
        *inputs: Variable number of field elements to hash
        modulus: Prime field modulus (default: BN254 scalar field)
    
    Returns:
        Hash digest as a field element
    """
    # Simplified parameters (not cryptographically secure)
    WIDTH = 3  # State width
    ROUNDS = 8  # Total rounds
    
    # Initialize state
    state = [0] * WIDTH
    
    # Absorb phase: XOR inputs into state
    input_list = list(inputs)
    for i, inp in enumerate(input_list):
        state[i % WIDTH] = (state[i % WIDTH] + inp) % modulus
    
    # Permutation phase: simplified round function
    for round_idx in range(ROUNDS):
        # S-box: cube each element
        for i in range(WIDTH):
            state[i] = pow(state[i], 3, modulus)
        
        # Linear layer: simplified MDS-like mixing
        new_state = [0] * WIDTH
        for i in range(WIDTH):
            for j in range(WIDTH):
                # Simplified mixing matrix (not actual MDS)
                coeff = (i + j + 1) % modulus
                new_state[i] = (new_state[i] + coeff * state[j]) % modulus
        state = new_state
        
        # Round constants: simple pattern (not cryptographically hardened)
        for i in range(WIDTH):
            state[i] = (state[i] + round_idx * 1000 + i * 100 + 42) % modulus
    
    # Squeeze phase: return first element
    return state[0]


def poseidon_hash_bytes(data: bytes, modulus: int = BN254_MODULUS) -> int:
    """
    Hash arbitrary bytes by chunking into field elements.
    
    Args:
        data: Bytes to hash
        modulus: Prime field modulus
    
    Returns:
        Hash digest as a field element
    """
    # Convert bytes to field elements (chunk by 31 bytes to stay under modulus)
    chunk_size = 31  # Safe for BN254 (32 bytes but need < modulus)
    chunks = []
    
    for i in range(0, len(data), chunk_size):
        chunk = data[i:i+chunk_size]
        # Interpret as big-endian integer
        elem = int.from_bytes(chunk, byteorder='big') % modulus
        chunks.append(elem)
    
    # Hash all chunks
    if not chunks:
        return 0
    
    return poseidon_hash(*chunks, modulus=modulus)
