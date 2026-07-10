use num_bigint::{BigInt, Sign};
use sha2::{Sha256, Digest};
use std::str::FromStr;
use crate::GoldilocksField;

pub const BN254_PRIME_STR: &str = "21888242871839275222246405745257275088548364400416034343698204186575808495617";

pub fn get_bn254_prime() -> BigInt {
    BigInt::from_str(BN254_PRIME_STR).unwrap()
}

pub const POSEIDON2_T: usize = 9;
pub const POSEIDON2_R: usize = 8;
pub const RF: usize = 8;
pub const RP: usize = 57;

pub struct Poseidon2BN254 {
    prime: BigInt,
    mds: Vec<Vec<BigInt>>,
    round_constants: Vec<BigInt>,
}

impl Poseidon2BN254 {
    pub fn new() -> Self {
        let p = get_bn254_prime();
        let mds = Self::build_mds_matrix(POSEIDON2_T, &p);
        let round_constants = Self::build_round_constants(RF * POSEIDON2_T + RP, &p);
        Self { prime: p, mds, round_constants }
    }

    fn build_mds_matrix(t: usize, p: &BigInt) -> Vec<Vec<BigInt>> {
        let mut seed_row = Vec::new();
        for i in 0..t {
            let mut hasher = Sha256::new();
            hasher.update(format!("poseidon2-mds-row0-col{}-t{}", i, t).as_bytes());
            let hash = hasher.finalize();
            seed_row.push(BigInt::from_bytes_be(Sign::Plus, &hash) % p);
        }

        let mut matrix = Vec::new();
        for k in 0..t {
            let mut row = Vec::new();
            for i in 0..t {
                row.push(seed_row[(i + k) % t].clone());
            }
            matrix.push(row);
        }
        matrix
    }

    fn build_round_constants(num: usize, p: &BigInt) -> Vec<BigInt> {
        let mut constants = Vec::new();
        for i in 0..num {
            let mut hasher = Sha256::new();
            hasher.update(format!("poseidon2-rc-{}", i).as_bytes());
            let hash = hasher.finalize();
            constants.push(BigInt::from_bytes_be(Sign::Plus, &hash) % p);
        }
        constants
    }

    pub fn permute(&self, state: &mut [BigInt]) {
        let t = state.len();
        let mut rc_idx = 0;

        for _ in 0..(RF / 2) {
            for i in 0..t {
                state[i] = (&state[i] + &self.round_constants[rc_idx]) % &self.prime;
                rc_idx += 1;
            }
            for i in 0..t {
                state[i] = state[i].pow(5) % &self.prime;
            }
            self.mds_mix(state);
        }

        for _ in 0..RP {
            state[0] = (&state[0] + &self.round_constants[rc_idx]) % &self.prime;
            rc_idx += 1;
            state[0] = state[0].pow(5) % &self.prime;
            self.mds_mix(state);
        }

        for _ in 0..(RF / 2) {
            for i in 0..t {
                state[i] = (&state[i] + &self.round_constants[rc_idx]) % &self.prime;
                rc_idx += 1;
            }
            for i in 0..t {
                state[i] = state[i].pow(5) % &self.prime;
            }
            self.mds_mix(state);
        }
    }

    fn mds_mix(&self, state: &mut [BigInt]) {
        let t = state.len();
        let mut new_state = vec![BigInt::from(0); t];
        for i in 0..t {
            let mut acc = BigInt::from(0);
            for j in 0..t {
                acc = (acc + &self.mds[i][j] * &state[j]) % &self.prime;
            }
            new_state[i] = acc;
        }
        for i in 0..t {
            state[i] = new_state[i].clone();
        }
    }
}

/// Poseidon2 over Goldilocks Field
pub struct Poseidon2Goldilocks {
    mds: Vec<Vec<GoldilocksField>>,
    round_constants: Vec<GoldilocksField>,
}

impl Poseidon2Goldilocks {
    pub fn new() -> Self {
        let mds = Self::build_mds_matrix(POSEIDON2_T);
        let round_constants = Self::build_round_constants(RF * POSEIDON2_T + RP);
        Self { mds, round_constants }
    }

    fn build_mds_matrix(t: usize) -> Vec<Vec<GoldilocksField>> {
        let mut seed_row = Vec::new();
        for i in 0..t {
            let mut hasher = Sha256::new();
            hasher.update(format!("poseidon2-gl-mds-row0-col{}-t{}", i, t).as_bytes());
            let hash = hasher.finalize();
            let val = u64::from_be_bytes(hash[0..8].try_into().unwrap());
            seed_row.push(GoldilocksField::new(val));
        }

        let mut matrix = Vec::new();
        for k in 0..t {
            let mut row = Vec::new();
            for i in 0..t {
                row.push(seed_row[(i + k) % t]);
            }
            matrix.push(row);
        }
        matrix
    }

    fn build_round_constants(num: usize) -> Vec<GoldilocksField> {
        let mut constants = Vec::new();
        for i in 0..num {
            let mut hasher = Sha256::new();
            hasher.update(format!("poseidon2-gl-rc-{}", i).as_bytes());
            let hash = hasher.finalize();
            let val = u64::from_be_bytes(hash[0..8].try_into().unwrap());
            constants.push(GoldilocksField::new(val));
        }
        constants
    }

    pub fn permute(&self, state: &mut [GoldilocksField]) {
        let t = state.len();
        let mut rc_idx = 0;

        for _ in 0..(RF / 2) {
            for i in 0..t {
                state[i] = state[i] + self.round_constants[rc_idx];
                rc_idx += 1;
            }
            for i in 0..t {
                state[i] = state[i].pow(7); // Use 7 for Goldilocks S-box if appropriate, or keep 5
            }
            self.mds_mix(state);
        }

        for _ in 0..RP {
            state[0] = state[0] + self.round_constants[rc_idx];
            rc_idx += 1;
            state[0] = state[0].pow(7);
            self.mds_mix(state);
        }

        for _ in 0..(RF / 2) {
            for i in 0..t {
                state[i] = state[i] + self.round_constants[rc_idx];
                rc_idx += 1;
            }
            for i in 0..t {
                state[i] = state[i].pow(7);
            }
            self.mds_mix(state);
        }
    }

    fn mds_mix(&self, state: &mut [GoldilocksField]) {
        let t = state.len();
        let mut new_state = vec![GoldilocksField::ZERO; t];
        for i in 0..t {
            let mut acc = GoldilocksField::ZERO;
            for j in 0..t {
                acc = acc + self.mds[i][j] * state[j];
            }
            new_state[i] = acc;
        }
        state.copy_from_slice(&new_state);
    }
}
