import hashlib
import re
import sys
import json
from typing import Dict, Any, List, Optional

# blake3 is optional, fallback to sha256 if unavailable
try:
    import blake3
    HAS_BLAKE3 = True
except ImportError:
    HAS_BLAKE3 = False

# Canonical prime set
CERTIFIED_PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]

def is_prime(n: int) -> bool:
    if n < 2: return False
    for i in range(2, int(n**0.5) + 1):
        if n % i == 0: return False
    return True

def get_modulus_type(mod: int) -> str:
    return "tensor" if is_prime(mod) else "ctensor"

def poseidon_hash(data: str) -> str:
    """Mock Poseidon hash using SHA256 with a prefix."""
    return hashlib.sha256(f"poseidon:{data}".encode()).hexdigest()

def sha256_hash(data: str) -> str:
    return hashlib.sha256(data.encode()).hexdigest()

class PirtmTranspiler:
    """
    PIRTM Transpiler (Ring 0.5 ISA)
    
    EBNF Mapping Strategy:
    - stability_margin (ε) -> epsilon
    - contraction_coefficient (q) -> q_target
    - nonlinear_gain (‖T‖) -> op_norm_t
    - prime_index (p) -> mod
    """
    def __init__(self):
        self.epsilon = 0.05
        self.q_target = 0.95
        self.op_norm_t = 1.0
        self.mod = 7
        self.identity_secret = "default_secret"

    def parse_nl(self, text: str):
        # EBNF-aligned Regex Mappings
        mappings = {
            "epsilon": [
                r"stability margin of ([\d\.]+)", 
                r"epsilon of ([\d\.]+)", 
                r"ε = ([\d\.]+)",
                r"([\d\.]+)% margin",
                r"margin of ([\d\.]+)%"
            ],
            "q_target": [
                r"spectral radius of ([\d\.]+)", 
                r"contraction coefficient of ([\d\.]+)", 
                r"q = ([\d\.]+)",
                r"spectral radius < ([\d\.]+)"
            ],
            "op_norm_t": [
                r"nonlinear gain of ([\d\.]+)", 
                r"operator norm of ([\d\.]+)", 
                r"‖T‖ = ([\d\.]+)"
            ],
            "mod": [
                r"modulus ([\d]+)", 
                r"prime index ([\d]+)", 
                r"p = ([\d]+)"
            ]
        }

        for attr, patterns in mappings.items():
            for pattern in patterns:
                match = re.search(pattern, text, re.IGNORECASE)
                if match:
                    raw_val = match.group(1)
                    if "%" in pattern or (match.end() < len(text) and text[match.end()] == "%"):
                        val = float(raw_val) / 100.0
                    else:
                        val = float(raw_val) if "." in raw_val or attr != "mod" else int(raw_val)
                    setattr(self, attr, val)
                    break

        # Deterministic prime mapping if not specified
        if "modulus" not in text.lower() and "prime index" not in text.lower() and "p =" not in text.lower():
            if HAS_BLAKE3:
                h = blake3.blake3(text.encode()).digest()
            else:
                h = hashlib.sha256(text.encode()).digest()
            idx = int.from_bytes(h[:4], "big") % len(CERTIFIED_PRIMES)
            self.mod = CERTIFIED_PRIMES[idx]

    def emit_mlir(self, name: str) -> str:
        mod_type = get_modulus_type(self.mod)
        identity_commitment = poseidon_hash(self.identity_secret)
        
        mlir = f"""// PIRTM-SPEC-1.0 MLIR Dialect Output
module @{name} {{
  pirtm.module {{ 
    prime_index = {self.mod} : i64, 
    epsilon = {self.epsilon:.4f} : f64, 
    op_norm_T = {self.op_norm_t:.4f} : f64, 
    identity_commitment = "{identity_commitment}" 
  }} {{
    %X = "pirtm.undef"() : () -> !pirtm.{mod_type}<mod={self.mod}>
    %Xi = "pirtm.undef"() : () -> !pirtm.{mod_type}<mod={self.mod}>
    %Lambda = "pirtm.undef"() : () -> !pirtm.{mod_type}<mod={self.mod}>
    %G = "pirtm.undef"() : () -> !pirtm.{mod_type}<mod={self.mod}>
    
    %0 = "pirtm.step"(%X, %Xi, %Lambda, %G) {{ 
      mod = {self.mod} : i64, 
      epsilon = {self.epsilon:.4f} : f64,
      q_target = {self.q_target:.4f} : f64
    }} : (!pirtm.{mod_type}<mod={self.mod}>, !pirtm.{mod_type}<mod={self.mod}>, !pirtm.{mod_type}<mod={self.mod}>, !pirtm.{mod_type}<mod={self.mod}>) -> !pirtm.{mod_type}<mod={self.mod}>
  }}
}}"""
        return mlir

    def emit_witness(self) -> Dict[str, str]:
        # Canonical payload for witness commitment
        payload = {
            "mod": self.mod,
            "epsilon": self.epsilon,
            "q_target": self.q_target,
            "op_norm_t": self.op_norm_t,
            "scheme": "dual"
        }
        data = json.dumps(payload, sort_keys=True)
        return {
            "sha256": sha256_hash(data),
            "poseidon": poseidon_hash(data)
        }

def main():
    if len(sys.argv) < 2:
        print("Usage: python nl_to_pirtm.py '<natural language requirement>'")
        sys.exit(1)

    nl_input = " ".join(sys.argv[1:])
    transpiler = PirtmTranspiler()
    transpiler.parse_nl(nl_input)

    print("--- PIRTM Transpiler Output (Ring 0.5 ISA) ---")
    print(f"Input: {nl_input}")
    print("\n[MLIR Dialect]")
    print(transpiler.emit_mlir("generated_module"))
    
    print("\n[Dual-Hash Witness]")
    witness = transpiler.emit_witness()
    print(f"SHA256:  {witness['sha256']}")
    print(f"Poseidon: {witness['poseidon']}")

if __name__ == "__main__":
    main()
