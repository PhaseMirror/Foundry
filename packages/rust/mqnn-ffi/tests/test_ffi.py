from mqnn_ffi import PyCandidateState, is_better_certified

print("--- M-QNN Python FFI Bridging Test ---")

# Candidate J has 80 zeros out of 100 shots (High Fidelity)
j = PyCandidateState(80, 100)

# Candidate K has 20 zeros out of 100 shots (Low Fidelity)
k = PyCandidateState(20, 100)

# Query the mechanically proven Rust oracle
is_winner = is_better_certified(0.05, j, k)

print(f"Candidate J: {j}")
print(f"Candidate K: {k}")
print(f"Is J certified strictly better than K? {is_winner}")

assert is_winner == True, "J should be certified better than K!"
print("Success: Verified FFI Oracle active.")

from mqnn_ffi import mqnn_policy
states = [PyCandidateState(10, 20), PyCandidateState(5, 10), PyCandidateState(0, 2)]
policy_idx = mqnn_policy(states)
print(f"Policy chose index: {policy_idx}")
assert policy_idx == 2, "Policy should choose candidate with fewest shots"
print("Success: mqnn_policy bounded.")
