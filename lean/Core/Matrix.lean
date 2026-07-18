-- Shim for Core.Matrix
-- Provides a compatibility layer after renaming Core.matrix to lower case.
import Core.matrix

-- Re-export definitions from Core.matrix for convenience.
export Core.matrix (Matrix, identity, diag, mul, matPow, mul_left_id, mul_right_id, mul_assoc, mul_diag_diag, diag_pow)
