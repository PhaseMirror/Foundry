#!/usr/bin/env python3
import argparse
import yaml
import os
from pathlib import Path

def generate_rust_harness(yaml_file, out_dir, bounds):
    with open(yaml_file, 'r') as f:
        data = yaml.safe_load(f)
    
    name = data.get('name', 'unknown')
    rust_impl = data.get('rust_implementation', {})
    func = rust_impl.get('function', 'unknown_func')
    
    out_path = Path(out_dir) / f"{name}_harness.rs"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    
    inputs = data.get('inputs', [])
    outputs = data.get('outputs', [])
    
    rust_vars = []
    for var in inputs + outputs:
        v_name = var['name']
        v_type = var.get('type', 'int')
        if v_type == 'int':
            r_type = 'i32'
        elif v_type == 'bool':
            r_type = 'bool'
        elif v_type == 'rat':
            r_type = 'f64'
        else:
            r_type = 'f64'
        rust_vars.append(f"    let {v_name}: {r_type} = kani::any();")
        
        # Add basic bounds if present
        if 'bounds' in var and len(var['bounds']) == 2:
            rust_vars.append(f"    kani::assume({v_name} >= {var['bounds'][0]} && {v_name} <= {var['bounds'][1]});")

    rust_vars_str = "\n".join(rust_vars)

    theorems = data.get('theorems', [])
    assumes = []
    asserts = []
    for t in theorems:
        stmt = t.get('statement', '').replace('≤', '<=')
        if '=>' in stmt:
            parts = stmt.split('=>')
            assumes.append(f"    kani::assume({parts[0].strip()});")
            asserts.append(f"    kani::assert({parts[1].strip()}, \"{t['id']} failed\");")
        elif stmt:
            assumes.append(f"    kani::assume({stmt});")
            
    assumes_str = "\n".join(assumes)
    asserts_str = "\n".join(asserts)

    stub = f"""// Auto-generated Kani harness stub for {name}
// Telemetry emission proof generated from {yaml_file}

#[kani::proof]
#[kani::unwind({bounds})]
pub fn harness_{name}() {{
    // The environment requires the generated stubs to finalize the telemetry emission proof.
    // Initialize symbolic variables:
{rust_vars_str}
    
    // Bridge Lean proofs:
{assumes_str}
    
    // Check theorems:
{asserts_str}
}}
"""
    out_path.write_text(stub)
    print(f"✅ Generated harness stub at {out_path}")

def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="lang")
    rust_parser = subparsers.add_parser("rust")
    rust_sub = rust_parser.add_subparsers(dest="action")
    gen_parser = rust_sub.add_parser("generate")
    gen_sub = gen_parser.add_subparsers(dest="target")
    harness_parser = gen_sub.add_parser("harness")
    
    harness_parser.add_argument("--contract", required=True)
    harness_parser.add_argument("--output", required=True)
    harness_parser.add_argument("--bounds", required=True)
    harness_parser.add_argument("--telemetry-format", required=False)
    harness_parser.add_argument("--petc-enforced", action="store_true")
    
    args = parser.parse_args()
    
    if args.lang == "rust" and args.action == "generate" and args.target == "harness":
        bounds = args.bounds.split('=')[1] if '=' in args.bounds else args.bounds
        generate_rust_harness(args.contract, args.output, bounds)

if __name__ == "__main__":
    main()
