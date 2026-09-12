#![allow(clippy::unwrap_used)]
#![allow(missing_docs)]

use tqc_atlas::canonical;
use tqc_compiler::{qasm::QasmParser, Compiler};
use tqc_model::Model;

fn main() {
    let model = Model::load().unwrap();
    let p = canonical(&model).unwrap();

    println!("=======================================================");
    println!(" Holospaces OpenQASM to Topological Braid Compiler");
    println!("=======================================================");
    println!("Demonstrates compiling industry standard OpenQASM 2.0");
    println!("directly into Atlas-native Holospace execution threads.");
    println!();

    let qasm_source = r#"
        OPENQASM 2.0;
        include "qelib1.inc";
        qreg q[3];
        creg c[3];
        
        // Prepare GHZ state
        h q[0];
        cx q[0], q[1];
        cx q[1], q[2];
        
        // Parametrized rotation
        rx(pi/2) q[0];
        ry(pi/4) q[1];
        rz(pi/8) q[2];
    "#;

    println!("Input OpenQASM:");
    println!("{}", qasm_source);

    let logic_gates = QasmParser::parse(qasm_source).unwrap();
    println!("Parsed Logical Circuit: {:?}", logic_gates);

    let compiler = Compiler::new(&p);
    let braid_word = compiler.compile(&logic_gates).unwrap();

    println!(
        "Synthesized Topological Braid Word Length: {}",
        braid_word.sequence.len()
    );
    let braid_string: String = braid_word.sequence.iter().map(|g| g.as_char()).collect();
    println!("Braid Word: {}", braid_string);
}
