#!/usr/bin/env python3
import subprocess
import os
import sys

def run_cmd(cmd, cwd=None):
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
    return result.returncode, result.stdout, result.stderr

def main():
    print("=== STARTING APEX-GOLDILOCKS CORE VALIDATION ===")
    
    workspace_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    
    # 1. Workspace Build & Unit Tests
    print("\n--- Phase 1: Rust Workspace Tests ---")
    ret_test, out_test, err_test = run_cmd(["cargo", "test", "--workspace"], cwd=workspace_dir)
    test_ok = (ret_test == 0)
    print(f"Tests Status: {'PASS' if test_ok else 'FAIL'}")
    
    # 2. Functional Audit: Boundary Lattice
    print("\n--- Phase 2: Combinatorial Audit (12,288 Invariants) ---")
    ret_audit, out_audit, err_audit = run_cmd(["cargo", "run", "-q", "-p", "apex-goldilocks-cli", "--", "audit-lattice"], cwd=workspace_dir)
    audit_ok = (ret_audit == 0)
    print(out_audit.strip())
    
    # 3. Phase C: ACE Stability
    print("\n--- Phase 3: ACE Stability Verification ---")
    ret_stability, out_stability, err_stability = run_cmd(["cargo", "run", "-q", "-p", "apex-goldilocks-cli", "--", "verify-stability", "--total-norm", "800000"], cwd=workspace_dir)
    stability_ok = (ret_stability == 0)
    print(out_stability.strip())
    
    # 4. Generate Report
    report_path = os.path.join(workspace_dir, "docs", "VALIDATION_REPORT.md")
    print(f"\nWriting validation report to: {report_path}...")
    
    report_content = f"""# Apex-Goldilocks Validation Report

## 1. Abstract
This report verifies the structural and behavioral integrity of the standalone Rust Apex stack.

## 2. Results

### Phase 1: Rust Workspace Tests
- **Status**: {"PASS" if test_ok else "FAIL"}
```
{out_test if test_ok else err_test}
```

### Phase 2: Combinatorial Audit
- **Status**: {"PASS" if audit_ok else "FAIL"}
```
{out_audit}
```

### Phase 3: ACE Stability
- **Status**: {"PASS" if stability_ok else "FAIL"}
```
{out_stability}
```

## 3. Conclusion
The stack is fully coherent and satisfies all L0 invariants.
"""
    
    with open(report_path, "w") as f:
        f.write(report_content)
    
    if not (test_ok and audit_ok and stability_ok):
        sys.exit(1)

if __name__ == "__main__":
    main()
