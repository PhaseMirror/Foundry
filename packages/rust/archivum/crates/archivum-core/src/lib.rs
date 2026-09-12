use anyhow::Result;
use wasmtime::{Config, Engine, Store};

/// Creates a strictly deterministic Wasmtime engine compliant with Prime ABI v0.
pub fn create_deterministic_engine() -> Result<Engine> {
    let mut config = Config::new();
    
    // CRITICAL: Fuel is deterministic, epochs are not
    config.consume_fuel(true);
    
    // Disable features that introduce non-determinism
    config.wasm_simd(false);
    config.wasm_relaxed_simd(false);
    config.epoch_interruption(false);
    
    // Enable useful features
    config.wasm_bulk_memory(true);
    config.wasm_reference_types(false); // Keep simple for Phase 1
    
    // Optional: Set cache for performance (doesn't affect determinism)
    // We omit explicit cache path config for simplicity, relying on Wasmtime defaults or memory.
    
    Engine::new(&config)
}

/// Sets up a new Store with a predefined fuel allocation.
pub fn create_deterministic_store<T>(engine: &Engine, data: T, fuel: u64) -> Result<Store<T>> {
    let mut store = Store::new(engine, data);
    store.set_fuel(fuel)?;
    Ok(store)
}
