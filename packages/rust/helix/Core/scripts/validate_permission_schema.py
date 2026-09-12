#!/usr/bin/env python3

import json
import sys
import argparse
from datetime import datetime

# --- v1.2.0 Schema Definition ---
# This defines the expected structure and rules for a permission entry.
REQUIRED_FIELDS = [
    "document_hash", "owner_id", "delegate_id", "access_level",
    "valid_until", "jurisdiction", "enforcement_mode", "reason",
    "last_modified_utc", "modified_by_id"
]
VALID_ACCESS_LEVELS = {"ALLOW", "DENY"}
VALID_ENFORCEMENT_MODES = {"GOVERNANCE", "HARD_ENFORCED"}

def validate_iso8601_utc(timestamp_str, field_name):
    """
    Validates that a string is a compliant ISO-8601 UTC timestamp
    ending in 'Z'. Returns (True, None) on success, (False, error_msg) on failure.
    """
    if timestamp_str is None:
        return True, None # Null is valid for optional timestamps like valid_until

    if not isinstance(timestamp_str, str) or not timestamp_str.endswith('Z'):
        return False, f"'{field_name}' must be a string ending in 'Z'."

    try:
        # Replace 'Z' with '+00:00' for Python's fromisoformat
        datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        return True, None
    except ValueError:
        return False, f"'{field_name}' content '{timestamp_str}' is not a valid ISO-8601 timestamp."

def main():
    """Main validation function."""
    parser = argparse.ArgumentParser(description="Validate the vault_permissions.json file against the v1.2.0 schema.")
    parser.add_argument("filepath", help="Path to the vault_permissions.json file.")
    args = parser.parse_args()

    try:
        with open(args.filepath, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"❌ [ERROR] File not found: {args.filepath}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"❌ [ERROR] Invalid JSON in file: {args.filepath}", file=sys.stderr)
        sys.exit(1)

    # --- Schema Version Check ---
    if data.get("schema_version") != "1.2.0":
        print(f"❌ [ERROR] Invalid schema_version. Expected '1.2.0', found '{data.get('schema_version')}'.", file=sys.stderr)
        sys.exit(1)

    # --- Permissions Array Check ---
    permissions = data.get("permissions")
    if not isinstance(permissions, list):
        print("❌ [ERROR] Top-level 'permissions' key must be a list.", file=sys.stderr)
        sys.exit(1)

    for i, entry in enumerate(permissions):
        # Check for required fields
        for field in REQUIRED_FIELDS:
            if field not in entry:
                print(f"❌ [ERROR] Entry {i}: Missing required field '{field}'.", file=sys.stderr)
                sys.exit(1)

        # Validate enum values
        if entry["access_level"] not in VALID_ACCESS_LEVELS:
            print(f"❌ [ERROR] Entry {i}: Invalid 'access_level'. Found '{entry['access_level']}'.", file=sys.stderr)
            sys.exit(1)

        if entry["enforcement_mode"] not in VALID_ENFORCEMENT_MODES:
            print(f"❌ [ERROR] Entry {i}: Invalid 'enforcement_mode'. Found '{entry['enforcement_mode']}'.", file=sys.stderr)
            sys.exit(1)

        # Validate timestamps
        valid, msg = validate_iso8601_utc(entry["valid_until"], "valid_until")
        if not valid:
            print(f"❌ [ERROR] Entry {i}: {msg}", file=sys.stderr)
            sys.exit(1)
            
        valid, msg = validate_iso8601_utc(entry["last_modified_utc"], "last_modified_utc")
        if not valid:
            print(f"❌ [ERROR] Entry {i}: {msg}", file=sys.stderr)
            sys.exit(1)

    print(f"✅ [SUCCESS] Schema validation passed for {args.filepath}")
    sys.exit(0)

if __name__ == "__main__":
    main()
