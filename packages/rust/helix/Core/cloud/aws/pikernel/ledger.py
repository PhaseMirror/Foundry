"""
SHA-256 PETC Ledger.

Append-only JSONL ledger with canonical JSON → SHA-256 commitments.
Each record is serialized deterministically and hashed before appending.
"""

import json
import hashlib
import time
from typing import Any, Dict, List, Optional


class Ledger:
    """
    Append-only ledger with SHA-256 commitments.
    
    Each entry is:
    1. Serialized to canonical JSON (sorted keys, compact)
    2. Hashed with SHA-256
    3. Appended to in-memory list
    4. Optionally written to JSONL file
    """
    
    def __init__(self, filepath: Optional[str] = None):
        """
        Initialize ledger.
        
        Args:
            filepath: Optional path to JSONL file for persistence
        """
        self.filepath = filepath
        self.entries: List[Dict[str, Any]] = []
        self._file_handle = None
        
        if filepath:
            # Open file in append mode
            self._file_handle = open(filepath, 'a')
    
    def append(self, record: Dict[str, Any]) -> str:
        """
        Append a record to the ledger.
        
        Args:
            record: Dictionary to append (will be augmented with timestamp and digest)
        
        Returns:
            Hex digest of the canonical JSON representation
        """
        # Create a copy to avoid mutating input
        entry = dict(record)
        
        # Add timestamp
        entry["timestamp_ms"] = int(time.time() * 1000)
        
        # Canonical JSON: sorted keys, no whitespace
        canonical_json = json.dumps(entry, sort_keys=True, separators=(',', ':'))
        
        # Compute SHA-256 digest
        digest = hashlib.sha256(canonical_json.encode('utf-8')).hexdigest()
        entry["digest"] = digest
        
        # Append to in-memory list
        self.entries.append(entry)
        
        # Write to file if configured
        if self._file_handle:
            self._file_handle.write(canonical_json + '\n')
            self._file_handle.flush()
        
        return digest
    
    def get_entries(self) -> List[Dict[str, Any]]:
        """Get all ledger entries."""
        return list(self.entries)
    
    def verify_digest(self, entry: Dict[str, Any]) -> bool:
        """
        Verify that an entry's digest matches its content.
        
        Args:
            entry: Entry with 'digest' field
        
        Returns:
            True if digest is valid
        """
        if "digest" not in entry:
            return False
        
        # Remove digest and recompute
        entry_copy = {k: v for k, v in entry.items() if k != "digest"}
        canonical_json = json.dumps(entry_copy, sort_keys=True, separators=(',', ':'))
        computed_digest = hashlib.sha256(canonical_json.encode('utf-8')).hexdigest()
        
        return computed_digest == entry["digest"]
    
    def close(self):
        """Close file handle if open."""
        if self._file_handle:
            self._file_handle.close()
            self._file_handle = None
    
    def __del__(self):
        """Cleanup on deletion."""
        self.close()
    
    def __len__(self) -> int:
        """Number of entries in ledger."""
        return len(self.entries)
