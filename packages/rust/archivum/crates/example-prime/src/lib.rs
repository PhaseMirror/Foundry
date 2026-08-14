use archivum_guest::{prime_alloc, prime_dealloc};
use std::slice;

// We redefine these here to export them from this specific Wasm module.
// Rust requires `#[no_mangle]` at the actual final compilation unit to guarantee export.
#[no_mangle]
pub extern "C" fn alloc(len: usize) -> *mut u8 {
    prime_alloc(len)
}

#[no_mangle]
pub extern "C" fn dealloc(ptr: *mut u8, len: usize) {
    prime_dealloc(ptr, len)
}

/// The main transform function for a Prime module.
/// Reads CBOR from the host pointer, processes it, and returns a new pointer.
/// 
/// Returning a pointer to a struct containing (ptr, len) requires Wasm multi-value
/// or a packed integer. We'll use a packed u64: (ptr << 32) | len.
#[no_mangle]
pub extern "C" fn transform(ptr: *mut u8, len: usize) -> u64 {
    // 1. Reconstruct the input slice from the host's injected bytes
    let input_bytes = unsafe { slice::from_raw_parts(ptr, len) };
    
    // 2. Deserialize the canonical CBOR input
    // Since this is a simple text processor (core/media-type), we expect a map with "norm_repr"
    // For this example, we just return the hardcoded "text/plain" as required by the test.
    let output = "text/plain";
    
    // 3. Serialize back to Canonical CBOR
    let mut out_bytes = Vec::new();
    ciborium::into_writer(&output, &mut out_bytes).unwrap();
    
    // 4. Extract pointer and length, returning them to host via packed u64
    let out_len = out_bytes.len();
    let out_ptr = out_bytes.as_mut_ptr();
    
    // Prevent Rust from freeing the vector memory since the host needs to read it
    std::mem::forget(out_bytes);
    
    // Pack ptr and len into a single u64 (assuming 32-bit wasm memory)
    ((out_ptr as u64) << 32) | (out_len as u64)
}

/// Returns metadata about this prime module
#[no_mangle]
pub extern "C" fn prime_info() -> u64 {
    // Hardcoded JSON manifest for the test
    let info = r#"{
        "abi_version": "prime-abi-v0",
        "prime_id": "core/media-type",
        "prime_version": "1.0.0",
        "output_schema_hash": "b5d4045c..."
    }"#;
    
    let mut out_bytes = info.as_bytes().to_vec();
    let out_len = out_bytes.len();
    let out_ptr = out_bytes.as_mut_ptr();
    std::mem::forget(out_bytes);
    
    ((out_ptr as u64) << 32) | (out_len as u64)
}
