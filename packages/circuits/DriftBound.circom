pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/comparators.circom";

/**
 * DriftBound - MTPI Drift Constraint Enforcement Template
 * 
 * PURPOSE:
 * Enforces MTPI constitutional constraint: δ(t) ≤ ε·‖Ξ‖ where ε = 0.3
 * Prevents unbounded state evolution and temporal manipulation attacks.
 * Implements core Ξ-Constitution principle of bounded drift.
 * 
 * MATHEMATICAL FORMULATION:
 * - Drift constraint: 10·δ ≤ 3·ξ (equivalent to δ ≤ 0.3·ξ)
 * - δ (delta): Scalar drift measure (e.g., timestamp - nonce)
 * - ξ (xi): Scalar norm proxy (e.g., state hash magnitude)
 * - ε (epsilon): Fixed bound 0.3 (encoded as ratio 3/10)
 * 
 * INPUTS:
 * - delta: Non-negative scalar drift value (in wei or dimensionless units)
 * - xi: Non-negative scalar norm proxy (state magnitude estimate)
 * 
 * OUTPUTS:
 * - ok: 1 if drift bound satisfied (10·δ ≤ 3·ξ), 0 otherwise
 * 
 * CONSTRAINTS:
 * - Arithmetic: lhs = 10 × delta, rhs = 3 × xi
 * - Comparison: lhs < rhs + 1 (implements lhs ≤ rhs)
 * - Bit width: Uses 80-bit LessThan for safety margin
 * 
 * SECURITY CONSIDERATIONS:
 * - Prevents temporal manipulation: large time gaps rejected
 * - Overflow protection: 80-bit comparison provides headroom
 * - Relative bound: drift scaled to state magnitude (not absolute)
 * - Always non-negative: delta and xi should be >= 0
 * 
 * MTPI/WEB4 ALIGNMENT:
 * - Implements core Ξ-Constitution Article on bounded evolution
 * - Prevents drift attacks while allowing legitimate state changes
 * - Auditable: constraint is transparent and mathematically precise
 * - Lawful: enforces MTPI constitutional limits in-circuit
 * - No surveillance: pure mathematical constraint, no data collection
 * 
 * TYPICAL USAGE:
 * // In RootContract or RecoveryContract
 * signal drift;
 * drift <== timestamp - nonce;
 * 
 * component driftCheck = DriftBound();
 * driftCheck.delta <== drift;
 * driftCheck.xi <== stateHash; // Using stateHash as norm proxy
 * driftCheck.ok === 1; // Enforce constraint
 * 
 * CALIBRATION:
 * - ε = 0.3 chosen to balance security and usability
 * - Larger ε: more permissive (easier to satisfy, less secure)
 * - Smaller ε: more restrictive (harder to satisfy, more secure)
 * - Current value (0.3 Ξ) represents ~30% relative drift tolerance
 */

// Enforce drift bound: 10*delta <= 3*xi (epsilon = 0.3)
template DriftBound() {
    signal input delta;  // nonnegative scalar drift
    signal input xi;     // nonnegative scalar norm
    signal output ok;
    
    signal lhs;
    lhs <== 10 * delta;
    
    signal rhs;
    rhs <== 3 * xi;
    
    // lhs <= rhs means lhs < rhs + 1
    component lt = LessThan(80);
    lt.in[0] <== lhs;
    lt.in[1] <== rhs + 1;
    
    ok <== lt.out;
}
