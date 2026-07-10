import matplotlib.pyplot as plt
import sys
import os

# Add the simulator directory to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), 'substrates', 'atomic-calculator'))

from civic_simulator import CivicSimulator

def generate_visualization():
    sim = CivicSimulator()
    supply = 10000.0
    c_t = 0.5 
    
    # We will simulate the growth of a Lifebushido network
    # Phases: Individual (M=1) -> Triad (M=3) -> Squad (M=9) -> Village (M=27)
    # We'll map this to the timeline to show V_MSC saturating.
    
    base_factors = [1.0, 1.0, 1.0, 1.0]
    
    for t in range(40):
        # Scale factors to simulate growth from Triad to Village
        if t < 10:
            # Triad forming
            factors = [f * (0.8 + 0.02 * t) for f in base_factors]
        elif t < 20:
            # Squad scaling
            factors = [f * (1.0 + 0.03 * (t - 10)) for f in base_factors]
        else:
            # Village saturation (Hundian Ground State)
            factors = [1.5, 1.5, 1.5, 1.5]
            
        supply = sim.step(factors, 0.5, 1.0, 1.0, c_t, supply)
        
    times = [r['time'] for r in sim.history]
    v_msc = [r['v_msc'] for r in sim.history]
    s_civic = [r['s_civic'] for r in sim.history]
    
    fig, ax1 = plt.subplots(figsize=(12, 6))
    
    color = 'tab:blue'
    ax1.set_xlabel('Timeline (Network Growth Cycles)', fontweight='bold')
    ax1.set_ylabel('V_MSC ($)', color=color, fontweight='bold')
    ax1.plot(times, v_msc, color=color, linewidth=3, label='Multiplicity Stablecoin Value')
    ax1.tick_params(axis='y', labelcolor=color)
    
    ax2 = ax1.twinx()
    color = 'tab:green'
    ax2.set_ylabel('Civic State (S_civic)', color=color, fontweight='bold')
    ax2.plot(times, s_civic, color=color, linestyle='--', linewidth=2, label='Civic State')
    ax2.tick_params(axis='y', labelcolor=color)
    
    # Add Lifebushido hierarchy annotations
    ax1.axvspan(0, 10, alpha=0.1, color='gray')
    ax1.text(5, 2.5, 'Triad Phase\n(M=3)', horizontalalignment='center', fontsize=12, fontweight='bold')
    
    ax1.axvspan(10, 20, alpha=0.1, color='orange')
    ax1.text(15, 2.5, 'Squad Phase\n(M=9)', horizontalalignment='center', fontsize=12, fontweight='bold')
    
    ax1.axvspan(20, 40, alpha=0.1, color='green')
    ax1.text(30, 2.5, 'Village Phase\n(Hundian Ground State)', horizontalalignment='center', fontsize=12, fontweight='bold')
    
    plt.title('Hundian Ground State: V_MSC Valuation over Lifebushido Hierarchy', fontsize=16, fontweight='bold')
    fig.tight_layout()
    
    # Ensure artifacts directory exists for saving
    output_path = '/home/multiplicity/.gemini/antigravity-cli/brain/211ad06e-eaf6-4a2b-8f33-8dcabab195c3/hundian_ground_state.png'
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=300)
    print(f"Visualization saved to {output_path}")

if __name__ == "__main__":
    generate_visualization()
