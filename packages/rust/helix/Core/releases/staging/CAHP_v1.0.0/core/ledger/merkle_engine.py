import hashlib
from typing import List

class MerkleEngine:
    def __init__(self):
        self.leaves = []
        self.root = None

    @staticmethod
    def _hash(data: str) -> str:
        """Helper to hash data."""
        return hashlib.sha256(data.encode()).hexdigest()

    def add_leaf(self, data: str):
        """Adds a data item (leaf) to the tree."""
        # We hash the data immediately upon entry
        self.leaves.append(self._hash(data))
        self.root = None # Invalidate current root

    def add_leaf_hash(self, leaf_hash: str):
        """Adds an already hashed leaf."""
        self.leaves.append(leaf_hash)
        self.root = None

    def compute_root(self) -> str:
        """Computes the Merkle Root of the current leaves."""
        if not self.leaves:
            return ""
        
        current_level = self.leaves
        
        while len(current_level) > 1:
            next_level = []
            # Process pairs
            for i in range(0, len(current_level), 2):
                left = current_level[i]
                # Duplicate last element if odd number of leaves
                right = current_level[i+1] if i+1 < len(current_level) else left
                
                combined = left + right
                next_level.append(self._hash(combined))
            current_level = next_level
            
        self.root = current_level[0]
        return self.root

    def get_proof(self, index: int) -> List[dict]:
        """
        Generates a Merkle Proof for a leaf at a given index.
        Returns a list of dicts: {'direction': 'left'|'right', 'hash': '...'}
        """
        if not self.leaves or index >= len(self.leaves):
            return []
            
        proof = []
        current_level = self.leaves
        target_index = index
        
        while len(current_level) > 1:
            next_level = []
            for i in range(0, len(current_level), 2):
                left = current_level[i]
                right = current_level[i+1] if i+1 < len(current_level) else left
                
                # If our target is left, we need the right sibling
                if i == target_index:
                    proof.append({'direction': 'right', 'hash': right})
                # If our target is right, we need the left sibling
                elif i+1 == target_index:
                    proof.append({'direction': 'left', 'hash': left})
                    
                combined = left + right
                next_level.append(self._hash(combined))
            
            current_level = next_level
            target_index //= 2
            
        return proof

    @staticmethod
    def verify_proof(leaf_data: str, proof: List[dict], root: str) -> bool:
        """Verifies a Merkle Proof."""
        current_hash = MerkleEngine._hash(leaf_data)
        
        for step in proof:
            if step['direction'] == 'right':
                combined = current_hash + step['hash']
            else:
                combined = step['hash'] + current_hash
            current_hash = MerkleEngine._hash(combined)
            
        return current_hash == root

# Example Usage
if __name__ == "__main__":
    mt = MerkleEngine()
    logs = ["Log 1: System Start", "Log 2: Drift Check", "Log 3: System Green"]
    
    print("--- Building Tree ---")
    for l in logs:
        mt.add_leaf(l)
        print(f"Added: {l}")
        
    root = mt.compute_root()
    print(f"Merkle Root: {root}")
    
    print("""
--- Verifying 'Log 2' ---
""")
    proof = mt.get_proof(1) # Index of Log 2
    is_valid = MerkleEngine.verify_proof("Log 2: Drift Check", proof, root)
    print(f"Verification Result: {is_valid}")
