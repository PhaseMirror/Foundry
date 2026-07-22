import re

content = open('Core/F1/Analysis/PsiLine.lean').read()

# Add maxRecDepth at the top
if 'set_option maxRecDepth' not in content:
    content = "set_option maxRecDepth 200000\n" + content

# Restore simp only to undo dsimp that didn't work
content = content.replace("dsimp [corrT, corrTel, Qsub, Qle, add, neg]", "simp only [corrT, corrTel, Qsub, Qle, add, neg]")
content = content.replace("dsimp [corrTP, corrTel2, Qsub, Qle, add, neg]", "simp only [corrTP, corrTel2, Qsub, Qle, add, neg]")
content = content.replace("dsimp [corrTP, corrTel3, Qsub, Qle, add, neg]", "simp only [corrTP, corrTel3, Qsub, Qle, add, neg]")
content = content.replace("dsimp [corrTP, corrTel4, Qsub, Qle, add, neg]", "simp only [corrTP, corrTel4, Qsub, Qle, add, neg]")
content = content.replace("dsimp [corrTP, corrTel5, Qsub, Qle, add, neg]", "simp only [corrTP, corrTel5, Qsub, Qle, add, neg]")
content = content.replace("dsimp [corrTP, corrTel1, Qsub, Qle, add, neg]", "simp only [corrTP, corrTel1, Qsub, Qle, add, neg]")

# Fix corrTP1_le_teldiff1
# We'll just define a private integer lemma.
old_proof = '''private theorem corrTP1_le_teldiff1 {n : Nat} (hn : 2 ≤ n) :
    Qle (corrTP 1 1 n) (Qsub (corrTel1 n) (corrTel1 (n + 1))) := by
  simp only [corrTP, corrTel1, Qsub, Qle, add, neg]
  push_cast
  have key :
      (16 * ((4 * ((n : Int) + 1) + 1) * (4 * ((n : Int) + 1) + 1) + 16)
          + -16 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16))
        * ((4 * (n : Int) + 1) * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) * 1 + 16))
      = 64 * (((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16)
          * ((4 * ((n : Int) + 1) + 1) * (4 * ((n : Int) + 1) + 1) + 16))
        + 64 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16)
          * (16 * (n : Int) * (n : Int) - 8 * (n : Int) - 35) := by ring_uor
  have key2 : (16 : Int) = 16 := rfl
  -- wait, I need to extract the lemma for this because `push_cast` evaluates `16` to `1+1...16` in the target, and `rw` fails.
  have hnn : (0 : Int) ≤ 64 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16)
      * (16 * (n : Int) * (n : Int) - 8 * (n : Int) - 35) :=
    Int.mul_nonneg (Int.mul_nonneg (by decide)
      (by have := sq_nonneg_int (4 * (n : Int) + 1); omega)) (quad_nonneg_ge2 (by exact_mod_cast hn))
  exact le_add_right_of_nonneg hnn'''

new_proof = '''private theorem corrTP1_int_eq (n : Int) :
  (16 * ((4 * (n + 1) + 1) * (4 * (n + 1) + 1) + 16) +
        -16 * ((4 * n + 1) * (4 * n + 1) + 16)) *
      ((4 * n + 1) * ((4 * n + 1) * (4 * n + 1) * 1 + 16)) =
    64 *
        (((4 * n + 1) * (4 * n + 1) + 16) *
          ((4 * (n + 1) + 1) * (4 * (n + 1) + 1) + 16)) +
      64 * ((4 * n + 1) * (4 * n + 1) + 16) * (16 * n * n - 8 * n - 35) := by ring_uor

private theorem corrTP1_le_teldiff1 {n : Nat} (hn : 2 ≤ n) :
    Qle (corrTP 1 1 n) (Qsub (corrTel1 n) (corrTel1 (n + 1))) := by
  simp only [corrTP, corrTel1, Qsub, Qle, add, neg]
  push_cast
  have hnn : (0 : Int) ≤ 64 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16)
      * (16 * (n : Int) * (n : Int) - 8 * (n : Int) - 35) :=
    Int.mul_nonneg (Int.mul_nonneg (by decide)
      (by have := sq_nonneg_int (4 * (n : Int) + 1); omega)) (quad_nonneg_ge2 (by exact_mod_cast hn))
  have e1 := corrTP1_int_eq (n : Int)
  omega'''

content = content.replace(old_proof, new_proof)

open('Core/F1/Analysis/PsiLine.lean', 'w').write(content)
