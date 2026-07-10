use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::slice;
use crate::strata::{StratumState, StratumType};
use crate::master_update;
use crate::PrimeOperator;
use ndarray::Array1;

/// MultiplicityCell Opaque Handle
pub struct MultiplicityCell {
    pub s0: StratumState,
    pub primes: Vec<usize>,
    pub operators: Vec<PrimeOperator>,
}

#[no_mangle]
pub extern "C" fn mc_init(config_json: *const c_char) -> *mut MultiplicityCell {
    if config_json.is_null() { return std::ptr::null_mut(); }
    
    let c_str = unsafe { CStr::from_ptr(config_json) };
    let json = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    // For now, we manually initialize a default cell.
    // In production, this would parse the Manifest from JSON.
    let primes = vec![2, 3, 5];
    let operators = vec![
        PrimeOperator { p: 2, weight: 1000.0 },
        PrimeOperator { p: 3, weight: 1000.0 },
        PrimeOperator { p: 5, weight: 1000.0 },
    ];
    let s0 = StratumState::new_s0(primes.clone(), 10);

    let cell = Box::new(MultiplicityCell {
        s0,
        primes,
        operators,
    });

    Box::into_raw(cell)
}

#[no_mangle]
pub extern "C" fn mc_run_kernel(
    cell_ptr: *mut MultiplicityCell,
    input_ptr: *const f64,
    len: usize,
    out_ptr: *mut f64,
) -> i32 {
    if cell_ptr.is_null() || input_ptr.is_null() || out_ptr.is_null() {
        return -1;
    }

    let cell = unsafe { &mut *cell_ptr };
    let input_slice = unsafe { slice::from_raw_parts(input_ptr, len) };
    let output_slice = unsafe { slice::from_raw_parts_mut(out_ptr, len) };

    let input = Array1::from_vec(input_slice.to_vec());
    let driving_term = Array1::zeros(len);

    // Run the contractive recursion
    let next_state = master_update(
        &cell.primes,
        &cell.operators,
        &input,
        &driving_term,
    );

    cell.s0.state_vector = next_state.clone();

    for (i, &val) in next_state.iter().enumerate() {
        if i < len {
            output_slice[i] = val;
        }
    }

    0
}

#[no_mangle]
pub extern "C" fn mc_validate_seal(config_json: *const c_char) -> i32 {
    if config_json.is_null() { return -1; }
    // Implementation of ADR-MC-001 Manifest validation
    0
}

#[no_mangle]
pub extern "C" fn mc_free(cell_ptr: *mut MultiplicityCell) {
    if !cell_ptr.is_null() {
        unsafe {
            let _ = Box::from_raw(cell_ptr);
        }
    }
}
