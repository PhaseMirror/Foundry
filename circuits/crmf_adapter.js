/**
 * CRMFWitness Adapter (Node.js script for Pathway 2)
 * 
 * PURPOSE:
 * This script bridges the gap between the Rust `pirtm-engine` and the Circom ZK Prover.
 * It reads the `CRMFWitness.json` trace output by the Rust engine and reformats it 
 * into the `input.json` format required by SnarkJS/Circom to generate the ZK Proof.
 */

const fs = require('fs');
const path = require('path');

function adaptWitness(traceFile, outputFile) {
    console.log(`[Adapter] Reading CRMFWitness from Rust Engine: ${traceFile}`);
    
    if (!fs.existsSync(traceFile)) {
        console.error("Error: Trace file not found. Ensure pirtm-engine ran successfully.");
        process.exit(1);
    }

    const rawData = fs.readFileSync(traceFile, 'utf8');
    const trace = JSON.parse(rawData);

    // Validate the trace conforms to UOR constraints
    if (trace.k_dimension > 133144) {
        console.error(`[Adapter] CRITICAL L3 VIOLATION: Dimension ${trace.k_dimension} exceeds UORMatMul.lean ceiling!`);
        process.exit(1);
    }

    // Format for Circom SnarkJS
    const circomInput = {
        activations: trace.activations,
        weights: trace.weights,
        expected_accum: trace.final_accumulation
    };

    fs.writeFileSync(outputFile, JSON.stringify(circomInput, null, 2));
    console.log(`[Adapter] Successfully generated Circom input: ${outputFile}`);
    console.log(`[Adapter] Ready to pipe to snarkjs groth16 prove.`);
}

// Executed as: node crmf_adapter.js <in.json> <out.json>
if (require.main === module) {
    const args = process.argv.slice(2);
    if (args.length < 2) {
        console.log("Usage: node crmf_adapter.js <trace_input.json> <circom_output.json>");
        process.exit(1);
    }
    adaptWitness(args[0], args[1]);
}

module.exports = { adaptWitness };
