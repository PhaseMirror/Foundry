use std::env;
use std::fs;
use std::path::Path;

fn main() {
    let out_dir = env::var("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("riemann_zeta_ffi.h");
    
    let header = r#"#ifndef RIEMANN_ZETA_FFI_H
#define RIEMANN_ZETA_FFI_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Evaluate ζ(s) at s = real + i*imag with given precision (bits).
// Returns low and high bounds of the verified interval.
void riemann_zeta_evaluate(uint32_t precision_bits, double real, double imag, double* low, double* high);

// Verify that s = 0.5 + i*t is a zero of ζ(s).
// Returns is_zero, real_part_lower, real_part_upper, imaginary_part, verification_bits.
bool riemann_zeta_verify_zero(uint32_t precision_bits, double imag, double* real_lower, double* real_upper, double* imag_out, uint32_t* bits);

// Compute the Gram point g_n.
double riemann_zeta_gram_point(uint32_t precision_bits, uint32_t n);

// Find all zeros in [t_min, t_max] on the critical line.
// Returns array of ZeroLocation structs and count via output parameters.
typedef struct {
    double imaginary_part;
    bool verified;
    double bound_width;
    double real_part_lower;
    double real_part_upper;
} ZeroLocation;

void riemann_zeta_find_zeros(uint32_t precision_bits, double t_min, double t_max, ZeroLocation** zeros, size_t* count);

#ifdef __cplusplus
}
#endif

#endif // RIEMANN_ZETA_FFI_H
"#;

    fs::write(&dest_path, header).expect("Failed to write FFI header");
    println!("cargo:rerun-if-changed=build.rs");
}
