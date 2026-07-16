import matplotlib.pyplot as plt
import sys
import csv

def generate_visualization(csv_path):
    runs = []
    pre_defects = []
    post_defects = []
    pre_losses = []
    post_losses = []
    zk_times = []

    with open(csv_path, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            runs.append(int(row['run']))
            pre_defects.append(float(row['pre_arta_defect']))
            post_defects.append(float(row['post_arta_defect']))
            pre_losses.append(float(row.get('pre_total_loss', row.get('total_loss', 0))))
            post_losses.append(float(row.get('post_total_loss', row.get('total_loss', 0))))
            zk_times.append(float(row.get('zk_time', 0)))

    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('Hundian Ground State: UAC Simulation Results', fontsize=16, fontweight='bold')

    ax = axes[0, 0]
    ax.plot(runs, pre_defects, marker='o', label='Pre-Fit Arta Defect', color='tab:red')
    ax.plot(runs, post_defects, marker='o', label='Post-Fit Arta Defect', color='tab:green')
    ax.set_xlabel('Run')
    ax.set_ylabel('Arta Defect')
    ax.set_title('Arta Defect (Symmetry Deviation)')
    ax.legend()
    ax.grid(True, alpha=0.3)

    ax = axes[0, 1]
    ax.plot(runs, pre_losses, marker='s', label='Pre-Fit Total Loss', color='tab:orange')
    ax.plot(runs, post_losses, marker='s', label='Post-Fit Total Loss', color='tab:blue')
    ax.set_xlabel('Run')
    ax.set_ylabel('Total Loss')
    ax.set_title('Langlands + Arta Total Loss')
    ax.legend()
    ax.grid(True, alpha=0.3)

    ax = axes[1, 0]
    ax.bar(runs, zk_times, color='tab:purple', alpha=0.7)
    ax.set_xlabel('Run')
    ax.set_ylabel('Time (seconds)')
    ax.set_title('ZK Verification Time')
    ax.grid(True, alpha=0.3, axis='y')

    ax = axes[1, 1]
    reduction = [pre - post for pre, post in zip(pre_defects, post_defects)]
    colors = ['tab:green' if r > 0 else 'tab:red' for r in reduction]
    ax.bar(runs, reduction, color=colors, alpha=0.7)
    ax.set_xlabel('Run')
    ax.set_ylabel('Defect Reduction')
    ax.set_title('Arta Defect Reduction (Pre - Post)')
    ax.grid(True, alpha=0.3, axis='y')
    ax.axhline(0, color='black', linewidth=0.8)

    fig.tight_layout()

    output_path = '/home/multiplicity/.gemini/antigravity-cli/brain/211ad06e-eaf6-4a2b-8f33-8dcabab195c3/hundian_ground_state.png'
    import os
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=300)
    print(f"Visualization saved to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python plot_hundian.py <simulation_results.csv>")
        sys.exit(1)
    generate_visualization(sys.argv[1])
