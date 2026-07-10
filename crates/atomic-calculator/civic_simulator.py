"""
Multiplicity Stablecoin Simulator - Civic State Integration
"""
from dataclasses import dataclass
from typing import List

@dataclass
class Multiplicity:
    reciprocity: float
    
    def calculate(self) -> float:
        return 2.0 * self.reciprocity + 1.0

def calculate_civic_state(lambda_m: float, factors: List[float], res: float, emb: float) -> float:
    factor_sum = sum(factors)
    return lambda_m * factor_sum * res * emb

class CivicSimulator:
    def __init__(self):
        self.target_value = 3.0 # Hundian Ground State
        self.time = 0
        self.history = []

    def compute_valuation(self, s_civic: float, c_t: float) -> float:
        """
        V_MSC(t) = 1 + S(t) + C(t)
        Here we define S(t) proportional to the normalized civic state.
        """
        s_t = s_civic * 0.2  # Scaling factor for the simulation
        return 1.0 + s_t + c_t

    def step(self, factors: List[float], lambda_m: float, res: float, emb: float, c_t: float, supply: float) -> float:
        # Step 1: Engine computes Civic State
        s_civic = calculate_civic_state(lambda_m, factors, res, emb)
        
        # Step 2: Compute token value
        v_msc = self.compute_valuation(s_civic, c_t)
        
        # Step 3: Adjust supply based on deviation from target state ($3.0)
        deviation = self.target_value - v_msc
        mint_burn_rate = 0.1 # 10% adjustment rate
        new_supply = supply * (1.0 - (deviation * mint_burn_rate))
        
        self.history.append({
            'time': self.time,
            's_civic': s_civic,
            'v_msc': v_msc,
            'supply': supply
        })
        self.time += 1
        return new_supply

def run_stability_benchmark():
    print("=== Multiplicity Stablecoin - Stability Benchmark ===")
    sim = CivicSimulator()
    supply = 10000.0
    c_t = 0.5 # Constant collateral ratio for this test
    
    # [Resonance, Agency, Integrity, Viability]
    base_factors = [1.0, 1.0, 1.0, 1.0] 
    
    print("Phase 1: Equilibration (t=0 to 10)")
    for t in range(10):
        supply = sim.step(base_factors, 0.5, 1.0, 1.0, c_t, supply)
        r = sim.history[-1]
        print(f"t={r['time']:02d} | Scivic: {r['s_civic']:.2f} | V_MSC: ${r['v_msc']:.3f} | Supply: {r['supply']:.1f}")

    print("\nPhase 2: High-Stress Scenario (t=10 to 20)")
    stress_factors = [0.4, 0.6, 0.8, 0.3] # Massive drop in viability and resonance
    for t in range(10, 20):
        supply = sim.step(stress_factors, 0.5, 0.8, 0.8, c_t, supply)
        r = sim.history[-1]
        print(f"t={r['time']:02d} | Scivic: {r['s_civic']:.2f} | V_MSC: ${r['v_msc']:.3f} | Supply: {r['supply']:.1f}")

    print("\nPhase 3: Hundian Ground State Recovery (t=20 to 30)")
    for t in range(20, 30):
        # As the system stabilizes, factors approach 1.5 (saturation limit)
        recovery_factors = [1.5, 1.5, 1.5, 1.5]
        supply = sim.step(recovery_factors, 0.5, 1.0, 1.0, c_t, supply)
        r = sim.history[-1]
        print(f"t={r['time']:02d} | Scivic: {r['s_civic']:.2f} | V_MSC: ${r['v_msc']:.3f} | Supply: {r['supply']:.1f}")

if __name__ == "__main__":
    run_stability_benchmark()
