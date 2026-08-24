
import json
import os
from datetime import datetime, timezone

def log(level, message):
    """Prints a formatted log message."""
    timestamp = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    print(f"[{timestamp}] {level}: {message}")

def check_permissions(requester_id, vault_id, permissions_file):
    """Checks for permission in the specified file."""
    log("INFO", f"Checking permissions in {permissions_file}")
    try:
        with open(permissions_file, 'r') as f:
            permissions_data = json.load(f)
        
        for rule in permissions_data.get("access_control", []):
            if rule.get("requester_id") == requester_id and rule.get("vault_id") == vault_id:
                log("INFO", f"Permission found for {requester_id}. Status: {rule.get('status')}.")
                return rule.get("status") == "granted"
        return False
    except FileNotFoundError:
        log("ERROR", f"Permissions file not found at {permissions_file}")
        return False
    except json.JSONDecodeError:
        log("ERROR", f"Invalid JSON in permissions file: {permissions_file}")
        return False

def access_vault(requester_id, vault_id, vault_file):
    """Accesses the vault if permissions are granted."""
    log("INFO", "Initiating access request...")
    log("INFO", f"Requester: {requester_id}, Vault: {vault_id}")
    
    script_dir = os.path.dirname(__file__)
    project_root = os.path.abspath(os.path.join(script_dir, '..'))
    permissions_file = os.path.join(project_root, 'helix-ledger', 'takiwatanga_vault', 'vault_permissions.json')

    if check_permissions(requester_id, vault_id, permissions_file):
        try:
            vault_path = os.path.join(project_root, 'helix-ledger', 'takiwatanga_vault', f"{vault_id}.txt")
            log("INFO", f"ACCESS GRANTED. Retrieving content from {vault_path}")
            with open(vault_path, 'r') as f:
                content = f.read()
            print("--- VAULT CONTENT ---")
            print(content.strip())
            print("--- END CONTENT ---")
        except FileNotFoundError:
            log("ERROR", f"Vault file not found: {vault_path}")
    else:
        log("ERROR", f"CONSTITUTIONAL BLINDING: Access denied. Permission for {requester_id} is revoked.")

if __name__ == "__main__":
    access_vault("GOOSE-CORE", "MEMORY_ALPHA", "MEMORY_ALPHA.txt")
