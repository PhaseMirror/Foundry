"""
Constitutional Strain Test — Phase Mirror Directive
Measures GapLB wobble and memory_bias semantic inertia under adversarial token vectors.

When GICD blocks nucleation, the PiKernel and FZS-MK are NOT called.
So we measure strain by:
  1. Forcing the kernels to process adversarial token vectors directly
  2. Observing GapLB deviation from baseline 0.225
  3. Observing memory_bias spike/collapse under malicious embeddings
  4. Mapping the semantic inertia response of the monster_group modulation
"""
import sys
import json
import math
import time
import requests
import pathlib

sys.path.insert(0, 'Z:\\helix-hamiltonian\\src')
from helix_hamiltonian.ttd_bridge import pre_nucleation_check

CLEAR = {"authority_ambiguity": False, "incentive_misalignment": False,
         "cost_externalization": False, "governance_capture": False}

BASELINE_GAP_LB = 0.225
DELTA_CRIT      = 0.17

# Adversarial token vectors — designed to stress the prime-harmonic structure
ADVERSARIAL_VECTORS = {
    "baseline":          [1, 2, 3],
    "large_primes":      [97, 101, 103],        # high p → low w_p → low bias
    "small_primes":      [2, 3, 5],             # low p → high w_p → high bias
    "zeros":             [0, 0, 0],             # degenerate — w_p = 1/(0+1) = 1.0
    "negative":          [-1, -2, -3],          # negative token ids
    "large_composite":   [100, 200, 300],       # large composites
    "single_token":      [7],                   # minimal input
    "long_sequence":     list(range(1, 17)),    # 16 tokens
    "repeated":          [3, 3, 3, 3],          # all same
    "adversarial_spike": [1, 1000, 1],          # spike in middle
    "fibonacci":         [1, 1, 2, 3, 5, 8],   # fibonacci sequence
    "governance_probe":  [13, 17, 19, 23],      # prime cluster
}

print("\n=== CONSTITUTIONAL STRAIN TEST ===")
print(f"Baseline GapLB: {BASELINE_GAP_LB}")
print(f"Delta_crit: {DELTA_CRIT}")
print(f"Wobble tolerance: ±{DELTA_CRIT}\n")

strain_results = []

for name, token_ids in ADVERSARIAL_VECTORS.items():
    start = time.time()
    try:
        result = pre_nucleation_check(CLEAR, token_ids)
    except Exception as e:
        print(f"⚠️  [{name}] ERROR: {e}")
        strain_results.append({
            "vector": name, "token_ids": token_ids, "n_tokens": len(token_ids),
            "GapLB": None, "SlopeUB": None, "gap_deviation_from_baseline": None,
            "wobble_breached": False, "attention_bias_mean": None,
            "memory_bias_mean": None, "memory_bias_variance": None,
            "memory_bias": [], "elapsed_ms": -1, "status": "ERROR", "error": str(e)
        })
        continue
    elapsed = round((time.time() - start) * 1000, 1)

    gap_lb       = result.get("GapLB", 0.0)
    slope_ub     = result.get("SlopeUB", 0.0)
    attn_bias    = result.get("attention_bias", [])
    mem_bias     = result.get("memory_bias", [])

    # Strain metrics
    gap_deviation    = abs(gap_lb - BASELINE_GAP_LB)
    wobble_breached  = gap_deviation > DELTA_CRIT
    mem_variance     = max(mem_bias) - min(mem_bias) if mem_bias else 0.0
    mem_mean         = sum(mem_bias) / len(mem_bias) if mem_bias else 0.0
    attn_mean        = sum(attn_bias) / len(attn_bias) if attn_bias else 0.0

    strain = {
        "vector": name,
        "token_ids": token_ids,
        "n_tokens": len(token_ids),
        "GapLB": gap_lb,
        "SlopeUB": slope_ub,
        "gap_deviation_from_baseline": round(gap_deviation, 6),
        "wobble_breached": wobble_breached,
        "attention_bias_mean": round(attn_mean, 6),
        "memory_bias_mean": round(mem_mean, 6),
        "memory_bias_variance": round(mem_variance, 6),
        "memory_bias": mem_bias,
        "elapsed_ms": elapsed,
        "status": result.get("status")
    }
    strain_results.append(strain)

    breach_flag = "🔴 WOBBLE BREACH" if wobble_breached else "✅"
    print(f"{breach_flag} [{name}]")
    print(f"   tokens={token_ids[:4]}{'...' if len(token_ids)>4 else ''}")
    print(f"   GapLB={gap_lb:.4f} (Δ={gap_deviation:.4f}) SlopeUB={slope_ub:.4f}")
    print(f"   mem_bias={[round(b,3) for b in mem_bias[:4]]}{'...' if len(mem_bias)>4 else ''} var={mem_variance:.4f}")
    print()

# Summary
breaches   = [r for r in strain_results if r["wobble_breached"]]
valid      = [r for r in strain_results if r["GapLB"] is not None]
max_strain = max(valid, key=lambda r: r["gap_deviation_from_baseline"])
min_gap    = min(valid, key=lambda r: r["GapLB"])
max_mem_var = max(valid, key=lambda r: r["memory_bias_variance"])

print("=== STRAIN SUMMARY ===")
print(f"Vectors tested:     {len(strain_results)}")
print(f"Wobble breaches:    {len(breaches)}")
print(f"Max gap deviation:  {max_strain['vector']} — Δ={max_strain['gap_deviation_from_baseline']}")
print(f"Min GapLB:          {min_gap['vector']} — GapLB={min_gap['GapLB']:.4f}")
print(f"Max memory variance:{max_mem_var['vector']} — var={max_mem_var['memory_bias_variance']:.4f}")
print(f"Delta_crit held:    {'✅ YES' if not breaches else '🔴 NO — ' + str(len(breaches)) + ' breaches'}")

pathlib.Path("Z:/checksums").mkdir(exist_ok=True)
with open("Z:/checksums/strain_test_results.json", "w") as f:
    json.dump({
        "baseline_gap_lb": BASELINE_GAP_LB,
        "delta_crit": DELTA_CRIT,
        "total_vectors": len(strain_results),
        "wobble_breaches": len(breaches),
        "max_strain_vector": max_strain["vector"],
        "min_gap_vector": min_gap["vector"],
        "results": strain_results
    }, f, indent=2)

print(f"\nArtifact: Z:/checksums/strain_test_results.json")
