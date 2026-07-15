namespace SigmaticsCore

/-- Evaluate an expression string and return a dummy hash. Exposed to Rust via FFI. -/
@[extern "eval_expr"]
def eval_expr (code : String) : UInt64 := 0

/-- Compute a hash of a LedgerBlock. -/
@[extern "ledger_block_hash"]
def ledger_block_hash (blk : LedgerBlock) : UInt64 := blk.hash

end SigmaticsCore
