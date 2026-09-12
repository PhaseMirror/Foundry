#!/usr/bin/env bash

# process_all_projects.sh – run from the repository root
# It iterates each subdirectory under ./lean/projects (alphabetical order),
# ensures a proper lakefile, creates a Main.lean that imports the first
# source file, builds the project, and moves it to ./lean/Core/ on success.

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
PROJECTS_DIR="$ROOT_DIR/lean/projects"
CORE_DIR="$ROOT_DIR/lean/Core"

mkdir -p "$CORE_DIR"

log_success() { echo "[SUCCESS] $1"; }
log_failure() { echo "[FAILURE] $1"; }

for proj_path in $(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d | sort); do
  proj_name=$(basename "$proj_path")
  echo "Processing $proj_name..."

  # Ensure lakefile exists and has correct config
  lakefile="$proj_path/lakefile.lean"
  if [[ ! -f "$lakefile" ]]; then
    cat > "$lakefile" <<'EOF'
import Lake
open Lake DSL

package $proj_name {
  version := v!"0.1.0"
}

lean_lib Formalization {
  srcDir := "src"
}

@[default_target]
lean_exe Main
EOF
    echo "Created default lakefile for $proj_name"
  else
    # Append srcDir if missing
    grep -q "srcDir := \"src\"" "$lakefile" || echo "lean_lib Formalization { srcDir := \"src\" }" >> "$lakefile"
    # Append default target if missing
    grep -q "@\[default_target\]" "$lakefile" || echo -e "\n@[default_target]\nlean_exe Main" >> "$lakefile"
  fi

  # Create Main.lean that imports the first source file in src/
  src_dir="$proj_path/src"
  first_file=$(find "$src_dir" -maxdepth 1 -type f -name "*.lean" | head -n 1)
  if [[ -z "$first_file" ]]; then
    log_failure "$proj_name: no .lean files in src/"
    continue
  fi
  module_name=$(basename "$first_file" .lean)
  main_file="$proj_path/Main.lean"
  cat > "$main_file" <<EOF
import Formalization.$module_name

-- Placeholder theorem to ensure compilation

theorem placeholder : True := trivial
EOF

  # Build the project
  pushd "$proj_path" > /dev/null
  if lake build; then
    popd > /dev/null
    # Move to Core on success
    dest="$CORE_DIR/$proj_name"
    mkdir -p "$dest"
    mv "$proj_path"* "$dest/"
    log_success "$proj_name built and moved to Core"
  else
    popd > /dev/null
    log_failure "$proj_name build failed"
  fi
done

echo "All projects processed."
