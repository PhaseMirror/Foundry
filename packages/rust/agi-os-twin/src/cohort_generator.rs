use anyhow::Result;
use nalgebra::DVector;
use rand::{Rng, SeedableRng};
use rand_distr::{Distribution, Normal};
use rand_chacha::ChaCha8Rng;
use serde::{Deserialize, Serialize};
use std::fs::File;
use std::io::Write;
use sha2::{Sha256, Digest};
use hex;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum DriftShape {
    Step,
    Ramp { days: u32 },
    Sigmoid { k: f64 },
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CohortSpec {
    pub n_subjects: usize,
    pub trajectory_days: usize,
    pub signal_snr_db: f64,
    pub lag_mean: f64,
    pub lag_std: f64,
    pub drift_shape: DriftShape,
    pub missing_rate: f64,
    pub episode_prevalence: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LagEntry {
    pub deidnum: String,
    pub hrv_drift_onset: f64,
    pub inflammatory_onset: f64,
    pub true_lag: f64,
    pub drift_shape: String,
    pub noise_seed: u64,
}

pub struct CohortGenerator {
    pub spec: CohortSpec,
    pub seed: u64,
}

impl CohortGenerator {
    pub fn new(spec: CohortSpec, seed: u64) -> Self {
        Self { spec, seed }
    }

    pub fn generate(&self, traj_path: &str, lag_path: &str) -> Result<String> {
        let mut rng = ChaCha8Rng::seed_from_u64(self.seed);
        let mut traj_file = File::create(traj_path)?;
        let mut lag_file = File::create(lag_path)?;

        writeln!(traj_file, "deidnum,visit,crp,il6,hrv_proxy")?;
        writeln!(lag_file, "deidnum,hrv_drift_onset,inflammatory_onset,true_lag,drift_shape,noise_seed")?;

        for i in 0..self.spec.n_subjects {
            let deidnum = format!("SUBJ-{:04}", i);
            let has_episode = rng.gen_bool(self.spec.episode_prevalence);
            let subject_seed = rng.gen::<u64>();
            let mut sub_rng = ChaCha8Rng::seed_from_u64(subject_seed);

            let (hrv_onset, infl_onset, lag) = if has_episode {
                let lag_dist = Normal::new(self.spec.lag_mean, self.spec.lag_std).unwrap();
                let lag = lag_dist.sample(&mut sub_rng).max(0.0);
                let hrv_onset = sub_rng.gen_range(5.0..20.0);
                (hrv_onset, hrv_onset + lag, lag)
            } else {
                (-1.0, -1.0, -1.0)
            };

            // Log ground truth
            writeln!(lag_file, "{},{},{},{},{:?},{}", 
                deidnum, hrv_onset, infl_onset, lag, self.spec.drift_shape, subject_seed)?;

            // Generate longitudinal data
            for day in 0..self.spec.trajectory_days {
                if rng.gen_bool(self.spec.missing_rate) {
                    continue; // Skip missing data points
                }

                let t = day as f64;
                let mut hrv_signal = 0.0;
                let mut crp_signal = 0.1;
                let mut il6_signal = 0.05;

                if has_episode {
                    // HRV Drift
                    if t >= hrv_onset {
                        let mag = -2.0;
                        hrv_signal = match self.spec.drift_shape {
                            DriftShape::Step => mag,
                            DriftShape::Ramp { days } => {
                                let progress = ((t - hrv_onset) / days as f64).min(1.0);
                                mag * progress
                            },
                            DriftShape::Sigmoid { k } => {
                                let midpoint = hrv_onset + 3.0;
                                mag / (1.0 + (-(k * (t - midpoint))).exp())
                            }
                        };
                    }

                    // Inflammatory Spike
                    if t >= infl_onset {
                        crp_signal = 5.0;
                        il6_signal = 3.0;
                    }
                }

                // Add Noise based on SNR
                // SNR_dB = 10 * log10(P_signal / P_noise)
                // P_noise = P_signal / 10^(SNR_dB / 10)
                let snr_linear = 10.0f64.powf(self.spec.signal_snr_db / 10.0);
                let signal_power = 1.0; // Normalized
                let noise_std = (signal_power / snr_linear).sqrt();
                let noise_dist = Normal::new(0.0, noise_std).unwrap();

                let hrv_obs = hrv_signal + noise_dist.sample(&mut sub_rng);
                let crp_obs = (crp_signal + noise_dist.sample(&mut sub_rng)).max(0.01f64);
                let il6_obs = (il6_signal + noise_dist.sample(&mut sub_rng)).max(0.01f64);

                writeln!(traj_file, "{},DAY_{},{},{},{}", deidnum, day, crp_obs, il6_obs, hrv_obs)?;
            }
        }

        // Seal the lag table
        let hash = self.compute_hash(lag_path)?;
        Ok(hash)
    }

    fn compute_hash(&self, path: &str) -> Result<String> {
        let mut file = File::open(path)?;
        let mut hasher = Sha256::new();
        std::io::copy(&mut file, &mut hasher)?;
        let hash = hasher.finalize();
        Ok(hex::encode(hash))
    }
}
