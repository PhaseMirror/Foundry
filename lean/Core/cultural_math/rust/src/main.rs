//! Cultural Mathematics - Test Runner
//!
//! This binary runs basic tests on the verified implementations.

fn main() {
    println!("Cultural Mathematics - Verified Implementations");
    println!("===============================================");
    
    // Egyptian multiplication
    let result = cultural_math::egyptian_mul(3, 4);
    println!("Egyptian 3 × 4 = {}", result);
    assert_eq!(result, 12);
    
    // Chinese CRT (simplified)
    let result = cultural_math::chinese_crt(3, 5, 1, 2);
    println!("Chinese CRT(3,5,1,2) = {}", result);
    
    // Vedic multiplication
    let result = cultural_math::vedic_mul(3, 4, 10);
    println!("Vedic (3,4,10) = {}", result);
    assert_eq!(result, 13 * 14);
    
    // African halving
    let result = cultural_math::african_halve(8);
    println!("African halve(8) = {}", result);
    assert_eq!(result, 4);
    
    // Russian boundary operation
    let result = cultural_math::boundary_op(3, 5);
    println!("Russian boundary(3,5) = {}", result);
    assert_eq!(result, 0);
    
    // GRTF iterate
    let result = cultural_math::grtf_iterate(1, 1, &[]);
    println!("GRTF iterate(1,1,[]) = {}", result);
    assert_eq!(result, 0);
    
    println!("\nAll tests passed!");
}
