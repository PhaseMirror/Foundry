import json

def is_prime(n: int) -> bool:
    if n <= 1: return False
    if n <= 3: return True
    if n % 2 == 0 or n % 3 == 0: return False
    i = 5
    while i * i <= n:
        if n % i == 0 or n % (i + 2) == 0: return False
        i += 6
    return True

def test_lever_emission():
    # Simulate a violation context
    violation_type = "SUCCESSOR_PREDICATE_VIOLATION"
    context = {"path": "ast.rs", "line": 42, "snippet": "..."}
    
    lever = {
        "tension": violation_type,
        "owner": "CompilerTeam",
        "metric": "invariant_pass_rate >= 0.999",
        "horizon": "7 days",
        "evidence": context
    }
    
    assert "evidence" in lever and "path" in lever["evidence"]
    print(json.dumps(lever, indent=2))
    
    # L0 guard: no bypass
    assert "disable_gate" not in str(lever).lower()
    assert "bypass" not in str(lever).lower()

if __name__ == "__main__":
    test_lever_emission()
