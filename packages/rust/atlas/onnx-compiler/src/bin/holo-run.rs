//! Hologram Model Runner
//!
//! Loads and executes compiled .holo models
//!
//! # Usage
//!
//! ```bash
//! # Show model information
//! holo-run info model.holo
//!
//! # Run inference with JSON input
//! holo-run run model.holo --input input.json --output output.json
//!
//! # Run in interactive mode
//! holo-run run model.holo --interactive
//!
//! # Run inference with generated test data
//! holo-run test model.holo
//!
//! # Show ONNX operators from an ONNX file
//! holo-run show-ops model.onnx
//! ```

use clap::{Parser, Subcommand, ValueEnum};
use hologram_onnx_compiler::compiler::{RuntimeExecutor, SerializableGraph};
use hologram_onnx_compiler::hrm::graph::ir::GraphStatistics;
use hologram_onnx_compiler::hrm::graph::HologramGraph;
use hologram_onnx_compiler::hrm::{ExtendedAddress, PerfectHashTable};
use hologram_onnx_compiler::proto::ModelProto;
use prost::Message as ProstMessage;
use std::collections::HashMap;
use std::fs;
use std::io::Read;
use std::path::PathBuf;

/// Hologram Model Runner - Execute compiled .holo models
#[derive(Parser)]
#[command(name = "holo-run")]
#[command(about = "Run compiled Hologram models", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Show model information
    Info {
        /// Path to compiled .holo model
        model: PathBuf,
    },

    /// Run inference
    Run {
        /// Path to compiled .holo model
        model: PathBuf,

        /// Path to input JSON file
        #[arg(short, long)]
        input: Option<PathBuf>,

        /// Path to output JSON file
        #[arg(short, long)]
        output: Option<PathBuf>,

        /// Enter interactive mode (REPL)
        #[arg(long)]
        interactive: bool,
    },

    /// Test model with generated data
    Test {
        /// Path to compiled .holo model
        model: PathBuf,

        /// Number of test runs
        #[arg(short, long, default_value = "10")]
        iterations: usize,
    },

    /// Show ONNX operators from an ONNX file
    ShowOps {
        /// Path to ONNX model file
        model: PathBuf,

        /// Show detailed attributes for each operator
        #[arg(short, long)]
        verbose: bool,

        /// Show only operator type statistics
        #[arg(short, long)]
        stats_only: bool,

        /// Filter by operator type (e.g., "MatMul", "Conv")
        #[arg(short = 't', long)]
        filter_type: Option<String>,

        /// Output format: text, json, or csv
        #[arg(short = 'f', long, default_value = "text")]
        format: OutputFormat,
    },
}

#[derive(Debug, Clone, ValueEnum)]
enum OutputFormat {
    Text,
    Json,
    Csv,
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Info { model } => {
            if let Err(e) = show_info(&model) {
                eprintln!("Error: {}", e);
                std::process::exit(1);
            }
        }
        Commands::Run { model, input, output, interactive } => {
            if interactive {
                if let Err(e) = interactive_mode(&model) {
                    eprintln!("Error: {}", e);
                    std::process::exit(1);
                }
            } else {
                if let Err(e) = run_inference(&model, input.as_deref(), output.as_deref()) {
                    eprintln!("Error: {}", e);
                    std::process::exit(1);
                }
            }
        }
        Commands::Test { model, iterations } => {
            if let Err(e) = test_model(&model, iterations) {
                eprintln!("Error: {}", e);
                std::process::exit(1);
            }
        }
        Commands::ShowOps {
            model,
            verbose,
            stats_only,
            filter_type,
            format,
        } => {
            if let Err(e) = show_ops(&model, verbose, stats_only, filter_type, format) {
                eprintln!("Error: {}", e);
                std::process::exit(1);
            }
        }
    }
}

/// Show model information
fn show_info(model_path: &PathBuf) -> Result<(), Box<dyn std::error::Error>> {
    println!("Loading model: {}", model_path.display());

    let model = load_model(model_path)?;

    println!("\n┌─────────────────────────────────────────────┐");
    println!("│ Model Information                            │");
    println!("└─────────────────────────────────────────────┘\n");

    println!("File size: {:.2} MB", model.total_bytes as f64 / 1_000_000.0);
    println!("Format version: {}", model.version);
    println!();
    println!("Sections:");
    println!(
        "  Manifest:      {:.2} MB ({} bytes)",
        model.manifest_size as f64 / 1_000_000.0,
        model.manifest_size
    );
    println!(
        "  Address space: {:.2} MB ({} bytes)",
        model.address_space_size as f64 / 1_000_000.0,
        model.address_space_size
    );
    println!(
        "  Hash tables:   {:.2} MB ({} bytes)",
        model.hash_tables_size as f64 / 1_000_000.0,
        model.hash_tables_size
    );
    println!(
        "  Metadata:      {:.2} MB ({} bytes)",
        model.metadata_size as f64 / 1_000_000.0,
        model.metadata_size
    );
    if model.version >= 2 && model.graph_size > 0 {
        println!(
            "  Graph:         {:.2} MB ({} bytes)",
            model.graph_size as f64 / 1_000_000.0,
            model.graph_size
        );
    }
    println!();

    // Parse manifest
    if let Ok(manifest) = serde_json::from_slice::<serde_json::Value>(&model.manifest_data) {
        if let Some(op_stats) = manifest.get("operation_stats").and_then(|v| v.as_array()) {
            println!("Operations: {}", op_stats.len());
            println!();
            println!("Operation breakdown:");
            for (i, op) in op_stats.iter().enumerate() {
                let op_type = op.get("op_type").and_then(|v| v.as_str()).unwrap_or("Unknown");
                let input_shapes = op
                    .get("input_shapes")
                    .and_then(|v| v.as_array())
                    .map(|arr| arr.iter().map(|s| format!("{:?}", s)).collect::<Vec<_>>().join(", "))
                    .unwrap_or_default();
                let output_shapes = op
                    .get("output_shapes")
                    .and_then(|v| v.as_array())
                    .map(|arr| arr.iter().map(|s| format!("{:?}", s)).collect::<Vec<_>>().join(", "))
                    .unwrap_or_default();

                println!("  {}: {} ({}) → ({})", i, op_type, input_shapes, output_shapes);
            }
        }

        if let Some(patterns) = manifest.get("patterns_per_operation").and_then(|v| v.as_array()) {
            let total: i64 = patterns.iter().filter_map(|v| v.as_i64()).sum();
            println!();
            println!("Total pre-computed patterns: {}", total);
        }
    }

    Ok(())
}

/// Run inference
fn run_inference(
    model_path: &PathBuf,
    input_path: Option<&std::path::Path>,
    output_path: Option<&std::path::Path>,
) -> Result<(), Box<dyn std::error::Error>> {
    println!("Loading model: {}", model_path.display());
    let model = load_model(model_path)?;

    // Load or generate input
    let input_data: Vec<f32> = if let Some(input_path) = input_path {
        println!("Loading input: {}", input_path.display());
        let input_json = fs::read_to_string(input_path)?;
        serde_json::from_str(&input_json)?
    } else {
        println!("Generating test input...");
        generate_test_input(256)
    };

    println!("Running inference...");
    let output = execute_model(&model, &input_data)?;

    // Save or display output
    if let Some(output_path) = output_path {
        println!("Saving output: {}", output_path.display());
        let output_json = serde_json::to_string_pretty(&output)?;
        fs::write(output_path, output_json)?;
    } else {
        println!("\nOutput ({} values):", output.len());
        println!("{:?}", &output[..output.len().min(10)]);
        if output.len() > 10 {
            println!("... ({} more values)", output.len() - 10);
        }
    }

    println!("\n✓ Inference complete!");

    Ok(())
}

/// Test model with multiple iterations
fn test_model(model_path: &PathBuf, iterations: usize) -> Result<(), Box<dyn std::error::Error>> {
    println!("Loading model: {}", model_path.display());
    let model = load_model(model_path)?;

    println!("Running {} test iterations...\n", iterations);

    let mut total_time = std::time::Duration::ZERO;

    for i in 0..iterations {
        let input = generate_test_input(256);

        let start = std::time::Instant::now();
        let _output = execute_model(&model, &input)?;
        let elapsed = start.elapsed();

        total_time += elapsed;

        println!("Iteration {}: {:?}", i + 1, elapsed);
    }

    let avg_time = total_time / iterations as u32;
    println!("\n┌─────────────────────────────────────────────┐");
    println!("│ Performance Summary                          │");
    println!("└─────────────────────────────────────────────┘");
    println!();
    println!("Total time:   {:?}", total_time);
    println!("Average time: {:?}", avg_time);
    println!("Throughput:   {:.2} inferences/sec", 1.0 / avg_time.as_secs_f64());

    Ok(())
}

/// Interactive inference mode - REPL for testing the model
fn interactive_mode(model_path: &PathBuf) -> Result<(), Box<dyn std::error::Error>> {
    use std::io::{self, BufRead, Write};

    println!("┌─────────────────────────────────────────────┐");
    println!("│ Hologram Interactive Inference Mode         │");
    println!("└─────────────────────────────────────────────┘");
    println!();
    println!("Loading model: {}", model_path.display());
    let model = load_model(model_path)?;
    println!("✓ Model loaded (version {})", model.version);
    println!();
    println!("Commands:");
    println!("  - Enter comma-separated numbers for custom input");
    println!("  - 'random <size>' - Generate random input of given size");
    println!("  - 'test <size>' - Use test pattern of given size");
    println!("  - 'quit' or 'exit' - Exit interactive mode");
    println!();

    let stdin = io::stdin();
    let mut stdout = io::stdout();
    let reader = stdin.lock();

    // Show initial prompt
    print!("> ");
    stdout.flush()?;

    for line in reader.lines() {
        let line = line?;
        let trimmed = line.trim();

        if trimmed.is_empty() {
            print!("> ");
            stdout.flush()?;
            continue;
        }

        if trimmed == "quit" || trimmed == "exit" {
            println!("Goodbye!");
            break;
        }

        // Parse command
        let input_data = if let Some(size_str) = trimmed.strip_prefix("random ") {
            // Generate random input
            let size: usize = size_str.parse().unwrap_or(256);
            println!("Generating random input with {} values...", size);
            use std::hash::{Hash, Hasher};
            let mut hasher = ahash::AHasher::default();
            std::time::SystemTime::now().hash(&mut hasher);
            let seed = hasher.finish();
            (0..size).map(|i| ((seed.wrapping_add(i as u64) % 1000) as f32 / 1000.0) * 2.0 - 1.0).collect()
        } else if let Some(size_str) = trimmed.strip_prefix("test ") {
            // Generate test pattern
            let size: usize = size_str.parse().unwrap_or(256);
            println!("Generating test pattern with {} values...", size);
            generate_test_input(size)
        } else {
            // Parse comma-separated input
            let parts: Result<Vec<f32>, _> = trimmed
                .split(',')
                .map(|s| s.trim().parse::<f32>())
                .collect();

            match parts {
                Ok(values) if !values.is_empty() => {
                    println!("Using custom input with {} values", values.len());
                    values
                }
                _ => {
                    eprintln!("Invalid input. Examples:");
                    eprintln!("  1.0, 2.0, 3.0");
                    eprintln!("  random 256");
                    eprintln!("  test 128");
                    print!("> ");
                    stdout.flush()?;
                    continue;
                }
            }
        };

        // Run inference
        print!("Running inference... ");
        stdout.flush()?;

        let start = std::time::Instant::now();
        match execute_model(&model, &input_data) {
            Ok(output) => {
                let elapsed = start.elapsed();
                println!("✓ Done in {:?}", elapsed);
                println!();
                println!("Output ({} values):", output.len());
                if output.len() <= 20 {
                    for (i, val) in output.iter().enumerate() {
                        println!("  [{}] {}", i, val);
                    }
                } else {
                    for (i, val) in output.iter().take(10).enumerate() {
                        println!("  [{}] {}", i, val);
                    }
                    println!("  ... ({} more values)", output.len() - 20);
                    for (i, val) in output.iter().skip(output.len() - 10).enumerate() {
                        println!("  [{}] {}", output.len() - 10 + i, val);
                    }
                }
            }
            Err(e) => {
                println!("✗ Error");
                eprintln!("Inference failed: {}", e);
            }
        }

        println!();
        print!("> ");
        stdout.flush()?;
    }

    Ok(())
}

/// Loaded model structure
struct HoloModel {
    version: u32,
    manifest_data: Vec<u8>,
    address_space_data: Vec<u8>,
    hash_tables_data: Vec<u8>,
    #[allow(dead_code)]
    metadata_data: Vec<u8>,
    graph_data: Vec<u8>,
    manifest_size: usize,
    address_space_size: usize,
    hash_tables_size: usize,
    metadata_size: usize,
    graph_size: usize,
    total_bytes: usize,
}

/// Load .holo model from disk
fn load_model(path: &PathBuf) -> Result<HoloModel, Box<dyn std::error::Error>> {
    let mut file = fs::File::open(path)?;

    // Read entire file
    let mut data = Vec::new();
    file.read_to_end(&mut data)?;

    // Check magic
    if &data[0..4] != b"HOLO" {
        return Err("Invalid .holo file: bad magic".into());
    }

    // Read version
    let version = u32::from_le_bytes([data[4], data[5], data[6], data[7]]);

    // Version 2 format (88 byte header, 5 sections)
    if version >= 2 {
        if data.len() < 88 {
            return Err("Invalid .holo file: too small for v2".into());
        }

        // Read section offsets (8 bytes each)
        let manifest_offset = u64::from_le_bytes(data[8..16].try_into()?) as usize;
        let address_space_offset = u64::from_le_bytes(data[16..24].try_into()?) as usize;
        let hash_tables_offset = u64::from_le_bytes(data[24..32].try_into()?) as usize;
        let metadata_offset = u64::from_le_bytes(data[32..40].try_into()?) as usize;
        let graph_offset = u64::from_le_bytes(data[40..48].try_into()?) as usize;

        // Read section sizes (8 bytes each)
        let manifest_size = u64::from_le_bytes(data[48..56].try_into()?) as usize;
        let address_space_size = u64::from_le_bytes(data[56..64].try_into()?) as usize;
        let hash_tables_size = u64::from_le_bytes(data[64..72].try_into()?) as usize;
        let metadata_size = u64::from_le_bytes(data[72..80].try_into()?) as usize;
        let graph_size = u64::from_le_bytes(data[80..88].try_into()?) as usize;

        // Extract sections
        let manifest_data = data[manifest_offset..manifest_offset + manifest_size].to_vec();
        let address_space_data = data[address_space_offset..address_space_offset + address_space_size].to_vec();
        let hash_tables_data = data[hash_tables_offset..hash_tables_offset + hash_tables_size].to_vec();
        let metadata_data = data[metadata_offset..metadata_offset + metadata_size].to_vec();
        let graph_data = data[graph_offset..graph_offset + graph_size].to_vec();

        Ok(HoloModel {
            version,
            manifest_data,
            address_space_data,
            hash_tables_data,
            metadata_data,
            graph_data,
            manifest_size,
            address_space_size,
            hash_tables_size,
            metadata_size,
            graph_size,
            total_bytes: data.len(),
        })
    } else {
        // Version 1 format (72 byte header, 4 sections)
        if data.len() < 72 {
            return Err("Invalid .holo file: too small".into());
        }

        // Read section offsets (8 bytes each)
        let manifest_offset = u64::from_le_bytes(data[8..16].try_into()?) as usize;
        let address_space_offset = u64::from_le_bytes(data[16..24].try_into()?) as usize;
        let hash_tables_offset = u64::from_le_bytes(data[24..32].try_into()?) as usize;
        let metadata_offset = u64::from_le_bytes(data[32..40].try_into()?) as usize;

        // Read section sizes (8 bytes each)
        let manifest_size = u64::from_le_bytes(data[40..48].try_into()?) as usize;
        let address_space_size = u64::from_le_bytes(data[48..56].try_into()?) as usize;
        let hash_tables_size = u64::from_le_bytes(data[56..64].try_into()?) as usize;
        let metadata_size = u64::from_le_bytes(data[64..72].try_into()?) as usize;

        // Extract sections
        let manifest_data = data[manifest_offset..manifest_offset + manifest_size].to_vec();
        let address_space_data = data[address_space_offset..address_space_offset + address_space_size].to_vec();
        let hash_tables_data = data[hash_tables_offset..hash_tables_offset + hash_tables_size].to_vec();
        let metadata_data = data[metadata_offset..metadata_offset + metadata_size].to_vec();

        Ok(HoloModel {
            version,
            manifest_data,
            address_space_data,
            hash_tables_data,
            metadata_data,
            graph_data: vec![], // No graph in v1
            manifest_size,
            address_space_size,
            hash_tables_size,
            metadata_size,
            graph_size: 0,
            total_bytes: data.len(),
        })
    }
}

/// Execute model on input data
fn execute_model(model: &HoloModel, input: &[f32]) -> Result<Vec<f32>, Box<dyn std::error::Error>> {
    use std::hash::{Hash, Hasher};

    // Parse hash tables from JSON (PerfectHashTable has custom deserialization)
    let perfect_hash_tables: Vec<PerfectHashTable> = serde_json::from_slice(&model.hash_tables_data)?;

    // Convert to HashMap for lookup
    let hash_tables: Vec<HashMap<u64, ExtendedAddress>> = perfect_hash_tables
        .into_iter()
        .map(|pht| pht.entries.into_iter().collect())
        .collect();

    if hash_tables.is_empty() {
        return Err("No hash tables in model".into());
    }

    // Hash the input pattern using ahash (same as compilation)
    let mut hasher = ahash::AHasher::default();
    for &val in input {
        val.to_bits().hash(&mut hasher);
    }
    let input_hash = hasher.finish();

    // Fast path: Try hash table lookup (O(1))
    let first_table = &hash_tables[0];
    if let Some(address) = first_table.get(&input_hash) {
        // Calculate byte offset from ExtendedAddress
        let offset = calculate_address_offset(address);

        // Read f32 values from address space
        let start = offset * 4; // f32 = 4 bytes
        let end = (start + (input.len() * 4)).min(model.address_space_data.len());

        let mut result = Vec::new();
        for chunk in model.address_space_data[start..end].chunks_exact(4) {
            let bytes: [u8; 4] = chunk.try_into()?;
            result.push(f32::from_le_bytes(bytes));
        }

        return Ok(result);
    }

    // Slow path: Fall back to runtime graph execution
    // Only available in v2+ models with graph data
    if model.version >= 2 && !model.graph_data.is_empty() {
        println!("⚠ Pattern not found in cache (hash: {}), executing graph at runtime...", input_hash);

        // Deserialize the operator graph
        let graph: SerializableGraph = serde_json::from_slice(&model.graph_data)?;

        // Create runtime executor
        let mut executor = RuntimeExecutor::new(graph)?;

        // Execute the graph
        let result = executor.execute(input)?;

        println!("✓ Runtime execution succeeded ({} values computed)", result.len());

        return Ok(result);
    }

    // No fallback available
    Err(format!(
        "Input pattern (hash: {}) not found in pre-computed results and no runtime graph available (v{})",
        input_hash, model.version
    ).into())
}

/// Calculate byte offset from ExtendedAddress
fn calculate_address_offset(address: &ExtendedAddress) -> usize {
    // Address space layout: class → page → byte → sub_index
    // Total size per class: 48 pages × 256 bytes = 12,288 bytes
    const PAGES_PER_CLASS: usize = 48;
    const BYTES_PER_PAGE: usize = 256;

    let class_offset = address.class as usize * PAGES_PER_CLASS * BYTES_PER_PAGE;
    let page_offset = address.page as usize * BYTES_PER_PAGE;
    let byte_offset = address.byte as usize;

    class_offset + page_offset + byte_offset + address.sub_index as usize
}

/// Hash input pattern for lookup
#[allow(dead_code)]
fn hash_input(input: &[f32]) -> u64 {
    use std::hash::{Hash, Hasher};

    let mut hasher = std::collections::hash_map::DefaultHasher::new();
    for &val in input {
        val.to_bits().hash(&mut hasher);
    }
    hasher.finish()
}

/// Generate test input data
fn generate_test_input(size: usize) -> Vec<f32> {
    (0..size).map(|i| (i as f32 * 0.01) % 2.0 - 1.0).collect()
}

/// Show ONNX operators from an ONNX file
fn show_ops(
    model_path: &PathBuf,
    verbose: bool,
    stats_only: bool,
    filter_type: Option<String>,
    format: OutputFormat,
) -> Result<(), Box<dyn std::error::Error>> {
    // Load ONNX file
    let onnx_bytes = std::fs::read(model_path)?;

    // Parse ONNX protobuf
    let model = ModelProto::decode(&onnx_bytes[..])?;
    let onnx_graph = model.graph.ok_or("ONNX model has no graph")?;

    // Build HologramGraph
    let graph = HologramGraph::from_onnx(&onnx_graph)?;

    // Get statistics
    let stats = graph.statistics();

    if stats_only {
        // Show only statistics
        show_op_statistics(&stats);
        return Ok(());
    }

    match format {
        OutputFormat::Text => show_ops_text(&graph, &stats, model_path, verbose, &filter_type),
        OutputFormat::Json => show_ops_json(&graph, &stats, model_path, verbose, &filter_type)?,
        OutputFormat::Csv => show_ops_csv(&graph, model_path, &filter_type)?,
    }

    Ok(())
}

fn show_op_statistics(stats: &GraphStatistics) {
    println!("\n┌─────────────────────────────────────────────┐");
    println!("│ ONNX Model Statistics                        │");
    println!("└─────────────────────────────────────────────┘\n");

    println!("Total operators: {}", stats.total_nodes);
    println!("Total edges: {}", stats.total_edges);
    println!("Graph inputs: {}", stats.num_inputs);
    println!("Graph outputs: {}", stats.num_outputs);
    println!("Initializers: {}", stats.num_initializers);
    println!();
    println!("Operator types:");

    let mut sorted_ops: Vec<_> = stats.op_type_counts.iter().collect();
    sorted_ops.sort_by(|a, b| b.1.cmp(a.1));

    for (op_type, count) in sorted_ops {
        println!("  {:20} × {}", op_type, count);
    }
}

fn show_ops_text(
    graph: &HologramGraph,
    stats: &GraphStatistics,
    model_path: &PathBuf,
    verbose: bool,
    filter_type: &Option<String>,
) {
    println!("\n┌─────────────────────────────────────────────┐");
    println!("│ ONNX Operators                               │");
    println!("└─────────────────────────────────────────────┘\n");

    println!("Model: {}", model_path.display());
    println!("Total operators: {}\n", stats.total_nodes);

    // Iterate through nodes in topological order
    let topo_order = match graph.topological_sort() {
        Ok(order) => order,
        Err(e) => {
            eprintln!("Warning: Could not topologically sort graph: {}", e);
            graph.petgraph().node_indices().collect()
        }
    };

    for (idx, node_id) in topo_order.iter().enumerate() {
        if let Some(node) = graph.node(*node_id) {
            // Apply filter if specified
            if let Some(ref filter) = filter_type {
                if !node.op_type.contains(filter.as_str()) {
                    continue;
                }
            }

            println!("─────────────────────────────────────────────");
            println!("Operator #{}: {}", idx + 1, node.op_type);

            if !node.name.is_empty() {
                println!("  Name: {}", node.name);
            }

            if !node.domain.is_empty() {
                println!("  Domain: {}", node.domain);
            }

            // Show inputs
            if !node.input_names.is_empty() {
                println!("  Inputs ({}):", node.input_names.len());
                for (i, input) in node.input_names.iter().enumerate() {
                    let is_initializer = graph.initializers_map().contains_key(input);
                    let marker = if is_initializer { " (initializer)" } else { "" };
                    println!("    [{}] {}{}", i, input, marker);
                }
            }

            // Show outputs
            if !node.output_names.is_empty() {
                println!("  Outputs ({}):", node.output_names.len());
                for (i, output) in node.output_names.iter().enumerate() {
                    // Check if shape is known
                    let shape_info = if let Some(shape) = graph.shapes.get(&(*node_id, i as u8)) {
                        format!(" shape={:?}", shape)
                    } else {
                        String::new()
                    };
                    println!("    [{}] {}{}", i, output, shape_info);
                }
            }

            // Show attributes if verbose
            if verbose && !node.attributes.is_empty() {
                println!("  Attributes ({}):", node.attributes.len());
                for attr in &node.attributes {
                    print!("    {} = ", attr.name);

                    // Display attribute value based on type
                    use hologram_onnx_compiler::proto::attribute_proto::AttributeType;
                    match AttributeType::try_from(attr.r#type) {
                        Ok(AttributeType::Int) => println!("{}", attr.i),
                        Ok(AttributeType::Float) => println!("{}", attr.f),
                        Ok(AttributeType::String) => {
                            println!("{:?}", String::from_utf8_lossy(&attr.s))
                        }
                        Ok(AttributeType::Ints) => println!("{:?}", attr.ints),
                        Ok(AttributeType::Floats) => println!("{:?}", attr.floats),
                        Ok(AttributeType::Strings) => {
                            let strings: Vec<_> = attr
                                .strings
                                .iter()
                                .map(|s| String::from_utf8_lossy(s))
                                .collect();
                            println!("{:?}", strings);
                        }
                        Ok(AttributeType::Tensor) => println!("<tensor>"),
                        Ok(AttributeType::Graph) => println!("<graph>"),
                        Ok(AttributeType::SparseTensor) => println!("<sparse_tensor>"),
                        _ => println!("<unknown>"),
                    }
                }
            }

            println!();
        }
    }

    println!("─────────────────────────────────────────────\n");

    // Show summary
    println!("Summary by operator type:");
    let mut sorted_ops: Vec<_> = stats.op_type_counts.iter().collect();
    sorted_ops.sort_by(|a, b| b.1.cmp(a.1));

    for (op_type, count) in sorted_ops {
        if let Some(ref filter) = filter_type {
            if !op_type.contains(filter.as_str()) {
                continue;
            }
        }
        println!("  {:20} × {}", op_type, count);
    }
}

fn show_ops_json(
    graph: &HologramGraph,
    stats: &GraphStatistics,
    model_path: &PathBuf,
    verbose: bool,
    filter_type: &Option<String>,
) -> Result<(), Box<dyn std::error::Error>> {
    use serde_json::{json, Value};

    let mut operators = Vec::new();

    // Iterate through nodes in topological order
    let topo_order = match graph.topological_sort() {
        Ok(order) => order,
        Err(_) => graph.petgraph().node_indices().collect(),
    };

    for node_id in topo_order {
        if let Some(node) = graph.node(node_id) {
            // Apply filter if specified
            if let Some(ref filter) = filter_type {
                if !node.op_type.contains(filter.as_str()) {
                    continue;
                }
            }

            let mut op_json = json!({
                "op_type": node.op_type,
                "name": node.name,
                "domain": node.domain,
                "inputs": node.input_names,
                "outputs": node.output_names,
            });

            // Add attributes if verbose
            if verbose {
                let attrs: Vec<Value> = node
                    .attributes
                    .iter()
                    .map(|attr| {
                        json!({
                            "name": attr.name,
                            "type": attr.r#type,
                            "value": format_attribute_value(attr),
                        })
                    })
                    .collect();
                op_json["attributes"] = json!(attrs);
            }

            operators.push(op_json);
        }
    }

    let output = json!({
        "model_path": model_path.display().to_string(),
        "total_operators": stats.total_nodes,
        "total_edges": stats.total_edges,
        "graph_inputs": stats.num_inputs,
        "graph_outputs": stats.num_outputs,
        "initializers": stats.num_initializers,
        "operator_counts": stats.op_type_counts,
        "operators": operators,
    });

    println!("{}", serde_json::to_string_pretty(&output)?);

    Ok(())
}

fn show_ops_csv(
    graph: &HologramGraph,
    model_path: &PathBuf,
    filter_type: &Option<String>,
) -> Result<(), Box<dyn std::error::Error>> {
    // CSV header
    println!("index,op_type,name,domain,num_inputs,num_outputs,input_names,output_names");

    // Iterate through nodes in topological order
    let topo_order = match graph.topological_sort() {
        Ok(order) => order,
        Err(e) => {
            eprintln!("# Warning: Could not topologically sort graph: {}", e);
            graph.petgraph().node_indices().collect()
        }
    };

    for (idx, node_id) in topo_order.iter().enumerate() {
        if let Some(node) = graph.node(*node_id) {
            // Apply filter if specified
            if let Some(ref filter) = filter_type {
                if !node.op_type.contains(filter.as_str()) {
                    continue;
                }
            }

            let input_names = node.input_names.join(";");
            let output_names = node.output_names.join(";");

            println!(
                "{},{},{},{},{},{},\"{}\",\"{}\"",
                idx + 1,
                node.op_type,
                node.name,
                node.domain,
                node.input_names.len(),
                node.output_names.len(),
                input_names,
                output_names
            );
        }
    }

    println!("# Model: {}", model_path.display());

    Ok(())
}

fn format_attribute_value(attr: &hologram_onnx_compiler::proto::AttributeProto) -> String {
    use hologram_onnx_compiler::proto::attribute_proto::AttributeType;

    match AttributeType::try_from(attr.r#type) {
        Ok(AttributeType::Int) => format!("{}", attr.i),
        Ok(AttributeType::Float) => format!("{}", attr.f),
        Ok(AttributeType::String) => format!("{:?}", String::from_utf8_lossy(&attr.s)),
        Ok(AttributeType::Ints) => format!("{:?}", attr.ints),
        Ok(AttributeType::Floats) => format!("{:?}", attr.floats),
        Ok(AttributeType::Strings) => {
            let strings: Vec<_> = attr
                .strings
                .iter()
                .map(|s| String::from_utf8_lossy(s))
                .collect();
            format!("{:?}", strings)
        }
        Ok(AttributeType::Tensor) => "<tensor>".to_string(),
        Ok(AttributeType::Graph) => "<graph>".to_string(),
        Ok(AttributeType::SparseTensor) => "<sparse_tensor>".to_string(),
        _ => "<unknown>".to_string(),
    }
}
