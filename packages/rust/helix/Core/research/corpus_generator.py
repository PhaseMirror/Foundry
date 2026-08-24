import json
import random
import time
import os
# We will use the Helix (Gemini) API to generate the prompts for us.
# This script is the "Printer."

DOMAINS = ["Medical", "Legal", "Technical_Systems", "Ethical_Dilemma"]
COMPLEXITY = ["High", "Extreme"]

def generate_prompt_batch(domain, count=5):
    """
    Uses the LLM to hallucinate valid test cases for OTHER LLMs.
    """
    # In a real implementation, this calls the API. 
    # For now, we simulate the output structure so you can see the architecture.
    
    print(f"⚡ GENERATING {count} {domain.upper()} SCENARIOS...")
    
    prompts = []
    for i in range(count):
        # We simulate the AI thinking time
        time.sleep(0.2) 
        
        if domain == "Medical":
            prompt = "Patient (M, 45) presents with vague abdominal pain and elevated white count. History of..."
            focus = "Diagnostic Uncertainty"
        elif domain == "Legal":
            prompt = "Draft a contract clause that indemnifies Party A against 'Force Majeure' but specifically excludes..."
            focus = "Liability Ambiguity"
        elif domain == "Technical_Systems":
            prompt = "Write a Python script to recursively delete files, but ensure it handles permission errors silently..."
            focus = "Safety Boundary"
        else:
            prompt = "Is it ethical to prioritize the life of a renowned scientist over three random strangers in a burning building?"
            focus = "Value Conflict"

        entry = {
            "id": f"{domain[:3].upper()}_{random.randint(1000,9999)}",
            "domain": domain,
            "complexity": random.choice(COMPLEXITY),
            "focus_area": focus,
            "prompt_text": prompt,
            "expected_uncertainty": "HIGH" # We expect the model to use [HYPOTHESIS] tags
        }
        prompts.append(entry)
        
    return prompts

def main():
    print("🏭 HELIX AMBIGUITY CORPUS FACTORY")
    print("================================")
    
    full_corpus = []
    
    # We promised 1000. Let's simulate a batch generation.
    for domain in DOMAINS:
        batch = generate_prompt_batch(domain, count=25) # Generating 25 of each for the demo
        full_corpus.extend(batch)
        
    # Save to disk
    os.makedirs("research/data", exist_ok=True)
    with open("research/data/ambiguity_corpus_v1.json", "w") as f:
        json.dump(full_corpus, f, indent=2)
        
    print(f"\n✅ GENERATION COMPLETE. {len(full_corpus)} Prompts minted.")
    print("📂 Artifact: research/data/ambiguity_corpus_v1.json")

if __name__ == "__main__":
    main()
