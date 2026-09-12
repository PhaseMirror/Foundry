import csv
import numpy as np

def analyze_results(csv_path):
    rq_s_vals = []
    rq_n_vals = []
    c_vals = []
    delta_vals = []
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rq_s_vals.append(float(row['rq_shape']))
            rq_n_vals.append(float(row['rq_num']))
            c_vals.append(float(row['c_resonance']))
            delta_vals.append(float(row['delta']))
            
    print(f"Total Roots Analyzed: {len(rq_s_vals)}")
    print("-" * 40)
    
    metrics = {
        "Shape Resonance (RQ_s)": rq_s_vals,
        "Numeric Resonance (RQ_n)": rq_n_vals,
        "Covenantal Integrity (C)": c_vals,
        "Channel Asymmetry (Delta)": delta_vals
    }
    
    for name, vals in metrics.items():
        arr = np.array(vals)
        print(f"{name}:")
        print(f"  Mean:   {np.mean(arr):.4f}")
        print(f"  Median: {np.median(arr):.4f}")
        print(f"  StdDev: {np.std(arr):.4f}")
        print(f"  10th %: {np.percentile(arr, 10):.4f}")
        print(f"  25th %: {np.percentile(arr, 25):.4f}")
        print(f"  75th %: {np.percentile(arr, 75):.4f}")
        print(f"  90th %: {np.percentile(arr, 90):.4f}")
        print("-" * 40)

    try:
        import matplotlib.pyplot as plt
        fig, axs = plt.subplots(2, 2, figsize=(12, 10))
        
        axs[0, 0].hist(rq_s_vals, bins=50, color='blue', alpha=0.7)
        axs[0, 0].set_title('Shape Resonance (RQ_s)')
        
        axs[0, 1].hist(rq_n_vals, bins=50, color='green', alpha=0.7)
        axs[0, 1].set_title('Numeric Resonance (RQ_n)')
        
        axs[1, 0].hist(c_vals, bins=50, color='purple', alpha=0.7)
        axs[1, 0].set_title('Covenantal Integrity (C)')
        
        axs[1, 1].hist(delta_vals, bins=50, color='orange', alpha=0.7)
        axs[1, 1].set_title('Channel Asymmetry (Delta)')
        
        plt.tight_layout()
        plt.savefig('oshl_histograms.png')
        print("Histograms saved to oshl_histograms.png")
    except ImportError:
        print("Matplotlib not available for histograms.")

if __name__ == "__main__":
    analyze_results('oshl_corpus_results.csv')
