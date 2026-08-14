use nalgebra::DVector;
use serde::{Deserialize, Serialize};
use std::error::Error;
use std::path::Path;

#[derive(Debug, Serialize, Deserialize)]
pub struct BiomarkerRecord {
    pub cell_id: String,
    pub phase_index: usize,
    pub phase_label: String,
    pub asi_mode: String,
    pub seed: u64,
    pub qr_ratio: f64,
    pub ddq50: f64,
    pub w_t: f64,
}

pub fn load_biomarker_data<P: AsRef<Path>>(path: P) -> Result<Vec<BiomarkerRecord>, Box<dyn Error>> {
    let mut reader = csv::Reader::from_path(path)?;
    let mut records = Vec::new();
    for result in reader.deserialize() {
        let record: BiomarkerRecord = result?;
        records.push(record);
    }
    Ok(records)
}

pub fn records_to_trajectories(records: Vec<BiomarkerRecord>) -> Vec<Vec<DVector<f64>>> {
    let mut trajectories = std::collections::HashMap::new();
    
    for r in records {
        let entry = trajectories.entry(r.cell_id.clone()).or_insert_with(Vec::new);
        // We use qr_ratio, ddq50, and w_t as our 3D state vector
        entry.push((r.phase_index, DVector::from_vec(vec![r.qr_ratio, r.ddq50, r.w_t])));
    }
    
    let mut result = Vec::new();
    for mut traj in trajectories.into_values() {
        traj.sort_by_key(|(idx, _)| *idx);
        result.push(traj.into_iter().map(|(_, v)| v).collect());
    }
    result
}
