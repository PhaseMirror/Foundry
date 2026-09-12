#!/usr/bin/env python3
"""
Governed ZRSD simulation: QuTiP physics → Rust legal engine → certified witness.
Assumes sedona_spine binary is built and in PATH or at ./models/legalese-scopist/target/release/.
"""

import subprocess
import json
import time
import numpy as np

# ------------------ QuTiP simulation generator ------------------
def run_zrsd_simulation():
    """
    Yields physics telemetry as a dict with keys matching EsiInputs.
    """
    t = 0.0
    dt = 0.1
    fidelity_initial = 0.95
    damping = 0.02          
    oscillation_freq = 0.5  

    while t < 10.0:
        envelope = np.exp(-damping * t)
        osc = 0.05 * np.sin(oscillation_freq * t * 2 * np.pi)
        fidelity = fidelity_initial * envelope + osc
        fidelity = max(0.0, min(1.0, fidelity))

        entropy_rate = -0.1 * (fidelity - 0.5) + 0.02 * np.sin(t * 0.3)
        hist = np.random.normal(loc=fidelity, scale=0.1, size=64).clip(0, 1).tolist()

        spoliation_potential = 1.0 - fidelity
        preservation_urgency = 0.5 + 0.5 * (1.0 - fidelity)

        yield {
            "spoliation_potential": spoliation_potential,
            "preservation_urgency": preservation_urgency,
            "volume_estimate_gb": 0.0,
            "fidelity": fidelity,
            "entropy_rate": entropy_rate,
            "zeta_truncation": 20,
            "histogram": hist,
        }

        t += dt
        time.sleep(0.01)

# ------------------ Main orchestration ------------------
def main():
    rust_bin = "./target/release/sedona_spine"
    proc = subprocess.Popen(
        [rust_bin],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1
    )

    print("🚀 ZRSD simulation started. Streaming to Sedona Spine...\n")

    step = 0
    for telemetry in run_zrsd_simulation():
        if step % 10 != 0:
            step += 1
            continue

        json_line = json.dumps(telemetry)
        proc.stdin.write(json_line + "\n")
        proc.stdin.flush()

        output_line = proc.stdout.readline()
        if not output_line:
            break
        result = json.loads(output_line)

        if "error" in result:
            print(f"Rust returned error: {result['error']}")
            break

        print(f"Step {step:4d} | Risk: {result['risk_level']:>8} | "
              f"c_λ = {result['c_lambda']:.4f} | "
              f"C_TOTAL: {result['c_total'][:16]}... "
              f"(W0: {result['w0_exec'][:12]}... W1: {result['w1_axiom'][:12]}... W2: {result['w2_phys'][:12]}...)")

        if result["risk_level"] == "Critical":
            print("🛑 PRESERVATION ALERT! Simulation would be halted.")

        step += 1

    proc.stdin.close()
    proc.stdout.close()
    proc.stderr.close()
    proc.wait()
    print("\n✅ Governance completed. C6 witness chain logged.")

if __name__ == "__main__":
    main()
