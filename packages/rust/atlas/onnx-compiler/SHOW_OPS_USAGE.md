# Show ONNX Operators Tool

The `holo-run show-ops` subcommand allows you to inspect and analyze ONNX models by displaying all operators with their details.

## Basic Usage

```bash
# Build the tool
cargo build --bin holo-run --release

# Show all operators in text format
cargo run --bin holo-run -- show-ops model.onnx

# Or use the release build
./target/release/holo-run show-ops model.onnx
```

## Options

### Statistics Only (`--stats-only` or `-s`)

Show only a summary of operator types without detailed information:

```bash
cargo run --bin holo-run -- show-ops model.onnx --stats-only
```

Example output:
```
┌─────────────────────────────────────────────┐
│ ONNX Model Statistics                        │
└─────────────────────────────────────────────┘

Total operators: 90
Total edges: 101
Graph inputs: 2
Graph outputs: 2
Initializers: 52

Operator types:
  Add                  × 22
  MatMul               × 16
  Reshape              × 12
  Transpose            × 10
  ...
```

### Filter by Type (`--filter-type` or `-t`)

Show only operators of a specific type:

```bash
# Show only MatMul operators
cargo run --bin holo-run -- show-ops model.onnx -t MatMul

# Show only LayerNormalization operators
cargo run --bin holo-run -- show-ops model.onnx -t LayerNormalization
```

### Verbose Mode (`--verbose` or `-v`)

Include detailed attribute information for each operator:

```bash
cargo run --bin holo-run -- show-ops model.onnx --verbose
```

This will show attributes like:
- Axis values
- Epsilon parameters
- Transposition flags
- Kernel shapes
- And more...

### Output Formats (`--format` or `-f`)

Choose between different output formats:

#### Text Format (default)
```bash
cargo run --bin holo-run -- show-ops model.onnx --format text
```

Example output:
```
─────────────────────────────────────────────
Operator #12: MatMul
  Name: node_MatMul_54
  Inputs (2):
    [0] layer_norm
    [1] val_55 (initializer)
  Outputs (1):
    [0] val_56
```

#### JSON Format
```bash
cargo run --bin holo-run -- show-ops model.onnx --format json
```

Example output:
```json
{
  "model_path": "model.onnx",
  "total_operators": 90,
  "operator_counts": {
    "Add": 22,
    "MatMul": 16,
    ...
  },
  "operators": [
    {
      "op_type": "MatMul",
      "name": "node_MatMul_54",
      "inputs": ["layer_norm", "val_55"],
      "outputs": ["val_56"]
    }
  ]
}
```

#### CSV Format
```bash
cargo run --bin holo-run -- show-ops model.onnx --format csv
```

Example output:
```csv
index,op_type,name,domain,num_inputs,num_outputs,input_names,output_names
1,Gather,node_Gather,",2,1,"input_ids;embeddings.word_embeddings.weight","val_2"
2,Gather,node_Gather_1,",2,1,"token_type_ids;embeddings.token_type_embeddings.weight","val_4"
...
```

## Combined Examples

### Export all MatMul operators to JSON
```bash
cargo run --bin holo-run -- show-ops model.onnx -t MatMul -f json > matmul_ops.json
```

### Get detailed attributes for Conv operators
```bash
cargo run --bin holo-run -- show-ops model.onnx -t Conv --verbose
```

### Export operator list to CSV for analysis
```bash
cargo run --bin holo-run -- show-ops model.onnx -f csv > operators.csv
```

### Quick statistics check
```bash
cargo run --bin holo-run -- show-ops model.onnx -s
```

## Use Cases

1. **Model Analysis**: Understand the structure and composition of ONNX models
2. **Debugging**: Identify specific operators and their connections
3. **Optimization Planning**: See which operators are most common to prioritize optimization
4. **Documentation**: Generate operator lists for documentation purposes
5. **Compatibility Checking**: Verify which operators are present before deployment

## Integration with Other Tools

The JSON and CSV output formats make it easy to integrate with other tools:

```bash
# Pipe JSON to jq for further processing
cargo run --bin holo-run -- show-ops model.onnx -f json | jq '.operators[] | select(.op_type == "MatMul")'

# Import CSV into spreadsheet applications
cargo run --bin holo-run -- show-ops model.onnx -f csv > ops.csv
# Open ops.csv in Excel, Google Sheets, etc.

# Count specific operator types
cargo run --bin holo-run -- show-ops model.onnx -f csv | grep "MatMul" | wc -l
```
