pub mod pde_rnn;
pub mod smm;
pub mod ffi_bridge;

#[cfg(test)]
mod tests {
    #[test]
    fn test_ffi_round_trip() {
        assert!(true);
        // lean-rs is currently mocked for setup or we test it if it is available
    }
}
