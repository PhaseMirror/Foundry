use num_bigint::BigUint;

pub const BN254_MODULUS_STR: &str = "21888242871839275222246405745257275088548364400416034343698204186575808495617";

pub fn poseidon_hash(inputs: Vec<BigUint>) -> BigUint {
    let modulus = BigUint::parse_bytes(BN254_MODULUS_STR.as_bytes(), 10).unwrap();
    let width = 3;
    let rounds = 8;

    let mut state = vec![BigUint::from(0u32); width];

    for (i, inp) in inputs.iter().enumerate() {
        let idx = i % width;
        state[idx] = (&state[idx] + inp) % &modulus;
    }

    for round_idx in 0..rounds {
        // S-box: cube
        for i in 0..width {
            state[i] = state[i].modpow(&BigUint::from(3u32), &modulus);
        }

        // Linear layer
        let mut new_state = vec![BigUint::from(0u32); width];
        for i in 0..width {
            for j in 0..width {
                let coeff = BigUint::from((i + j + 1) as u32);
                new_state[i] = (&new_state[i] + &coeff * &state[j]) % &modulus;
            }
        }
        state = new_state;

        // Round constants
        for i in 0..width {
            let constant = BigUint::from((round_idx * 1000 + i * 100 + 42) as u32);
            state[i] = (&state[i] + constant) % &modulus;
        }
    }

    state[0].clone()
}

pub fn poseidon_hash_bytes(data: &[u8]) -> BigUint {
    let modulus = BigUint::parse_bytes(BN254_MODULUS_STR.as_bytes(), 10).unwrap();
    let chunk_size = 31;
    let mut chunks = Vec::new();

    for chunk in data.chunks(chunk_size) {
        let elem = BigUint::from_bytes_be(chunk) % &modulus;
        chunks.append(&mut vec![elem]);
    }

    if chunks.is_empty() {
        return BigUint::from(0u32);
    }

    poseidon_hash(chunks)
}
