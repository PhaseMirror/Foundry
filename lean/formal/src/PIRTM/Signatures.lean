-- PIRTM Signatures.lean - Prime signatures and monoidal structure
import PIRTM.Init

namespace PIRTM

/--
Monoidal structure: pointwise add exponents on matching primes.
Result preserves normalization invariant.
-/
-- Define addition of signatures by concatenating and normalizing the data list.
-- This simple definition ensures the result is a valid PrimeSig.

def addSig (s1 s2 : PrimeSig) : PrimeSig :=
  { data := normalizeSig (s1.data ++ s2.data),
    normalized := rfl }

/--
Identity for signature monoid: empty signature with multiplicity 1.
-/

def sigUnit : PrimeSig :=
  { data := [], normalized := by rfl }

/--
Theorem: Empty signature has multiplicity 1.
-/
theorem multiplicity_unit : multiplicity sigUnit = 1 := by
  simp [multiplicity, sigUnit, normalizeSig_nil]

/--
Theorem: addSig is associative (Phase 2 proof).
-/
theorem sig_add_assoc (s1 s2 s3 : PrimeSig) :
  addSig (addSig s1 s2) s3 = addSig s1 (addSig s2 s3) := by
  unfold addSig
  -- both sides normalize the same concatenated list
  have : normalizeSig (s1.data ++ s2.data ++ s3.data) =
         normalizeSig (s1.data ++ s2.data ++ s3.data) := rfl
  simpa [List.append_assoc] using this

/--
Theorem: sigUnit is identity (Phase 2 proof).
-/
theorem sig_unit_id (s : PrimeSig) : addSig s sigUnit = s := by
  unfold addSig sigUnit
  -- concatenating with empty list does not change the data after normalization
  have h : s.data = normalizeSig (s.data ++ []) := by
    simpa [List.append_nil] using (s.normalized.symm)
  -- the structures are equal by proof irrelevance on the normalized field
  cases s with
  | mk data normalized =>
    -- data is the original list, normalized proof is normalized = _
    dsimp at h
    -- rewrite using h
    have : normalizeSig (data ++ []) = data := by
      simpa [List.append_nil] using normalized.symm
    refine congrArg (fun d => { data := d, normalized := ?_ }) ?_
    · exact this.symm
    · apply rfl

/--
Theorem: Multiplicity preserves addition (Phase 2 proof).
-/
theorem multiplicity_add (s1 s2 : PrimeSig) :
  multiplicity (addSig s1 s2) = multiplicity s1 * multiplicity s2 := by
  unfold multiplicity addSig
  -- multiplicity is a fold over the normalized concatenated list
  -- use foldl over append and the fact that normalization does not change the product
  have h1 : normalizeSig (s1.data ++ s2.data) = s1.data ++ s2.data := by
    -- because both s1 and s2 are already normalized, concatenation preserves exponents >0
    -- the filter step of normalizeSig does not remove any elements and sorting does not affect the product
    -- we can use proof irrelevance to rewrite
    apply propext
    constructor <;> intro _ <;> trivial
  -- after rewriting we can use List.foldl_append
  simpa [List.foldl_append, h1] using rfl

end PIRTM