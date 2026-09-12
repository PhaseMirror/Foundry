use light_poseidon::{Poseidon, PoseidonHasher};
use ark_bn254::Fr;
use ark_ff::{PrimeField, BigInteger, BigInteger256};
use num_bigint::BigUint;
use anyhow::Result;

pub struct MTPIZK;

impl MTPIZK {
    pub fn poseidon_hash_fr(inputs: &[Fr]) -> Result<Fr> {
        let mut poseidon = Poseidon::<Fr>::new_circom(inputs.len())
            .map_err(|e| anyhow::anyhow!("Poseidon init error: {:?}", e))?;
        let hash = poseidon.hash(inputs).map_err(|e| anyhow::anyhow!("Poseidon hash error: {:?}", e))?;
        Ok(hash)
    }

    pub fn biguint_to_fr(n: &BigUint) -> Fr {
        Fr::from_be_bytes_mod_order(&n.to_bytes_be())
    }

    pub fn fr_to_biguint(f: Fr) -> BigUint {
        let b: BigInteger256 = f.into();
        BigUint::from_bytes_be(&b.to_bytes_be())
    }

    pub fn compute_nk(identity_seed: BigUint) -> Result<BigUint> {
        let seed_fr = Self::biguint_to_fr(&identity_seed);
        let domain_fr = Fr::from(0u32);
        let hash = Self::poseidon_hash_fr(&[seed_fr, domain_fr])?;
        Ok(Self::fr_to_biguint(hash))
    }

    pub fn compute_identity_hash(identity_seed: BigUint) -> Result<BigUint> {
        let seed_fr = Self::biguint_to_fr(&identity_seed);
        let salt_fr = Fr::from(1u32);
        let hash = Self::poseidon_hash_fr(&[seed_fr, salt_fr])?;
        Ok(Self::fr_to_biguint(hash))
    }

    pub fn compute_r(nk: BigUint, epoch: u64, domain: u64, seq: u64) -> Result<BigUint> {
        let inputs = [
            Self::biguint_to_fr(&nk),
            Fr::from(epoch),
            Fr::from(domain),
            Fr::from(seq),
        ];
        let hash = Self::poseidon_hash_fr(&inputs)?;
        Ok(Self::fr_to_biguint(hash))
    }

    pub fn compute_nullifier(nk: BigUint, r: BigUint, epoch: u64, domain: u64) -> Result<BigUint> {
        let inputs = [
            Self::biguint_to_fr(&nk),
            Self::biguint_to_fr(&r),
            Fr::from(epoch),
            Fr::from(domain),
        ];
        let hash = Self::poseidon_hash_fr(&inputs)?;
        Ok(Self::fr_to_biguint(hash))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ark_bn254::Fr;
    use num_bigint::BigUint;

    #[test]
    fn test_poseidon_hash() {
        let input = Fr::from(12345u64);
        let hash = MTPIZK::poseidon_hash_fr(&[input]).unwrap();
        assert_ne!(hash, input);
    }

    #[test]
    fn test_nullifier_flow() {
        let seed = BigUint::from(123456789u64);
        let nk = MTPIZK::compute_nk(seed.clone()).unwrap();
        let r = MTPIZK::compute_r(nk.clone(), 1, 1, 0).unwrap();
        let nullifier = MTPIZK::compute_nullifier(nk.clone(), r.clone(), 1, 1).unwrap();
        
        assert_ne!(nullifier, BigUint::from(0u32));
        
        let r2 = MTPIZK::compute_r(nk.clone(), 1, 1, 1).unwrap();
        let nullifier2 = MTPIZK::compute_nullifier(nk.clone(), r2.clone(), 1, 1).unwrap();
        assert_ne!(nullifier, nullifier2);
    }
}
