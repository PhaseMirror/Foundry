pub mod engine;

use crate::MultiplicityParams;

pub const SCALES: [u32; 4] = [0, 1, 2, 3];

impl MultiplicityParams {
    pub fn validate(&self) -> Result<(), String> {
        if self.scales_version == "v1" {
            if self.scales != SCALES {
                return Err(format!("scales (v1) must be exactly {:?}", SCALES));
            }
        }
        if self.noise_type != "binomial" {
            return Err("only 'binomial' noise type is supported".to_string());
        }
        Ok(())
    }
}
