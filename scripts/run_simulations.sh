#!/usr/bin/env bash
set -euo pipefail

# ---- Configuration ----
BINARY="cargo run -p pirtm-rs --bin uac_simulator --"
RUNS=10                # number of simulation runs
OUTPUT_CSV="simulation_results.csv"
PLOT_SCRIPT="scripts/plot_hundian.py"   # adjust if needed
ZK_FLAG="--zk"         # include ZK verification; remove if not needed
VK_PATH="${VK_PATH:-}" # optional verification key path

# ---- Initialize CSV ----
echo "run,pre_arta_defect,post_arta_defect,zk_status,pre_rta_dist,post_rta_dist,langlands_loss,total_loss,zk_time" > "$OUTPUT_CSV"

# ---- Main Loop ----
for (( i=1; i<=RUNS; i++ )); do
    echo "=== Run $i/$RUNS ==="
    # Run simulator and capture output
    output=$($BINARY $ZK_FLAG ${VK_PATH:+--vk "$VK_PATH"} 2>&1)
    
    # Extract metrics (adjust patterns to match your simulator's output)
    pre_defect=$(echo "$output" | grep -oP 'pre_arta_defect:\s*\K[\d.]+' || echo "0")
    post_defect=$(echo "$output" | grep -oP 'post_arta_defect:\s*\K[\d.]+' || echo "0")
    zk_status=$(echo "$output" | grep -oP 'zk_status:\s*\K\w+' || echo "N/A")
    pre_rta=$(echo "$output" | grep -oP 'pre_rta_dist:\s*\K[\d.N/A]+' || echo "0")
    post_rta=$(echo "$output" | grep -oP 'post_rta_dist:\s*\K[\d.]+' || echo "0")
    langlands_loss=$(echo "$output" | grep -oP 'post_langlands_loss:\s*\K[\d.]+' || echo "0")
    total_loss=$(echo "$output" | grep -oP 'post_total_loss:\s*\K[\d.]+' || echo "0")
    
    # Extract ZK verification time (if present)
    zk_time=$(echo "$output" | grep -oP '\[PROFILE\] ZK verification time: \K[^\]]+' || echo "0")
    # Append to CSV
    echo "$i,$pre_defect,$post_defect,$zk_status,$pre_rta,$post_rta,$langlands_loss,$total_loss,$zk_time" >> "$OUTPUT_CSV"
    
    echo "  pre_defect=$pre_defect  post_defect=$post_defect  ZK=$zk_status"
done

echo "Simulation data saved to $OUTPUT_CSV"

# ---- Generate plot (if plot script exists) ----
if [ -f "$PLOT_SCRIPT" ]; then
    python "$PLOT_SCRIPT" "$OUTPUT_CSV"
    echo "Plot generated."
else
    echo "Plot script not found; skipping plot generation."
fi
