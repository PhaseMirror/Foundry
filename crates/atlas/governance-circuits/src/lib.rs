pub const PROOF_HASH: &str = "LEAN_PROOF_HASH_108_CORE";
pub const CPIRTM_HASH: &str = "CPIRTM_CONTRACTIVE_VERIFIED_CORE";
pub const DRMM_HASH: &str = "DRMM_STABILITY_VERIFIED_CORE";
pub const WASM_WITNESS: &[u8] = include_bytes!("../../../target/wasm32-unknown-unknown/release/phase_mirror_wasm.wasm");

pub fn add(left: u64, right: u64) -> u64 {
    left + right
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}
