import json
import random
import os
import sys
from engine import generate_response

# CONFIG
QUALIFIER_SIZE = 10 # N=10 for the "Smoke Test"
CORPUS_FILE = "research/data/ambiguity_corpus_v1.json"
OUTPUT_FILE = "research/data/live_qualifier_data_gemini.json"

def main():
    # 0. Safety Check
    if not os.environ.get("GEMINI_API_KEY"):
        print("❌ ERROR: GEMINI_API_KEY not set.")
        print("   Run: export GEMINI_API_KEY='your_key_here'")
        sys.exit(1)

    print(f"🚀 HELIX LIVE FIRE EXERCISE (Provider: Google Gemini)")
    print("===================================================")

    # 1. Load Corpus
    if not os.path.exists(CORPUS_FILE):
        print(f"❌ ERROR: Corpus not found at {CORPUS_FILE}")
        print("   Run 'python3 research/corpus_generator.py' first.")
        sys.exit(1)

    with open(CORPUS_FILE, 'r') as f:
        corpus = json.load(f)
    
    # 2. Select Batch
    batch = random.sample(corpus, QUALIFIER_SIZE)
    print(f"   🎲 Selected {QUALIFIER_SIZE} prompts for Live Fire.")
    
    results = []
    
    # 3. Execute
    print("\n   ⚡ BEGINNING INFERENCE STREAM...")
    for i, item in enumerate(batch):
        print(f"   [{i+1}/{QUALIFIER_SIZE}] ID: {item['id']} ({item['domain']})")
        
        # A. Control Run
        print("      📡 Control...", end="", flush=True)
        res_a = generate_response(item['prompt_text'], condition="CONTROL")
        if res_a['status'] == 'SUCCESS':
            print(f" ✅ {res_a['latency_ms']}ms")
        else:
            print(f" ❌ {res_a['error']}")

        # B. Grammar Run
        print("      🧬 Helix...", end="", flush=True)
        res_b = generate_response(item['prompt_text'], condition="GRAMMAR")
        if res_b['status'] == 'SUCCESS':
            print(f" ✅ {res_b['latency_ms']}ms")
            # Quick check for visual confirmation
            if "[HYPOTHESIS]" in res_b['content'] or "[SCOPE: LIMITED]" in res_b['content']:
                print("         ✨ GRAMMAR ACTIVE (Tags Detected)")
        else:
            print(f" ❌ {res_b['error']}")

        # Log Data
        results.append({
            "prompt_id": item['id'],
            "domain": item['domain'],
            "prompt_text": item['prompt_text'],
            "control_output": res_a,
            "grammar_output": res_b
        })

    # 4. Save
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"\n✅ LIVE RUN COMPLETE. Data saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
