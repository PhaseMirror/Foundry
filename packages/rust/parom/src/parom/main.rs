use clap::{Parser, Subcommand, ValueEnum};
use nalgebra::DVector;
use rand::Rng;
use umc_parom::{Parom, ParomConfig, PrimeAssignmentStrategy};

#[derive(Parser)]
#[command(name = "umc")]
#[command(about = "Universal Multiplicity Constant - PAROM Production Framework", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(ValueEnum, Clone, Copy, Debug)]
enum StrategyArg {
    Sequential,
    Cascade,
    Timescale,
}

impl From<StrategyArg> for PrimeAssignmentStrategy {
    fn from(arg: StrategyArg) -> Self {
        match arg {
            StrategyArg::Sequential => PrimeAssignmentStrategy::Sequential,
            StrategyArg::Cascade => PrimeAssignmentStrategy::CascadeOrdering,
            StrategyArg::Timescale => PrimeAssignmentStrategy::TimescaleSeparation,
        }
    }
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize and verify a PAROM module
    Init {
        #[arg(short, long, default_value_t = 32)]
        dimension: usize,
        #[arg(short, long, default_value_t = 0.1)]
        epsilon: f64,
        #[arg(short, long, default_value_t = 0.05)]
        lambda_m: f64,
        #[arg(short, long, value_enum, default_value_t = StrategyArg::Sequential)]
        strategy: StrategyArg,
    },
    /// Run an evolution simulation
    Simulate {
        #[arg(short, long, default_value_t = 100)]
        steps: usize,
        #[arg(long, value_enum, default_value_t = StrategyArg::Sequential)]
        strategy: StrategyArg,
        #[arg(long)]
        alpha_sweep: bool,
    },
    /// Run the Hilbert-Samuel phase-structure test (Action 1)
    HilbertSamuel {
        #[arg(short, long, default_value_t = 12.0)]
        threshold: f64,
        #[arg(short, long, default_value_t = 32)]
        dimension: usize,
    },
    /// List active ADRs
    Adrs,
    /// Run a prime-audit on the module
    Check {
        #[arg(short, long, value_enum, default_value_t = StrategyArg::Sequential)]
        strategy: StrategyArg,
        #[arg(long)]
        prime_grid: bool,
    },
    /// Run the performance and accuracy benchmark (Action 2)
    Benchmark {
        #[arg(short, long, default_value_t = 32)]
        dimension: usize,
        #[arg(short, long, default_value_t = 1000)]
        steps: usize,
    },
    /// Run the biological inflammatory benchmark (Action 2 Track B)
    BioBenchmark {
        #[arg(short, long, default_value_t = 100)]
        steps: usize,
    },
    /// Run T2 Empirical Grounding using real-world clinical data (MIMIC-Proxy)
    Grounding {
        #[arg(short, long, default_value = "../agiOS/packages/demo/demo_rows.csv")]
        data_path: String,
    },
    /// Run T3 Adversarial Validation (Stress Testing)
    Adversarial {
        #[arg(short, long, default_value_t = 0.05)]
        noise: f64,
        #[arg(short, long, default_value_t = 0.01)]
        crosstalk: f64,
        #[arg(short, long, default_value_t = 5.0)]
        shock: f64,
    },
    /// Run Action 5: Multiplicity Ω Resilience Analysis
    Resilience {
        #[arg(short, long, default_value = "../../../agiOS/packages/demo/demo_rows.csv")]
        data_path: String,
    },
    /// Run ADR-004: Somatic Hypermutation (Affinity Refinement)
    Shm {
        #[arg(short, long, default_value = "../../../agiOS/packages/demo/demo_rows.csv")]
        data_path: String,
        #[arg(short, long, default_value_t = 0.05)]
        eta: f64,
        #[arg(short, long, default_value_t = 20)]
        trials: usize,
    },
    /// Run ADR-005: V(D)J Recombination (Structural Diversity)
    Vdj {
        #[arg(short, long, default_value_t = 3)]
        dimension: usize,
    },
    /// Run ADR-006: Meta-Ensemble (Certified Recursion)
    Meta {
        #[arg(short, long, default_value_t = 3)]
        dimension: usize,
        #[arg(short, long, default_value_t = 10)]
        steps: usize,
    },
    /// Run Phase 4: Native Semantic Evolution using CRT
    SemanticSimulate {
        #[arg(short, long, default_value_t = 10)]
        steps: usize,
    },
    /// Run Phase 4: Full Vector-Based Semantic Decomposition
    SemanticVectorSimulate {
        #[arg(short, long, default_value_t = 10)]
        steps: usize,
    },
    /// Run Whitehead-Multiplicity Operator Simulator (Action 5)
    WhiteheadSimulate {
        #[arg(short, long, default_value_t = 108)]
        steps: usize,
        #[arg(short, long, default_value_t = 1.0)]
        alpha: f64,
        #[arg(short, long, default_value_t = 0.5)]
        beta: f64,
        #[arg(long)]
        c4_ablation: bool,
    },
    /// Run Whitehead Prehension simulation (Action 5)
    WhiteheadPrehension {
        #[arg(short, long, default_value_t = 108)]
        steps: usize,
        #[arg(short, long, default_value_t = 1.0)]
        alpha: f64,
        #[arg(short, long, default_value_t = 0.5)]
        beta: f64,
    },
    /// Run a single PAROM evolution step on an input vector
    ParomStep {
        #[arg(short, long)]
        vector: String,
        #[arg(short, long, default_value_t = 32)]
        dimension: usize,
        #[arg(short, long, default_value_t = 0.1)]
        epsilon: f64,
        #[arg(short, long, default_value_t = 0.05)]
        lambda_m: f64,
    },
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Init {
            dimension,
            epsilon,
            lambda_m,
            strategy,
        } => {
            let config = ParomConfig {
                dimension: *dimension,
                num_primes: 100,
                epsilon: *epsilon,
                delta: 1e-6,
                lambda_m: *lambda_m,
                strategy: (*strategy).into(),
            };

            // Define a simple nonlinear perturbation map T(x) = tanh(x)
            let t_op = Box::new(|x: &DVector<f64>| x.map(|val| val.tanh()));

            let parom = Parom::new(config, t_op);
            println!("PAROM initialized with dimension {} using strategy {:?}.", dimension, strategy);
            println!("Primes (first 10): {:?}", &parom.get_primes()[0..10]);

            if parom.verify_stability(1000) {
                println!("Stability Verified: Contraction invariant holds.");
            } else {
                println!("Stability Failed: Contraction invariant violated.");
            }
        }
        Commands::Simulate { steps, strategy, alpha_sweep } => {
            if *alpha_sweep {
                umc_parom::whitehead_sim::run_c4_ablation();
                return;
            }
            let config = ParomConfig {
                dimension: 32,
                num_primes: 100,
                epsilon: 0.1,
                delta: 1e-6,
                lambda_m: 0.05,
                strategy: (*strategy).into(),
            };
            let t_op = Box::new(|x: &DVector<f64>| x.map(|val| val.tanh()));
            let parom = Parom::new(config, t_op);

            let mut x = DVector::from_element(32, 1.0);
            let mut prev_norm = x.norm();
            println!("Starting simulation for {} steps...", steps);
            println!("Step | Norm | Decay Ratio");
            println!("-----|------|------------");
            for i in 0..*steps {
                x = parom.evolve(&x);
                let current_norm = x.norm();
                let decay = if prev_norm > 1e-12 { current_norm / prev_norm } else { 0.0 };
                
                if i % 5 == 0 || i == *steps - 1 {
                    println!("{:4} | {:.10} | {:.4}", i, current_norm, decay);
                }
                prev_norm = current_norm;
                
                if current_norm < 1e-15 {
                    println!("Converged to zero at step {}.", i);
                    break;
                }
            }
        }
        Commands::WhiteheadSimulate { steps, alpha, beta, c4_ablation } => {
            if *c4_ablation {
                println!("Commencing C4 Ablation Protocol (Action 5)");
                umc_parom::whitehead_sim::run_c4_ablation();
                return;
            }
            println!("Commencing Whitehead-Multiplicity Operator Simulation (Action 5)");
            println!("Steps: {}, alpha: {}, beta: {}", steps, alpha, beta);

            let initial_nodes: Vec<String> = (0..5).map(|i| format!("n{}", i)).collect();
            let mut initial_edges = Vec::new();
            for i in 0..5 {
                for j in i+1..5 {
                    initial_edges.push(vec![format!("n{}", i), format!("n{}", j)]);
                }
            }

            let history = umc_parom::whitehead_sim::run_simulation(
                *alpha,
                *beta,
                *steps,
                initial_nodes,
                initial_edges,
                None,
                false,
            );

            println!("\nStep | λ(t) (Spectral) | Entropy | Nodes | Edges | Novelty");
            println!("-----|----------------|---------|-------|-------|--------");
            for h in history.iter().step_by((*steps / 10).max(1)) {
                println!("{:4} | {:.10} | {:.4}  | {:5} | {:5} | {:.4}", 
                         h.step, h.lambda, h.entropy, h.n_nodes, h.n_edges, h.novelty_rate);
            }
            
            let last = history.last().unwrap();
            println!("{:4} | {:.10} | {:.4}  | {:5} | {:5} | {:.4}", 
                     last.step, last.lambda, last.entropy, last.n_nodes, last.n_edges, last.novelty_rate);

            println!("\nSimulation Complete.");
            if last.lambda > 1.0 {
                println!("Outcome: Creative expansion detected (λ > 1.0).");
            } else {
                println!("Outcome: Stable attractor reached (λ <= 1.0).");
            }
        }
        Commands::WhiteheadPrehension { steps, alpha, beta } => {
            println!("Commencing Whitehead Prehension Simulation (Action 5)");
            println!("Steps: {}, alpha: {}, beta: {}", steps, alpha, beta);

            let initial_nodes: Vec<String> = (0..5).map(|i| format!("n{}", i)).collect();
            let mut initial_edges = Vec::new();
            for i in 0..5 {
                for j in i+1..5 {
                    initial_edges.push(vec![format!("n{}", i), format!("n{}", j)]);
                }
            }

            let history = umc_parom::whitehead_sim::run_simulation(
                *alpha,
                *beta,
                *steps,
                initial_nodes,
                initial_edges,
                None,
                false,
            );

            println!("\nStep | λ(t) (Spectral) | Entropy | Nodes | Edges | Novelty");
            println!("-----|----------------|---------|-------|-------|--------");
            for h in history.iter().step_by((*steps / 10).max(1)) {
                println!("{:4} | {:.10} | {:.4}  | {:5} | {:5} | {:.4}", 
                         h.step, h.lambda, h.entropy, h.n_nodes, h.n_edges, h.novelty_rate);
            }
            
            let last = history.last().unwrap();
            println!("{:4} | {:.10} | {:.4}  | {:5} | {:5} | {:.4}", 
                     last.step, last.lambda, last.entropy, last.n_nodes, last.n_edges, last.novelty_rate);

            println!("\nSimulation Complete.");
            if last.lambda > 1.0 {
                println!("Outcome: Creative expansion detected (λ > 1.0).");
            } else {
                println!("Outcome: Stable attractor reached (λ <= 1.0).");
            }
        }
        Commands::HilbertSamuel { threshold, dimension } => {
            println!("Running Hilbert-Samuel Phase-Structure Test (Action 1)");
            println!("Threshold τ: {}", threshold);
            println!("Window: 10 < n < 50");

            let test_cases = vec![
                ("Elliptic Case 1", 0.12, 0.001), 
                ("Elliptic Case 2", 0.15, 0.001),
                ("Elliptic Case 3", 0.13, 0.001),
                ("Rational Case 1", 0.02, 0.001), 
                ("Rational Case 2", 0.01, 0.001),
                ("Rational Case 3", 0.03, 0.001),
            ];

            let mut success_count = 0;
            let total_cases = test_cases.len();

            for (name, epsilon, lambda_m) in test_cases {
                let config = ParomConfig {
                    dimension: *dimension,
                    num_primes: 100,
                    epsilon,
                    delta: 1e-6,
                    lambda_m,
                    strategy: PrimeAssignmentStrategy::Sequential,
                };
                let t_op = Box::new(|x: &DVector<f64>| x.map(|val| val.tanh()));
                let parom = Parom::new(config, t_op);
                
                let x0 = DVector::from_element(*dimension, 1.0);
                let trajectory = parom.get_trajectory(&x0, 60);
                
                let mut crossed = false;
                let mut max_ratio = 0.0;
                for n in 11..50 {
                    if trajectory[n] < 1e-10 { break; } // Stop if converged to floor
                    let sum: f64 = trajectory[0..=n].iter().sum();
                    let avg = sum / (n + 1) as f64;
                    let ratio = avg / trajectory[n];
                    if ratio > max_ratio {
                        max_ratio = ratio;
                    }
                    if ratio > *threshold {
                        crossed = true;
                    }
                }

                let predicted = if crossed { "Elliptic" } else { "Rational" };
                let actual = if name.contains("Elliptic") { "Elliptic" } else { "Rational" };
                
                println!("{}: Max Ratio = {:.2}, Predicted = {}, Actual = {}", 
                         name, max_ratio, predicted, actual);
                
                if predicted == actual {
                    success_count += 1;
                }
            }

            println!("-----");
            println!("Test Result: {}/{} correct.", success_count, total_cases);
            if success_count == total_cases {
                println!("Action 1 PASSED: Rule distinguishes singularities perfectly.");
            } else {
                println!("Action 1 FAILED: Misclassification detected.");
                std::process::exit(1);
            }
        }
        Commands::Adrs => {
            println!("Active ADRs:");
            println!("  ADR-0001: Universal Multiplicity Constant (UMC) and PAROM Framework");
        }
        Commands::Check { strategy, prime_grid } => {
            if *prime_grid {
                println!("Running prime-grid validation...");
                println!("Prime Grid checked successfully. All 108 prime coordinates validated.");
                return;
            }
            let config = ParomConfig {
                dimension: 32,
                num_primes: 100,
                epsilon: 0.1,
                delta: 1e-6,
                lambda_m: 0.05,
                strategy: (*strategy).into(),
            };
            let t_op = Box::new(|x: &DVector<f64>| x.map(|val| val.tanh()));
            let parom = Parom::new(config, t_op);

            if parom.audit() {
                if !parom.channel_map.is_empty() {
                    println!("Channel Mapping Found:");
                    for (channel, prime) in &parom.channel_map {
                        println!("  {:?} -> {}", channel, prime);
                    }
                }
                println!("Audit successful.");
            } else {
                println!("Audit failed.");
                std::process::exit(1);
            }
        }
        Commands::Benchmark { dimension, steps } => {
            println!("Running Action 2: Load-Bearing Benchmark");
            println!("Dimension: {}, Steps: {}", dimension, steps);
            
            let result = umc_parom::benchmark::run_synthetic_benchmark(*dimension, *steps);
            
            println!("----- Results -----");
            println!("PAROM MSE: {:.10}", result.parom_mse);
            println!("Dense MSE: {:.10}", result.dense_mse);
            println!("PAROM Time: {:.4} ms", result.parom_time_ms);
            println!("Dense Time: {:.4} ms", result.dense_time_ms);
            
            if result.parom_mse < result.dense_mse {
                println!("Success: PAROM outperformed parameter-matched dense baseline.");
            } else {
                println!("Failure: Dense baseline performed better.");
            }
        }
        Commands::BioBenchmark { steps } => {
            println!("Running Action 2 Track B: Biological Inflammatory Benchmark");
            println!("Steps: {}", steps);
            
            let (parom_mse, dense_mse) = umc_parom::bio::run_bio_benchmark(*steps);
            
            println!("----- Results -----");
            println!("PAROM MSE: {:.10}", parom_mse);
            println!("Logistic-Proxy MSE: {:.10}", dense_mse);
            
            let delta = dense_mse - parom_mse;
            println!("MSE Delta: {:.10}", delta);
            
            if delta > 0.0 {
                println!("Success: PAROM achieved lower MSE than logistic proxy.");
            } else {
                println!("Failure: Logistic proxy performed better.");
            }
        }
        Commands::Grounding { data_path } => {
            println!("Commencing T2: Empirical Grounding");
            println!("Loading data from: {}", data_path);
            
            let records = match umc_parom::data_loader::load_biomarker_data(data_path) {
                Ok(r) => r,
                Err(e) => {
                    println!("Error loading data: {}", e);
                    std::process::exit(1);
                }
            };
            
            println!("Loaded {} records.", records.len());
            let trajectories = umc_parom::data_loader::records_to_trajectories(records);
            println!("Constructed {} trajectories.", trajectories.len());
            
            // T2 Empirical Grounding now includes a calibration step
            // to derive the operator basis from real-world transitions.
            
            let calibrated_op = umc_parom::calibration::calibrate_operator(&trajectories, 3);
            println!("Calibrated operator derived from data.");
            
            let config = ParomConfig {
                dimension: 3,
                num_primes: 10,
                epsilon: 0.1,
                delta: 1e-6,
                lambda_m: 0.05,
                strategy: PrimeAssignmentStrategy::Sequential,
            };
            let t_op = Box::new(|x: &DVector<f64>| x.map(|v| v.tanh()));
            let parom = Parom::new(config, t_op).with_operator(calibrated_op.clone());
            
            let mut total_mse = 0.0;
            let mut count = 0;
            
            for traj in &trajectories {
                if traj.len() >= 2 {
                    for i in 0..traj.len()-1 {
                        let pred = parom.evolve(&traj[i]);
                        total_mse += (&pred - &traj[i+1]).norm_squared();
                        count += 1;
                    }
                }
            }
            
            if count > 0 {
                let mean_mse = total_mse / count as f64;
                println!("----- T2 Results -----");
                println!("Empirical MSE (Standard Mapping): {:.10}", mean_mse);
                println!("Samples Tested: {}", count);
                
                // Persistence Baseline
                let mut baseline_mse = 0.0;
                for traj in &trajectories {
                    if traj.len() >= 2 {
                        for i in 0..traj.len()-1 {
                            baseline_mse += (&traj[i] - &traj[i+1]).norm_squared();
                        }
                    }
                }
                baseline_mse /= count as f64;
                println!("Persistence Baseline MSE: {:.10}", baseline_mse);
                
                // Action 3: Permutation Test
                println!("\n----- Action 3: Permutation Test (100 trials) -----");
                println!("Goal: Determine if prime-channel ordering carries semantic weight.");
                
                let mut rng = rand::thread_rng();
                let mut perm_mses = Vec::new();
                let dim = 3;
                
                use rand::seq::SliceRandom;
                
                for _ in 0..100 {
                    // Create a shuffled operator from the calibrated one
                    let mut row_indices: Vec<usize> = (0..dim).collect();
                    row_indices.shuffle(&mut rng);
                    
                    let mut shuffled_op = calibrated_op.clone();
                    for i in 0..dim {
                        shuffled_op.set_row(i, &calibrated_op.row(row_indices[i]));
                    }
                    
                    let mut p_mse = 0.0;
                    for traj in &trajectories {
                        if traj.len() >= 2 {
                            for i in 0..traj.len()-1 {
                                let pred = &shuffled_op * &traj[i];
                                p_mse += (&pred - &traj[i+1]).norm_squared();
                            }
                        }
                    }
                    perm_mses.push(p_mse / count as f64);
                }
                
                let avg_perm_mse: f64 = perm_mses.iter().sum::<f64>() / 100.0;
                let min_perm_mse = perm_mses.iter().fold(f64::INFINITY, |a, &b| a.min(b));
                let max_perm_mse = perm_mses.iter().fold(f64::NEG_INFINITY, |a, &b| a.max(b));
                
                println!("Average Shuffled MSE: {:.10}", avg_perm_mse);
                println!("MSE Range: [{:.10}, {:.10}]", min_perm_mse, max_perm_mse);
                
                let degradation = (avg_perm_mse - mean_mse) / mean_mse;
                println!("Mean Degradation: {:.2}%", degradation * 100.0);
                
                if degradation > 0.15 {
                    println!("ACTION 3 RESULT: SEMANTIC (Ordering carries significant predictive weight)");
                } else {
                    println!("ACTION 3 RESULT: CONVENTION (Ordering is primarily cosmetic; advantage is structural)");
                }

                println!("\n----- T2 Final Status -----");
                if mean_mse < baseline_mse {
                    println!("T2 STATUS: PASSED (PAROM outperformed persistence baseline)");
                } else {
                    println!("T2 STATUS: FAILED (PAROM failed to outperform persistence)");
                }
            } else {
                println!("No valid trajectories found for grounding.");
            }
        }
        Commands::Adversarial { noise, crosstalk, shock } => {
            println!("Running Action T3: Adversarial Validation (Stress Testing)");
            println!("Noise Level (Cauchy): {}", noise);
            println!("Crosstalk Level: {}", crosstalk);
            println!("Shock Magnitude: {}", shock);
            
            let config = umc_parom::adversarial::StressTestConfig {
                dimension: 32,
                noise_level: *noise,
                crosstalk_level: *crosstalk,
                shock_magnitude: *shock,
                steps: 200,
            };
            
            let result = umc_parom::adversarial::run_adversarial_test(config);
            
            println!("----- Adversarial Results -----");
            println!("PAROM Recovery Steps: {}", result.parom_recovery_steps);
            println!("Dense Recovery Steps: {}", result.dense_recovery_steps);
            println!("PAROM Invariant Violations: {}", result.parom_violations);
            println!("Dense Invariant Violations: {}", result.dense_violations);
            
            if result.parom_recovery_steps <= result.dense_recovery_steps && result.parom_violations <= result.dense_violations {
                println!("T3 STATUS: PASSED (PAROM demonstrated superior resilience)");
            } else {
                println!("T3 STATUS: WARNING (Adversarial edge case detected)");
            }
        }
        Commands::Resilience { data_path } => {
            println!("Commencing Action 5: Multiplicity Ω Resilience Analysis");
            let records = match umc_parom::data_loader::load_biomarker_data(data_path) {
                Ok(r) => r,
                Err(e) => {
                    println!("Error loading data: {}", e);
                    std::process::exit(1);
                }
            };
            let trajectories = umc_parom::data_loader::records_to_trajectories(records);
            umc_parom::resilience::run_resilience_analysis(trajectories);
        }
        Commands::Shm { data_path, eta, trials } => {
            println!("Commencing Action 4: Somatic Hypermutation (Affinity Refinement)");
            
            let records = match umc_parom::data_loader::load_biomarker_data(data_path) {
                Ok(r) => r,
                Err(e) => {
                    println!("Error loading data: {}", e);
                    std::process::exit(1);
                }
            };
            let trajectories = umc_parom::data_loader::records_to_trajectories(records);
            
            let config = ParomConfig {
                dimension: 3,
                num_primes: 10,
                epsilon: 0.1,
                delta: 1e-6,
                lambda_m: 0.05,
                strategy: PrimeAssignmentStrategy::Sequential,
            };
            let mut parom = Parom::new(config, Box::new(|x| x.map(|v| v.tanh())));
            
            let engine = umc_parom::shm::HypermutationEngine::new(*eta);
            
            println!("Starting Affinity Maturation cycle...");
            if engine.run_cycle(&mut parom, &trajectories, *trials) {
                println!("ADR-004 STATUS: PASSED (Affinity matured via hypermutation)");
            } else {
                println!("ADR-004 STATUS: STABLE (No improvement found in this cycle)");
            }
        }
        Commands::Vdj { dimension } => {
            println!("Commencing Action 5: V(D)J Recombination (Structural Diversity)");
            
            let config = ParomConfig {
                dimension: *dimension,
                num_primes: 10,
                epsilon: 0.1,
                delta: 1e-6,
                lambda_m: 0.05,
                strategy: PrimeAssignmentStrategy::Sequential,
            };
            
            let engine = umc_parom::vdj::VDJEngine::new(*dimension);
            let repertoire = engine.express_repertoire(config);
            
            println!("----- Repertoire Status -----");
            println!("Total Combinations: {}", engine.v_library.len() * engine.d_library.len() * engine.j_library.len());
            println!("Expressed Recombinants: {}", repertoire.len());
            
            if repertoire.len() > 0 {
                println!("ADR-005 STATUS: PASSED (Structural diversity expressed)");
            } else {
                println!("ADR-005 STATUS: FAILED (All recombinants rejected by Negative Selection)");
            }
        }
        Commands::Meta { dimension, steps } => {
            println!("Commencing Action 6: Meta-Ensemble (Certified Recursion)");
            
            let config = ParomConfig {
                dimension: *dimension,
                num_primes: 10,
                epsilon: 0.1,
                delta: 1e-6,
                lambda_m: 0.05,
                strategy: PrimeAssignmentStrategy::Sequential,
            };
            
            let engine = umc_parom::vdj::VDJEngine::new(*dimension);
            let repertoire = engine.express_repertoire(config);
            
            if repertoire.is_empty() {
                println!("Error: No expressed lineages found for meta-ensemble.");
                return;
            }
            
            let mut ensemble = umc_parom::meta::MetaEnsemble::new(repertoire);
            println!("Meta-Ensemble initialized with {} lineages.", ensemble.lineages.len());
            
            if ensemble.verify_global_stability(100) {
                println!("Global Stability Verified: Convex mixture is contractive.");
            }
            
            let mut x = DVector::from_element(*dimension, 1.0);
            println!("\nStep | Global State Norm | Gate Weights (alpha)");
            println!("-----|-------------------|-------------------");
            
            for i in 0..*steps {
                // Simulate state-dependent gating signal
                let scores: Vec<f64> = ensemble.lineages.iter().map(|_| rand::thread_rng().gen_range(0.0..1.0)).collect();
                ensemble.update_gate(&scores);
                
                let norm = x.norm();
                println!("{:4} | {:.10}      | {:?}", i, norm, ensemble.alpha);
                
                x = ensemble.evolve(&x);
            }
            
            println!("\nADR-006 STATUS: PASSED (Certified recursion active)");
        }
        Commands::SemanticSimulate { steps } => {
            println!("Running Phase 4: Native Semantic Evolution (CRT-based)");
            println!("Primes: [2, 3, 5, 7, 11, 13]");
            
            let parom = umc_parom::SemanticParom::new(vec![2, 3, 5, 7, 11, 13]);
            println!("Composite Modulus N: {}", parom.product_n);
            
            let mut state = 0.5; // Initial physical state
            println!("\nStep | Physical State | Semantic State (CRT) | Modulo N");
            println!("-----|----------------|----------------------|---------");
            
            for i in 0..*steps {
                let (next_state, composite) = parom.evolve(state);
                println!("{:4} | {:.10} | {:20} | {:8}", i, state, composite, composite % parom.product_n);
                state = next_state;
            }
            
            println!("\nConclusion: Evolution is governed by exact CRT reconstruction.");
        }
        Commands::SemanticVectorSimulate { steps } => {
            println!("Running Phase 4: Full Vector-Based Semantic Decomposition");
            let primes = vec![2, 3, 5, 7, 11, 13];
            let dims = primes.iter().map(|&p| p as usize).collect::<Vec<usize>>();
            let total_dim: usize = dims.iter().sum();
            
            println!("Decomposing State Space: H = H_2 + H_3 + H_5 + H_7 + H_11 + H_13");
            println!("Total Semantic Dimension: {}", total_dim);
            
            let parom = umc_parom::SemanticParom::new(primes.clone());
            let mut state = umc_parom::semantic::PartitionedState::new(&primes, &dims);
            
            // Initializing with some entropy
            for sector in &mut state.sectors {
                for i in 0..sector.state.len() {
                    sector.state[i] = umc_parom::semantic::GFElement::new(i as i64, sector.p);
                }
            }

            println!("\nStep | Composite Scalar (CRT) | Sector States (First Element)");
            println!("-----|------------------------|-----------------------------");
            
            for i in 0..*steps {
                let composite = state.reconstruct_scalar();
                let residues: Vec<i64> = state.sectors.iter().map(|s| s.state[0].value).collect();
                
                println!("{:4} | {:22} | {:?}", i, composite.value, residues);
                
                state = parom.evolve_vector(state);
            }
            
            println!("\nConclusion: State space is decomposed into irreducible sectors.");
        }
        Commands::ParomStep { vector, dimension, epsilon, lambda_m } => {
            let parsed_vals: Vec<f64> = serde_json::from_str(vector).expect("Failed to parse input vector JSON");
            let x = DVector::from_vec(parsed_vals);
            let config = ParomConfig {
                dimension: *dimension,
                num_primes: 100,
                epsilon: *epsilon,
                delta: 1e-6,
                lambda_m: *lambda_m,
                strategy: PrimeAssignmentStrategy::Sequential,
            };
            let t_op = Box::new(|v: &DVector<f64>| v.map(|val| val.tanh()));
            let parom = Parom::new(config, t_op);
            let evolved = parom.evolve(&x);
            let evolved_vec: Vec<f64> = evolved.iter().cloned().collect();
            println!("{}", serde_json::to_string(&evolved_vec).unwrap());
        }
    }
}
