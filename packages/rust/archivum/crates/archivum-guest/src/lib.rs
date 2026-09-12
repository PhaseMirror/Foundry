use std::mem;

/// Allocate memory in the guest for the host to write input data.
#[no_mangle]
pub extern "C" fn prime_alloc(len: usize) -> *mut u8 {
    let mut buf = Vec::with_capacity(len);
    let ptr = buf.as_mut_ptr();
    mem::forget(buf);
    ptr
}

/// Deallocate memory in the guest.
#[no_mangle]
pub extern "C" fn prime_dealloc(ptr: *mut u8, len: usize) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        let _ = Vec::from_raw_parts(ptr, 0, len);
    }
}
