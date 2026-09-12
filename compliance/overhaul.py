import os
import re

for root, _, files in os.walk('.'):
    for f in files:
        if f.endswith('.md') or f.endswith('.yaml') or f.endswith('.json'):
            path = os.path.join(root, f)
            with open(path, 'r') as file:
                content = file.read()
            
            # Replace fake hashes in manifest.json
            if f == 'manifest.json':
                content = re.sub(r'"<sha256-hex>"', '"UNATTESTED"', content)
                content = re.sub(r'"CERT-[^"]+"', '"UNATTESTED"', content)

            # Scrub fake CRMF seals in YAML
            if f == 'policy.yaml':
                content = re.sub(r'auto_crmf_attestation: true', 'auto_crmf_attestation: UNATTESTED', content)

            # Process Markdown
            if f == 'NIST OSCAL.md':
                content = re.sub(r'(?i)poseidon2 digest[s]?', 'UNATTESTED', content)
                content = re.sub(r'(?i)crmf validity seal[s]?', 'UNATTESTED', content)
                content = re.sub(r'(?i)on-chain attestation hash[es]?', 'UNATTESTED', content)
                content = re.sub(r'<sha256-hex>', 'UNATTESTED', content)
                
                # Add a big warning at the top
                if 'UNATTESTED' not in content[:500]:
                    warning = "> **WARNING: UNATTESTED.** Per ADR-0003, this document is an optional, read-only export format. Any evidence without a verifiable, hashed R1CS compiler manifest or Lean proof hash backing the claim is strictly UNATTESTED. Cryptographic seals are prohibited in this document.\n\n"
                    content = warning + content
            
            with open(path, 'w') as file:
                file.write(content)
print("Overhaul complete.")
