import json
import numpy as np
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
import os

# Load history
history_path = "output/lane_d_history.json"
if not os.path.exists(history_path):
    print("No history found.")
    sys.exit(0)

with open(history_path, "r") as f:
    data = json.load(f)

# Extract features: cd_overall, cd_tau, cd_recon, cd_fail
features = []
for entry in data:
    features.append([
        entry["cd_overall"],
        entry["cd_tau"],
        entry["cd_recon"],
        entry["cd_fail"]
    ])

X = np.array(features)

# Cluster Analysis
n_clusters = 4
kmeans = KMeans(n_clusters=n_clusters, random_state=42).fit(X)
labels = kmeans.labels_

# PCA for visualization
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X)

print("\n=== Governance Ledger Cluster Analysis ===")
for i in range(n_clusters):
    cluster_indices = np.where(labels == i)[0]
    cluster_data = X[cluster_indices]
    print(f"\nCluster {i}:")
    print(f"  Count: {len(cluster_indices)}")
    print(f"  Centroid: {np.mean(cluster_data, axis=0)}")

# Check against existing fragility classes
print("\n=== Fragility Class Distribution in Clusters ===")
for i in range(n_clusters):
    indices = np.where(labels == i)[0]
    classes = [data[idx]["meta_fragility_class"] for idx in indices]
    from collections import Counter
    print(f"Cluster {i} Classes: {Counter(classes)}")

# Visualization
plt.scatter(X_pca[:, 0], X_pca[:, 1], c=labels, cmap='viridis')
plt.title("Meta-Governance Space (PCA)")
plt.savefig("output/governance_clusters.png")
print("\nPCA plot saved to output/governance_clusters.png")
