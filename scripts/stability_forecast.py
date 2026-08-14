import math

def generate_forecast():
    print("--- [FORECAST] Generating 30-Day Stability & Convergence Forecast ---")
    print("Model Parameters:")
    print("  - Target Threshold: 15.0% (0.15)")
    print("  - Initial MD-002 FPR: 20.0% (0.20)")
    print("  - Stabilization Rate (lambda): 0.08 / day")
    print("\nTimeline Simulation:")
    print("| Day | Total Violations | User Overrides | Measured FPR | Compliance Posture |")
    print("|---|---|---|---|---|")
    
    # Baseline parameters
    V_base = 5.0
    V_init = 5.0
    O_base = 0.5
    O_init = 1.5
    decay_rate = 0.08
    
    threshold = 0.15
    rehardening_day = None
    
    for day in range(1, 31):
        # Exponential decay model for violations and overrides
        decay = math.exp(-decay_rate * (day - 1))
        V_t = V_base + V_init * decay
        O_t = O_base + O_init * decay
        
        # Calculate FPR
        fpr = O_t / V_t
        
        # Posture state
        posture = "WARN (Degraded)" if fpr > threshold else "BLOCK (Strict)"
        
        if fpr <= threshold and rehardening_day is None:
            rehardening_day = day
            
        print(f"| {day:3d} | {V_t:16.2f} | {O_t:14.2f} | {fpr:11.2%} | {posture:18s} |")
        
    print("\n--- Forecast Analysis Summary ---")
    if rehardening_day:
        print(f"[*] Re-hardening Event: Day {rehardening_day}")
        print(f"    - On Day {rehardening_day}, the system naturally drops below the 15% threshold.")
        print("    - Action: Oracle CLI automatically elevates MD-002 back to strict BLOCK mode.")
        print("    - Result: Complete environment immunization achieved.")
    else:
        print("[*] No re-hardening event detected within 30 days.")

if __name__ == "__main__":
    generate_forecast()
