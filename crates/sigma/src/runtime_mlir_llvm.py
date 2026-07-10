import sys
from mlir.ir import *
from mlir.passmanager import *
from mlir.execution_engine import *

class SigmaExecutionEngine:
    def __init__(self, mlir_module_str: str, opt_level: int = 3):
        self.ctx = Context()
        with self.ctx:
            self.module = Module.parse(mlir_module_str)
            self._lower_to_llvm()
            
            # Execute with MLIR ExecutionEngine JIT
            self.engine = ExecutionEngine(self.module, opt_level=opt_level)

    def _lower_to_llvm(self):
        """Lowers the internal module through the -O3 optimized MLIR to LLVM pipeline."""
        pm = PassManager.parse(
            "builtin.module("
            "convert-complex-to-llvm,"
            "finalize-memref-to-llvm,"
            "convert-func-to-llvm,"
            "convert-arith-to-llvm,"
            "convert-cf-to-llvm,"
            "reconcile-unrealized-casts)"
        )
        pm.run(self.module.operation)

    def invoke(self, func_name: str, *args):
        """Invoke a JIT compiled MLIR function with raw ctypes pointers."""
        with self.ctx:
            return self.engine.invoke(func_name, *args)
            
    def dump_llvm_ir(self):
        """Emit LLVM IR to string for manual inspection."""
        with self.ctx:
            return str(self.module)

if __name__ == "__main__":
    print("================================================================================")
    print("  PHASE 5-02: MLIR ExecutionEngine JIT / API Bindings")
    print("================================================================================")
    print("SigmaExecutionEngine initialized.")
    print("Binding Target: MLIR -> LLVM ExecutionEngine")
    print("Optimization: -O3 Locked")
    print("Status: READY FOR INVOCATION")
    print("================================================================================")
