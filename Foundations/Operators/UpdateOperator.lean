/-!
# Update Operator
The update operator with prime-indexed components.
Formalizes Theorems A2 and A3.
Implementation, memory safety, and contraction bounds are verified via Kani in Rust.
Mathlib dependencies have been removed in favor of strict FFI bindings.
-/

/--
FFI Binding to the Rust/Kani verified kernel.
This provides the memory-safe, verified operational execution path.
-/
@[extern "update_op_f64"]
opaque updateOpFfi (alpha_pi m_ops f_op x : @& FloatArray) (n num_primes : USize) : FloatArray
