#!/usr/bin/env bash

# migrate_packages.sh
# ------------------------------------------------------------
# Automates the SDK migration and policy template generation for
# each package under Multiplicity/Substrates/projects.
# ------------------------------------------------------------

set -euo pipefail

# Root directory containing all packages (two levels up from this script)
ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.."

# Absolute path to the shared policy template (YAML) stored as an artifact
TEMPLATE="/home/multiplicity/.gemini/antigravity-cli/brain/a93fbc7f-5a17-455d-b1de-479ce3370c97/templates/retention_policy.yaml"

# Function to update a single package
migrate_package() {
  local pkg_path="$1"
  echo "\n=== Migrating $(basename "$pkg_path") ==="

  # 1. Ensure Cargo.toml includes the latest sedona SDK
  if [[ -f "$pkg_path/Cargo.toml" ]]; then
    if grep -q "sedona-sdk" "$pkg_path/Cargo.toml"; then
      echo "Updating sedona-sdk version..."
      sed -i -E 's/(sedona-sdk\s*=\s*")[^"]+(".*)/\1= "2.3"\2/' "$pkg_path/Cargo.toml" || true
    else
      echo "Adding sedona-sdk dependency..."
      echo "sedona-sdk = \"2.3\"" >> "$pkg_path/Cargo.toml"
    fi
  else
    echo "⚠️ No Cargo.toml found in $pkg_path – skipping SDK update."
  fi

  # 2. Copy the retention policy template into the package
  mkdir -p "$pkg_path/templates"
  cp "$TEMPLATE" "$pkg_path/templates/retention_policy.yaml"
  echo "Copied retention policy template."

  # 3. Run the guided test harness (placeholder)
  if [[ -x "$pkg_path/run_tests.sh" ]]; then
    echo "Running guided test harness..."
    "$pkg_path/run_tests.sh"
  else
    echo "No test harness script found; you may need to add one manually."
  fi

  echo "Migration completed for $(basename "$pkg_path")."
}

# Iterate over all first‑level subdirectories (packages)
for dir in "$ROOT_DIR"/*; do
  if [[ -d "$dir" ]]; then
    migrate_package "$dir"
  fi
done

echo "\nAll packages have been processed."
