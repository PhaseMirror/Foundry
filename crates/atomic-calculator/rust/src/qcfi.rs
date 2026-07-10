//! Qudit-Classical Feedback Interface (QCFI)
//!
//! Enforces dimension constraints dynamically via the compiled ThermalWindow
//! bounded by the SnapKitty Math Engine models.

use crate::bounds::*;

/// Evaluates if the given scaled epsilon demands a lower qudit dimension.
/// Reflects the logic in `thermalWindowScaled` from Core.lean.
pub fn calculate_thermal_window(eps_scaled: u64, d_max: u64) -> (u64, u64) {
    let ema = (9 * eps_scaled + 1 * 5000) / 10;
    
    let lo_sub = (THERMAL_WINDOW_LO_SUB * ema) / SCALE;
    let lo = SCALE.saturating_sub(lo_sub);
    
    let hi_raw = SCALE + (THERMAL_WINDOW_HI_ADD * ema) / SCALE;
    let hi = if d_max * SCALE < hi_raw { d_max * SCALE } else { hi_raw };
    
    (lo, hi)
}

/// Dynamically adjusts qudit dimension bounded by the Thermodynamic window
pub fn adjust_dimension(eps_scaled: u64, current_d: u64, d_max: u64) -> u64 {
    let (lo, hi) = calculate_thermal_window(eps_scaled, d_max);
    let d_scaled = current_d * SCALE;
    
    if d_scaled > hi {
        // High friction, restrict window -> reduce dimension
        std::cmp::max(1, current_d / 2)
    } else if d_scaled < lo && current_d < d_max {
        // Expand dimension if allowed by lower bounds
        current_d * 2
    } else {
        current_d
    }
}
