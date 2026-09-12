//! Glanville Fritillary Butterfly 50-Patch Metapopulation Benchmark (M³EM §6.1)

use crate::types::{DispersalEdge, HabitatGraph, ModelConfig, ObservationRecord, PatchState};
use rand_distr::{Distribution, Uniform};

/// Benchmark dataset generator for 50-patch Glanville fritillary metapopulation.
pub struct MetapopulationBenchmark;

impl MetapopulationBenchmark {
    /// Constructs a realistic 50-patch spatial habitat graph with exponential distance dispersal.
    pub fn build_aland_islands_graph() -> (HabitatGraph, Vec<f64>) {
        let num_patches = 50;
        let mut edges = Vec::new();
        let mut rng = rand::thread_rng();
        let unif = Uniform::new(0.0f64, 100.0f64);

        // Generate synthetic spatial coordinates (x_coord, y_coord, patch_area)
        let mut patch_coords: Vec<(f64, f64)> = Vec::with_capacity(num_patches);
        let mut patch_areas: Vec<f64> = Vec::with_capacity(num_patches);

        for _ in 0..num_patches {
            let x: f64 = unif.sample(&mut rng);
            let y: f64 = unif.sample(&mut rng);
            let area: f64 = 0.5 + unif.sample(&mut rng) * 0.05; // area in hectares
            patch_coords.push((x, y));
            patch_areas.push(area);
        }

        // Exponential dispersal kernel: a_vw = exp(-d_vw / d_0) * sqrt(A_v * A_w)
        let d_0 = 15.0f64; // mean dispersal distance in km
        for i in 0..num_patches {
            for j in (i + 1)..num_patches {
                let dx = patch_coords[i].0 - patch_coords[j].0;
                let dy = patch_coords[i].1 - patch_coords[j].1;
                let dist = (dx * dx + dy * dy).sqrt();

                if dist < 40.0 {
                    let coupling = (-dist / d_0).exp() * (patch_areas[i] * patch_areas[j]).sqrt() * 0.1;
                    if coupling > 0.001 {
                        edges.push(DispersalEdge {
                            source: i,
                            target: j,
                            weight: coupling,
                        });
                    }
                }
            }
        }

        (HabitatGraph::new(num_patches, edges), patch_areas)
    }

    /// Generates synthetic longitudinal survey observations across 10 annual seasons.
    pub fn generate_survey_data<R: rand::Rng>(
        graph: &HabitatGraph,
        config: &ModelConfig,
        years: usize,
        rng: &mut R,
    ) -> (Vec<Vec<ObservationRecord>>, Vec<Vec<PatchState>>) {
        let n = graph.num_nodes;
        let mut sim = crate::dynamics::MqemSimulator::new(
            graph.clone(),
            config.clone(),
            vec![PatchState::new(vec![1.5; config.dim_d]); n],
        );

        let mut observations = Vec::with_capacity(years);
        let mut true_states = Vec::with_capacity(years);

        for y in 0..years {
            // Step forward by 20 time increments per year
            for _ in 0..20 {
                sim.step(None, rng);
            }

            true_states.push(sim.states.clone());

            let mut obs_step = Vec::with_capacity(n);
            for v in 0..n {
                let x_v = sim.states[v].values[0];
                // Detection probability p_det = 0.8
                let detected = x_v > 0.3 && rng.gen_bool(0.8);
                obs_step.push(ObservationRecord {
                    node_id: v,
                    time_step: y,
                    value: if detected { 1.0 } else { 0.0 },
                });
            }
            observations.push(obs_step);
        }

        (observations, true_states)
    }
}
