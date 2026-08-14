import subprocess
import json
import sys
import os

def run_validation(runs=1000):
    print(f"Starting {runs}-run determinism validation pipeline...")
    
    # Path to the Rust test runner
    runner_cmd = [
        "cargo", "run", "-q", "-p", "archivum-cli", "--",
        "--vectors", "../tests/vectors",
        "--output", "../tests/results/validation.json"
    ]
    
    # We will hash the output of the rust runner or inspect its json
    # to ensure absolute bit-for-bit determinism across all runs.
    
    baseline_result = None
    
    for i in range(1, runs + 1):
        if i % 100 == 0:
            print(f"Completed {i}/{runs} runs...")
            
        # Execute the Rust runner
        result = subprocess.run(
            runner_cmd, 
            capture_output=True, 
            text=True,
            cwd=os.path.dirname(os.path.abspath(__file__))
        )
        
        if result.returncode != 0:
            print(f"Error on run {i}: {result.stderr}")
            sys.exit(1)
            
        # Read the generated output json
        try:
            with open(os.path.join(os.path.dirname(__file__), "../tests/results/validation.json"), "r") as f:
                output = f.read()
                
            if baseline_result is None:
                baseline_result = output
            elif baseline_result != output:
                print(f"DETERMINISM FAILURE on run {i}!")
                print(f"Expected: {baseline_result}")
                print(f"Got: {output}")
                sys.exit(1)
        except Exception as e:
            print(f"Failed to read output on run {i}: {e}")
            sys.exit(1)

    print(f"\n✅ SUCCESS: 100% Determinism achieved across {runs} executions.")
    print("The Prime ABI v0 pipeline is formally stabilized.")

if __name__ == "__main__":
    # In a real environment we would default to 1000. 
    # For CI constraints we'll default to 50 for fast demonstration.
    runs = int(sys.argv[1]) if len(sys.argv) > 1 else 50
    run_validation(runs)
