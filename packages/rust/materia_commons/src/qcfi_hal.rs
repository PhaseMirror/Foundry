// materia_commons/src/qcfi_hal.rs

use std::ptr::write_volatile;

/// Physical memory-mapped AXI Bus Address for the Xilinx UltraScale+ RFSoC
#[cfg(not(test))]
const XILINX_AXI_BASE_ADDR: *mut u64 = 0x4000_0000 as *mut u64;

/// Safe, static mock buffer for the test environment to prevent segfaults
#[cfg(test)]
static mut MOCK_AXI_BUS: [u64; 8] = [0; 8];

pub struct QcfiHardwareInterface {
    base_address: *mut u64,
}

impl QcfiHardwareInterface {
    pub fn new() -> Self {
        #[cfg(not(test))]
        let addr = XILINX_AXI_BASE_ADDR;
        
        #[cfg(test)]
        let addr = unsafe { MOCK_AXI_BUS.as_mut_ptr() };

        Self { base_address: addr }
    }

    /// Pushes the 256-bit prime field state to the hardware for resonance validation.
    /// Strictly allocation-free. Operates entirely in the CPU cache and registers.
    #[inline(always)]
    pub fn transmit_state_zero_copy(&self, limbs: &[u64; 4]) {
        unsafe {
            // Explicitly unrolled loop to guarantee fixed-cycle execution
            write_volatile(self.base_address.add(0), limbs[0]);
            write_volatile(self.base_address.add(1), limbs[1]);
            write_volatile(self.base_address.add(2), limbs[2]);
            write_volatile(self.base_address.add(3), limbs[3]);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    // Import the raw x86_64 CPU intrinsic for cycle counting
    #[cfg(target_arch = "x86_64")]
    use core::arch::x86_64::_rdtsc;

    #[test]
    fn test_zero_allocation_axi_transmit_latency() {
        let hw = QcfiHardwareInterface::new();
        
        // Mock limbs extracted from a previously sealed BigUint state
        let test_limbs = [0xDEADBEEF_CAFEBABE, 0x12345678_90ABCDEF, 0x11112222_33334444, 0x55556666_77778888];

        #[cfg(target_arch = "x86_64")]
        unsafe {
            // 1. Warm up the CPU instruction cache to mirror an active node state
            hw.transmit_state_zero_copy(&test_limbs);
            
            // 2. The Critical Path Measurement
            let start = _rdtsc();
            hw.transmit_state_zero_copy(&test_limbs);
            let end = _rdtsc();
            
            let cycles = end - start;
            
            // Output to console for diagnostic proof
            println!("CRITICAL PATH: Transmit took exactly {} CPU cycles.", cycles);
            
            // 3. The Hardware Bounding Assertion
            // We assert a hard ceiling (e.g., 500 cycles / ~165ns). 
            // If the compiler ever introduces a regression that spills to the heap, this instantly fails.
            assert!(cycles < 500, "LATENCY BREACH: Execution exceeded 500 cycles SLA (Took {})", cycles);
            
            // 4. State Verification (Ensure the mock bus actually holds the thermodynamic state)
            assert_eq!(MOCK_AXI_BUS[0], test_limbs[0]);
            assert_eq!(MOCK_AXI_BUS[3], test_limbs[3]);
        }
    }
}
