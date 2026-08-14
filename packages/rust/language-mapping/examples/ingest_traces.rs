use alp_rs::cnl::CnlCompiler;
use language_mapping::{BehavioralRegime, CandidatePartition, Output, Perturbation, Prompt};
use serde::Deserialize;
use std::fs;

#[derive(Deserialize, Debug)]
struct TraceRecord {
    original_prompt: String,
    expected_output: String,
    structural_change: bool,
    isomorphic_change: bool,
    perturbed_prompt: String,
    perturbed_output: String,
}

fn main() {
    println!("=== Ingesting Real LLM JSON Traces & ALP/CNL Integration ===\n");

    let file_content = fs::read_to_string("traces.json").expect("Failed to read traces.json");
    let traces: Vec<TraceRecord> =
        serde_json::from_str(&file_content).expect("Failed to parse JSON");

    let mut partition = CandidatePartition::new("Empirical_Traces_Regime", 0.05);
    let mut artifact_count = 0;
    let mut stable_count = 0;

    for (idx, trace) in traces.iter().enumerate() {
        let orig_prompt = Prompt(trace.original_prompt.clone());
        let exp_output = Output::new(&trace.expected_output, vec![0.5, 0.5, 0.5]);

        // Establish the topology for this trace
        partition
            .topology
            .insert_mapping(orig_prompt.clone(), exp_output.clone());

        let perturbation = Perturbation {
            structural_change: trace.structural_change,
            isomorphic_change: trace.isomorphic_change,
            original_prompt: orig_prompt,
            perturbed_prompt: Prompt(trace.perturbed_prompt.clone()),
        };

        // If the trace resulted in an artifact, mock a completely orthogonal vector
        let perturbed_vec =
            if trace.structural_change && trace.expected_output != trace.perturbed_output {
                vec![-0.5, -0.5, -0.5]
            } else {
                vec![0.49, 0.51, 0.48]
            };

        let perturbed_out = Output::new(&trace.perturbed_output, perturbed_vec);
        let regime = partition.evaluate_perturbation(&perturbation, &perturbed_out);

        println!("Trace #{}: {:?}", idx + 1, regime);
        match regime {
            BehavioralRegime::Artifact => artifact_count += 1,
            BehavioralRegime::Stable => stable_count += 1,
        }
    }

    println!("------------------------------------------------------------");
    println!("Total Traces: {}", traces.len());
    println!("Stable Regimes: {}", stable_count);
    println!("Artifacts Detected: {}", artifact_count);
    println!("------------------------------------------------------------");
    println!("Compiling dynamic CNL policy based on regime integrity...\n");

    // Tie into ALP/CNL
    // We refine the policy by scaling adjustments dynamically based on the frequency of artifacts
    // versus stable regimes detected within the LLM mapping topology.
    let mut cnl_source = String::from("policy Trace_Driven_Adjustment\n");

    if artifact_count > 0 {
        // If we detect regime dissolution (artifacts), we penalize multiplicity aggressively
        // and reduce the arta defect to tighten security constraints.
        let multiplicity_penalty = (artifact_count as f64) * 0.35;
        let arta_adjustment = 0.20;

        cnl_source.push_str(&format!(
            "increase multiplicity by -{:.2}\n",
            multiplicity_penalty
        ));
        cnl_source.push_str(&format!("decrease arta defect by {:.2}\n", arta_adjustment));
    } else {
        // If the regime is perfectly stable, we loosen constraints slightly to reward robust mappings.
        cnl_source.push_str("increase multiplicity by 0.50\n");
        cnl_source.push_str("decrease arta defect by -0.10\n");
    }

    cnl_source.push_str("noop");

    println!("Generated CNL Source:\n{}", cnl_source);

    match CnlCompiler::parse(&cnl_source) {
        Ok(policy) => {
            println!("\n[Success] CNL Compiled Deterministically!");
            println!("ALP Policy AST: {:?}", policy);
        }
        Err(e) => {
            eprintln!("\n[Error] CNL Compilation Failed: {}", e);
        }
    }
}
