pub mod shamir;
pub mod vault;

pub use shamir::{split, combine, Share};
pub use vault::{SeedVault, VaultRecord, VaultError};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_shamir_roundtrip() {
        let secret = b"hello multiplicity";
        let shares = split(secret, 3, 5);
        assert_eq!(shares.len(), 5);
        
        let combined = combine(&shares[0..3]);
        assert_eq!(combined, secret);
    }

    #[test]
    fn test_vault_roundtrip() {
        let vault = SeedVault::new("test");
        let seed = b"super secret seed";
        let kek_material = b"user password";
        
        let record = vault.encrypt(seed, kek_material).unwrap();
        let decrypted = vault.decrypt(&record, kek_material).unwrap();
        
        assert_eq!(decrypted, seed);
    }
}
