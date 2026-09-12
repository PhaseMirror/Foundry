#!/usr/bin/env bash
set -euo pipefail

# Ensure helm is installed
if ! command -v helm &>/dev/null; then
  echo "Helm not found, installing via snap..."
  sudo snap install helm --classic || true
fi

# Copy Helm chart from artifact directory to repo
ARTIFACT_DIR="/home/multiplicity/.gemini/antigravity-cli/brain/50322566-949c-4222-b71b-2d7498fc0dea/deployment/helm"
DEST_DIR="$(pwd)/deployment/helm"
mkdir -p "$DEST_DIR"
cp -r "$ARTIFACT_DIR"/* "$DEST_DIR/"

# Deploy to Kubernetes (assumes KUBECONFIG is set)
helm upgrade --install phase-mirror-mcp "$DEST_DIR" \
  --namespace default \
  --create-namespace \
  --set image.repository=ghcr.io/phasemirror/pscmd \
  --set image.tag=$(git rev-parse --short HEAD)

echo "Deployment completed."
