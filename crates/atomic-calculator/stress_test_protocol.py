import sys
import os

sys.path.append(os.path.dirname(__file__))
from civic_simulator import CivicSimulator

def print_separator(title):
    print(f"\n{'='*10} {title} {'='*10}")

def scenario_node_failure_cascade():
    print_separator("Scenario 1: Node-Failure Cascade")
    # Simulate instantaneous loss of an entire "Tribe" level (27 nodes).
    sim = CivicSimulator()
    supply = 10000.0
    c_t = 0.5
    factors = [1.5, 1.5, 1.5, 1.5] # Start at Hundian Ground State
    
    print("Pre-Crash: Sustained Equilibrium")
    for t in range(5):
        supply = sim.step(factors, 0.5, 1.0, 1.0, c_t, supply)
        r = sim.history[-1]
        print(f"t={r['time']:02d} | Scivic: {r['s_civic']:.2f} | V_MSC: ${r['v_msc']:.3f} | Supply: {r['supply']:.1f}")

    print("Crash Event: Loss of 27 nodes (Massive Resonance & Agency drop)")
    factors = [0.6, 0.6, 1.5, 1.5] # Sharp drop in Resonance and Agency
    supply *= 0.8 # Sudden loss of supply capacity
    
    for t in range(5, 10):
        supply = sim.step(factors, 0.5, 1.0, 1.0, c_t, supply)
        r = sim.history[-1]
        print(f"t={r['time']:02d} | Scivic: {r['s_civic']:.2f} | V_MSC: ${r['v_msc']:.3f} | Supply: {r['supply']:.1f}")

    print("Recovery: System isolates the failure and stabilizes")
    factors = [1.2, 1.2, 1.5, 1.5] # Re-routing resonance
    for t in range(10, 15):
        supply = sim.step(factors, 0.5, 1.0, 1.0, c_t, supply)
        r = sim.history[-1]
        print(f"t={r['time']:02d} | Scivic: {r['s_civic']:.2f} | V_MSC: ${r['v_msc']:.3f} | Supply: {r['supply']:.1f}")

def scenario_factor_drop():
    print_separator("Scenario 2: Systemic Factor-Drop Event")
    # Simulate a systemic loss of one of the 4 "Minimal Core" factors (e.g., Integrity drops to near zero)
    sim = CivicSimulator()
    supply = 10000.0
    c_t = 0.5
    factors = [1.5, 1.5, 1.5, 1.5] 
    
    print("Baseline State")
    supply = sim.step(factors, 0.5, 1.0, 1.0, c_t, supply)
    r = sim.history[-1]
    print(f"t={r['time']:02d} | Scivic: {r['s_civic']:.2f} | V_MSC: ${r['v_msc']:.3f} | Supply: {r['supply']:.1f}")
    
    print("Crisis Event: Integrity and Resilience crash grid-wide")
    factors = [1.5, 1.5, 0.1, 0.2] # Integrity and Viability drop
    for t in range(1, 10):
        supply = sim.step(factors, 0.5, 0.6, 0.6, c_t, supply) # Embodiment and Res drop too
        r = sim.history[-1]
        print(f"t={r['time']:02d} | Scivic: {r['s_civic']:.2f} | V_MSC: ${r['v_msc']:.3f} | Supply: {r['supply']:.1f}")

def scenario_oversaturation():
    print_separator("Scenario 3: Hundian Over-Saturation (Bubble Event)")
    # Force a rapid, non-governed expansion
    sim = CivicSimulator()
    supply = 10000.0
    c_t = 0.5
    factors = [1.5, 1.5, 1.5, 1.5] 
    
    print("Baseline State")
    supply = sim.step(factors, 0.5, 1.0, 1.0, c_t, supply)
    r = sim.history[-1]
    print(f"t={r['time']:02d} | Scivic: {r['s_civic']:.2f} | V_MSC: ${r['v_msc']:.3f} | Supply: {r['supply']:.1f}")

    print("Bubble Event: Massive non-resonant expansion")
    factors = [2.5, 2.5, 2.5, 2.5] # Unnatural inflation
    supply *= 2.0 # Artificial inflation
    
    for t in range(1, 6):
        supply = sim.step(factors, 0.5, 1.2, 1.2, c_t, supply)
        r = sim.history[-1]
        print(f"t={r['time']:02d} | Scivic: {r['s_civic']:.2f} | V_MSC: ${r['v_msc']:.3f} | Supply: {r['supply']:.1f}")
        
    print("Governed Contraction: Phase Mirror triggers algorithm to return to cap")
    factors = [1.5, 1.5, 1.5, 1.5] # Governance restores factors to true state
    for t in range(6, 15):
        supply = sim.step(factors, 0.5, 1.0, 1.0, c_t, supply)
        r = sim.history[-1]
        print(f"t={r['time']:02d} | Scivic: {r['s_civic']:.2f} | V_MSC: ${r['v_msc']:.3f} | Supply: {r['supply']:.1f}")

if __name__ == "__main__":
    scenario_node_failure_cascade()
    scenario_factor_drop()
    scenario_oversaturation()
