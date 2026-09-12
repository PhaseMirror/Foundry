#!/usr/bin/env python3
import pandas as pd
import matplotlib.pyplot as plt
import sys

if len(sys.argv) < 2:
    print("Usage: plot_hundian.py <simulation_results.csv>")
    sys.exit(1)

csv_path = sys.argv[1]
df = pd.read_csv(csv_path)

fig, axes = plt.subplots(2, 2, figsize=(12, 8))
fig.suptitle("UAC Simulator: Convergence to the Arithmetic Bindu", fontsize=14)

# 1. Arta Defect (pre vs. post)
ax = axes[0, 0]
ax.plot(df["run"], df["pre_arta_defect"], 'ro-', label="Pre‑Fit")
ax.plot(df["run"], df["post_arta_defect"], 'go-', label="Post‑Fit")
ax.set_yscale("log")
ax.set_xlabel("Run")
ax.set_ylabel("Arta Defect (log scale)")
ax.legend()
ax.set_title("Arta Defect Convergence")

# 2. Rta Distance to Bindu
ax = axes[0, 1]
ax.plot(df["run"], df["pre_rta_dist"], 'ro-', label="Pre‑Fit")
ax.plot(df["run"], df["post_rta_dist"], 'go-', label="Post‑Fit")
ax.set_xlabel("Run")
ax.set_ylabel("Rta Distance")
ax.legend()
ax.set_title("Distance to Bindu")

# 3. Langlands Loss
ax = axes[1, 0]
ax.plot(df["run"], df["langlands_loss"], 'bo-')
ax.set_xlabel("Run")
ax.set_ylabel("Langlands Loss")
ax.set_title("Langlands Coherence (L‑value penalty)")

# 4. Total Loss and ZK Gate status
ax = axes[1, 1]
ax.plot(df["run"], df["total_loss"], 'mo-', label="Total Loss")
# Highlight ZK status
for i, row in df.iterrows():
    color = 'green' if row["zk_status"] == "ACCEPTED" else 'red'
    ax.scatter(row["run"], row["total_loss"], c=color, s=80, zorder=5)
ax.set_xlabel("Run")
ax.set_ylabel("Total Loss")
ax.set_title("Total Loss (green = ZK ACCEPTED)")

plt.tight_layout()
plt.savefig("simulation_plot.png", dpi=150)
plt.show()
