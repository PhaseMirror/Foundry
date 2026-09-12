import json
import yaml
import re

def audit():
    print("--- [AUDIT] Initiating Semantic Drift Audit of Governance Documentation ---")
    
    # 1. Parse ledger.jsonl for participant commits
    ledger_hashes = {}
    ledger_path = "cli/phasemirror-cli/var/archivum/ledger.jsonl"
    with open(ledger_path, "r") as f:
        for line in f:
            if line.strip():
                entry = json.loads(line)
                data = entry.get("data", {})
                archetype_id = data.get("archetypeId", "")
                if archetype_id.startswith("LEG-PARTICIPANT-"):
                    # Extract participant number from LEG-PARTICIPANT-00X-ONBOARD
                    p_id = f"PARTICIPANT-{archetype_id.split('-')[2]}"
                    ledger_hashes[p_id] = entry["hash"]
                    
    # 2. Parse mcp_manifest.yaml
    manifest_hashes = {}
    manifest_path = "phase-mirror-main/mcp/manifest/mcp_manifest.yaml"
    with open(manifest_path, "r") as f:
        manifest_data = yaml.safe_load(f)
        for p in manifest_data.get("participants", []):
            p_id = p["id"]
            manifest_hashes[p_id] = p.get("compliance", {}).get("ledger_commit_hash", "")
            
    # 3. Parse agency_integration_report.md for hashes
    report_hashes = {}
    report_path = "/home/multiplicity/.gemini/antigravity-cli/brain/23d50928-c672-45e5-af61-cf8c7f94e589/agency_integration_report.md"
    with open(report_path, "r") as f:
        content = f.read()
        # Look for participant commit hashes, e.g., 661d0f81...
        # Let's match lines like | **1** | `PARTICIPANT-001` | ... | `661d0f81...` |
        pattern = r"PARTICIPANT-(\d+).*?`([a-f0-9]+)\.\.\..*?`"
        matches = re.findall(pattern, content)
        for num, short_hash in matches:
            p_id = f"PARTICIPANT-{num}"
            report_hashes[p_id] = short_hash
            
    # 4. Compare all three
    all_match = True
    print("\nVerifying Hash Alignment:")
    for p_id in sorted(ledger_hashes.keys()):
        l_hash = ledger_hashes[p_id]
        m_hash = manifest_hashes.get(p_id, "")
        r_prefix = report_hashes.get(p_id, "")
        
        matches_manifest = (l_hash == m_hash)
        matches_report = l_hash.startswith(r_prefix)
        
        print(f"[*] {p_id}:")
        print(f"    - Ledger:   {l_hash}")
        print(f"    - Manifest: {m_hash} -> {'MATCH' if matches_manifest else 'MISMATCH'}")
        print(f"    - Report:   {r_prefix}... -> {'MATCH' if matches_report else 'MISMATCH'}")
        
        if not (matches_manifest and matches_report):
            all_match = False
            
    if all_match:
        print("\n[PASS] Zero documentation drift detected. Artifacts match the ledger chain exactly.")
    else:
        print("\n[FAIL] Drift detected in documentation. Verify manual inputs.")

if __name__ == "__main__":
    audit()
